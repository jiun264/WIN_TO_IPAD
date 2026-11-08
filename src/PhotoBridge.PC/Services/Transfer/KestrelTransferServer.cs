using System.Collections.Concurrent;
using System.IO;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using PhotoBridge.PC.Models;

namespace PhotoBridge.PC.Services.Transfer;

public sealed class KestrelTransferServer : ITransferServer
{
    private WebApplication? _app;
    private readonly ConcurrentDictionary<string, PhotoItem> _photoMap = new();
    private readonly SemaphoreSlim _gate = new(1, 1);

    public bool IsRunning => _app != null;
    public string? PairingCode { get; private set; }
    public ushort Port { get; private set; }
    public IReadOnlyList<string> LocalAddresses { get; private set; } = [];

    public event Action<string>? FileTransferred;
    public event Action<string>? LogMessage;

    public async Task<TransferServerResult> StartAsync(IReadOnlyCollection<PhotoItem> photos, ushort port = 8765)
    {
        await _gate.WaitAsync();
        try
        {
            if (_app != null)
            {
                await StopInternalAsync();
            }

            if (photos.Count == 0)
            {
                return new TransferServerResult(false, "請先選取至少一張照片。");
            }

            Port = port;
            PairingCode = Random.Shared.Next(100000, 999999).ToString();
            LocalAddresses = GetLocalIPv4Addresses();

            _photoMap.Clear();
            var manifestList = new List<PhotoManifestDto>();
            int index = 0;
            foreach (var photo in photos)
            {
                var id = (++index).ToString();
                _photoMap[id] = photo;
                manifestList.Add(new PhotoManifestDto(
                    id,
                    photo.FileName,
                    photo.SizeBytes,
                    photo.Format
                ));
            }

            var builder = WebApplication.CreateBuilder();
            builder.Logging.ClearProviders(); // 抑制 console 雜訊

            // 設定 Kestrel 監聽所有網路介面
            builder.WebHost.ConfigureKestrel(options =>
            {
                options.ListenAnyIP(Port);
                options.Limits.MaxRequestBodySize = null;
                options.Limits.MinResponseDataRate = null; // 避免傳輸巨大 RAW 檔在 Wi-Fi 抖動時觸發逾時中斷
            });

            // 啟用 CORS 允許跨端點存取
            builder.Services.AddCors(options =>
            {
                options.AddDefaultPolicy(policy =>
                {
                    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
                });
            });

            var app = builder.Build();
            app.UseCors();

            // 1. 測試連線端點
            app.MapGet("/api/status", () => Results.Ok(new
            {
                app = "PhotoBridge",
                version = "1.0",
                status = "online",
                photoCount = _photoMap.Count
            }));

            // 2. 清單端點
            app.MapGet("/api/manifest", (string? code) =>
            {
                if (string.IsNullOrEmpty(code) || code != PairingCode)
                {
                    return Results.Unauthorized();
                }

                return Results.Ok(new
                {
                    pairingCode = PairingCode,
                    count = manifestList.Count,
                    totalBytes = manifestList.Sum(p => p.SizeBytes),
                    items = manifestList
                });
            });

            // 3. 極速檔案串流端點 (Zero-Copy SendFile & Range 續傳支援)
            app.MapGet("/api/photos/{id}", (string id, string? code, HttpContext ctx) =>
            {
                if (string.IsNullOrEmpty(code) || code != PairingCode)
                {
                    return Results.Unauthorized();
                }

                if (!_photoMap.TryGetValue(id, out var photo) || !File.Exists(photo.Path))
                {
                    return Results.NotFound();
                }

                // 註冊傳輸完成回呼
                ctx.Response.OnCompleted(() =>
                {
                    FileTransferred?.Invoke(photo.FileName);
                    return Task.CompletedTask;
                });

                // enableRangeProcessing 支援斷點續傳，底層自動啟用 OS 零拷貝 (TransmitFile)
                return Results.File(
                    photo.Path,
                    contentType: "application/octet-stream",
                    fileDownloadName: photo.FileName,
                    enableRangeProcessing: true
                );
            });

            await app.StartAsync();
            _app = app;

            LogMessage?.Invoke($"傳輸服務已啟動在 Port {Port}，配對碼：{PairingCode}");
            return new TransferServerResult(
                true,
                $"傳輸伺服器已啟動！配對碼：{PairingCode}",
                PairingCode,
                Port,
                LocalAddresses
            );
        }
        catch (Exception ex)
        {
            return new TransferServerResult(false, $"啟動傳輸服務失敗：{ex.Message}");
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task StopAsync()
    {
        await _gate.WaitAsync();
        try
        {
            await StopInternalAsync();
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task StopInternalAsync()
    {
        if (_app != null)
        {
            try
            {
                await _app.StopAsync();
                await _app.DisposeAsync();
            }
            catch
            {
                // 忽略關閉時的例外
            }
            finally
            {
                _app = null;
                PairingCode = null;
                _photoMap.Clear();
                LogMessage?.Invoke("傳輸服務已停止。");
            }
        }
    }

    public async ValueTask DisposeAsync()
    {
        await StopAsync();
        _gate.Dispose();
    }

    private static List<string> GetLocalIPv4Addresses()
    {
        var addresses = new List<string>();
        try
        {
            foreach (var ni in NetworkInterface.GetAllNetworkInterfaces())
            {
                if (ni.OperationalStatus != OperationalStatus.Up ||
                    ni.NetworkInterfaceType == NetworkInterfaceType.Loopback)
                {
                    continue;
                }

                var ipProps = ni.GetIPProperties();
                foreach (var addr in ipProps.UnicastAddresses)
                {
                    if (addr.Address.AddressFamily == AddressFamily.InterNetwork)
                    {
                        var ipStr = addr.Address.ToString();
                        // 優先挑選標準私有網段 (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
                        if (ipStr.StartsWith("192.168.") || ipStr.StartsWith("10.") || ipStr.StartsWith("172."))
                        {
                            addresses.Insert(0, ipStr);
                        }
                        else
                        {
                            addresses.Add(ipStr);
                        }
                    }
                }
            }
        }
        catch
        {
            // 容錯降級
        }

        if (addresses.Count == 0)
        {
            addresses.Add("127.0.0.1");
        }

        return addresses.Distinct().ToList();
    }
}

public sealed record PhotoManifestDto(
    string Id,
    string FileName,
    long SizeBytes,
    string Format
);
