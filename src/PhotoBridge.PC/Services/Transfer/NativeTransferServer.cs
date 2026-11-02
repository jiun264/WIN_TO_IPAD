using System.Runtime.InteropServices;
using System.Text.Json;
using PhotoBridge.PC.Models;

namespace PhotoBridge.PC.Services.Transfer;

public sealed class NativeTransferServer : ITransferServer
{
    private const int Success = 0;
    private const int NotImplemented = 2;
    private const string NativeLibraryName = "PhotoBridge.Transport.Native";

    public TransferServerResult Start(IReadOnlyCollection<PhotoItem> photos, ushort port)
    {
        if (photos.Count == 0)
        {
            return new TransferServerResult(false, "請先選取至少一張照片。");
        }

        if (port == 0)
        {
            return new TransferServerResult(false, "傳輸服務連接埠無效。");
        }

        var manifest = JsonSerializer.Serialize(photos.Select(photo => photo.Path));
        var result = NativeMethods.StartServer(port, manifest);
        if (result == Success)
        {
            return new TransferServerResult(true, $"C++ 傳輸服務已啟動，連接埠 {port}。");
        }

        var error = Marshal.PtrToStringUTF8(NativeMethods.GetLastError()) ?? "No native error details.";
        return new TransferServerResult(false, result == NotImplemented
            ? "C++ 傳輸核心目前只有 API 骨架，尚未實作區網服務。"
            : $"C++ 傳輸服務啟動失敗（錯誤 {result}）：{error}");
    }

    public void Stop()
    {
        var result = NativeMethods.StopServer();
        if (result != Success)
        {
            throw new InvalidOperationException(
                $"C++ 傳輸服務停止失敗（錯誤 {result}）：{GetNativeError()}");
        }
    }

    private static string GetNativeError() =>
        Marshal.PtrToStringUTF8(NativeMethods.GetLastError()) ?? "No native error details.";

    private static class NativeMethods
    {
        [DllImport(NativeLibraryName, EntryPoint = "pb_start_server", CallingConvention = CallingConvention.Cdecl)]
        internal static extern int StartServer(ushort port, [MarshalAs(UnmanagedType.LPUTF8Str)] string manifestJson);

        [DllImport(NativeLibraryName, EntryPoint = "pb_stop_server", CallingConvention = CallingConvention.Cdecl)]
        internal static extern int StopServer();

        [DllImport(NativeLibraryName, EntryPoint = "pb_get_last_error", CallingConvention = CallingConvention.Cdecl)]
        internal static extern IntPtr GetLastError();
    }
}
