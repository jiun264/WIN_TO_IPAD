using PhotoBridge.PC.Models;

namespace PhotoBridge.PC.Services.Transfer;

/// <summary>
/// 原生 C++ 傳輸核心預留實作（備用）。目前系統預設使用高效能 Kestrel 傳輸核心。
/// </summary>
public sealed class NativeTransferServer : ITransferServer
{
    public bool IsRunning => false;
    public string? PairingCode => null;
    public ushort Port => 0;
    public IReadOnlyList<string> LocalAddresses => [];

    public event Action<string>? FileTransferred;
    public event Action<string>? LogMessage;

    public Task<TransferServerResult> StartAsync(IReadOnlyCollection<PhotoItem> photos, ushort port = 8765)
    {
        return Task.FromResult(new TransferServerResult(
            false,
            "原生 C++ 傳輸核心尚未實作，請使用 KestrelTransferServer。"
        ));
    }

    public Task StopAsync()
    {
        return Task.CompletedTask;
    }

    public ValueTask DisposeAsync()
    {
        return ValueTask.CompletedTask;
    }
}
