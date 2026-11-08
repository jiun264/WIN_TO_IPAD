using PhotoBridge.PC.Models;

namespace PhotoBridge.PC.Services.Transfer;

public interface ITransferServer : IAsyncDisposable
{
    bool IsRunning { get; }
    string? PairingCode { get; }
    ushort Port { get; }
    IReadOnlyList<string> LocalAddresses { get; }

    event Action<string>? FileTransferred;
    event Action<string>? LogMessage;

    Task<TransferServerResult> StartAsync(IReadOnlyCollection<PhotoItem> photos, ushort port = 8765);
    Task StopAsync();
}

public sealed record TransferServerResult(
    bool IsSuccess,
    string Message,
    string? PairingCode = null,
    ushort Port = 0,
    IReadOnlyList<string>? LocalAddresses = null
);
