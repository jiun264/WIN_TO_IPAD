using PhotoBridge.PC.Models;

namespace PhotoBridge.PC.Services.Transfer;

public interface ITransferServer
{
    TransferServerResult Start(IReadOnlyCollection<PhotoItem> photos, ushort port);

    void Stop();
}

public sealed record TransferServerResult(bool IsSuccess, string Message);
