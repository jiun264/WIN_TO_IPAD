# PhotoBridge

PC 選片後，透過同一個區域網路將 Nikon NEF 等原始照片傳到 iPad，供 Lightroom 匯入。傳輸不經雲端、不需接線。

## 專案結構

- `src/PhotoBridge.PC`：Windows WPF 桌面端；負責挑片 UI、檔案清單與傳輸服務協調。
- `src/PhotoBridge.Transport.Native`：C++20 原生 DLL 傳輸核心；由 C# 透過穩定的 C ABI 呼叫。
- `ios/PhotoBridge.swiftpm`：Swift Playgrounds 可開啟的 iPad SwiftUI App 起始專案。

## 目前狀態

PC 端目前已建立 WPF UI → C# `ITransferServer` → C++ C ABI DLL 的分層。C++ DLL 與 C# 互通介面已有明確契約，但原生傳輸核心目前回報「尚未實作」；**區域網路配對、NEF 預覽、傳輸與續傳尚未實作**。PC 傳送按鈕會明確顯示目前狀態，不會假裝傳輸成功。

接下來預計依序完成：

1. PC 照片格、NEF 內嵌 JPEG 預覽及快速挑片。
2. 以 C++ 實作 PC 區域網路配對服務：顯示連線資訊與一次性配對碼，只提供已選照片。
3. iPad 端接收清單與背景下載佇列，保存到「檔案」可存取的位置。
4. 逐檔記錄、重試及完整性驗證；Wi-Fi 中斷後恢復未完成項目。
5. 實機測試大量傳輸、iPad 鎖定、PC 睡眠及 Wi-Fi 變動等情境。

大量傳輸的目標是支援 iPad 鎖定後由系統背景下載接手，並在 App 重開後恢復佇列；iOS 不保證 App 被使用者強制結束或 PC 關機時仍能傳輸。正式承諾前必須在真實 iPad 與 Windows PC 上驗證區域網路背景下載行為。

## 開發

### Windows PC

需要 Windows、.NET 8 SDK、CMake 3.20+ 與可用的 C++20 編譯器：

```powershell
cmake -S . -B build
cmake --build build --config Release
dotnet build .\PhotoBridge.slnx
dotnet run --project .\src\PhotoBridge.PC
```

將 CMake 產生的 `PhotoBridge.Transport.Native.dll` 放在 WPF 應用程式輸出目錄旁，讓 P/Invoke 載入。

### iPad

在 Swift Playgrounds 中開啟 `ios/PhotoBridge.swiftpm`。使用本機網路前，App 需要取得 iOS 的「本機網路」權限；在連線服務完成時加入使用說明並於實機確認授權流程。若 Playgrounds 無法完成必要的權限設定或建置，使用 Mac 上的 Xcode 開啟／匯入此 SwiftUI 專案。
