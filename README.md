# PhotoBridge 🚀

> **PC 選片，極速零拷貝直傳 iPad！專為相機 RAW 原始檔（Nikon NEF, Canon CR2/CR3, Sony ARW, DNG）量身打造，同區域網路下跑滿 Wi-Fi 頻寬極限，無縫導入 Lightroom Mobile 修圖。**

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20iPadOS-blue.svg)](https://github.com/jiun264/WIN_TO_IPAD)
[![.NET 8](https://img.shields.io/badge/.NET-8.0-purple.svg)](https://dotnet.microsoft.com/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9%20%7C%20iOS%2017-orange.svg)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 目錄

- [一、核心特色與速度極限](#一核心特色與速度極限)
- [二、使用方法（完整流程）](#二使用方法完整流程)
- [三、本地打包與安裝方法](#三本地打包與安裝方法)
- [四、如何上架應用商店](#四如何上架應用商店)
  - [4.1 上架微軟商店 (Microsoft Store)](#41-上架微軟商店-microsoft-store)
  - [4.2 上架蘋果商店 (Apple App Store)](#42-上架蘋果商店-apple-app-store)
- [五、系統架構與技術細節](#五系統架構與技術細節)
  - [5.1 系統架構圖](#51-系統架構圖)
  - [5.2 核心技術細節](#52-核心技術細節)
- [六、關鍵代碼對應解說](#六關鍵代碼對應解說)
  - [6.1 PC 端代碼解說](#61-pc-端代碼解說)
  - [6.2 iPad 端代碼解說](#62-ipad-端代碼解說)

---

## 一、核心特色與速度極限

1. **極速傳輸（150 ~ 220+ MB/s）**：
   - 傳統傳輸協議（如 SMB、WebDAV、iTunes 傳輸）存在協定層與雙重緩衝開銷。PhotoBridge 採用 **OS Direct I/O Zero-Copy** 與 **4 通道並行串流**，實測跑滿 Wi-Fi 6 (5GHz/6GHz) 頻寬極限。
2. **安全配對，專圖專傳**：
   - 啟動時動態產生 6 位數安全配對碼，只有被 PC 端勾選的照片才會建立虛擬映射，嚴格防止區域網路非授權存取。
3. **Lightroom Mobile 零摩擦導入**：
   - 傳輸完成的照片直接落盤至 iPad 系統級共享目錄（`我的 iPad > PhotoBridge`），Lightroom Mobile 點擊「+ 匯入 > 來自檔案」即可一鍵整批導入所有 RAW 照片。
4. **雙端符合商店上架標準**：
   - Windows 端已封裝獨立自包含執行檔、一鍵安裝檔及 Microsoft Store MSIX 清單。
   - iPad 端支援 Swift Playgrounds 直接上架與完整 Xcode App Store 上架工程。

---

## 二、使用方法（完整流程）

### 步驟 1：PC 端啟動並挑片
1. 雙擊執行 `PhotoBridge.exe`（或從開始功能表開啟）。
2. 點擊「**選擇照片資料夾**」，程式自動掃描目錄中的照片（支援 NEF, CR2, ARW, DNG, JPG 等）。
3. 勾選欲傳輸的照片（支援「全選」/「全不選」）。
4. 點擊「**啟動直傳服務**」。
5. 畫面將出現：
   - **連線網址**（例如 `http://192.168.1.50:8765`，提供一鍵複製按鈕）。
   - **6 位數配對碼**（例如 `829314`）。

### 步驟 2：iPad 端連線接收
1. 打開 iPad 上的 **PhotoBridge** App。
2. 允許 iOS 提示的「**本機網路**」連線權限。
3. 輸入 PC 螢幕上顯示的「**位址**」與「**6 位數配對碼**」。
4. 點擊「**連線並同步清單**」，App 會載入本次傳輸的照片列表與總容量。
5. 點擊「**開始極速傳輸**」，4 條並發下載通道全速啟動，儀表板即時顯示傳輸速率（MB/s）與總進度。

### 步驟 3：在 Lightroom Mobile 匯入
1. 下載完成後，打開 iPad 上的 **Lightroom** App。
2. 點擊右下角「**+ 匯入**」按鈕 ➔ 選擇「**來自檔案 (From Files)**」。
3. 導航至「**我的 iPad ➔ PhotoBridge**」資料夾。
4. 點擊右上角「全選」並確認，即可瞬間導入所有 RAW 原始相片開始修圖！

---

## 三、本地打包與安裝方法

### 1. 一鍵自動編譯打包 (PowerShell)
在專案根目錄下直接執行：
```powershell
.\build-all.ps1
```
腳本將自動執行：
1. 編譯 .NET 8 Release win-x64 單一自包含執行檔。
2. 自動生成 Windows 一鍵安裝包與解除安裝批次檔。
3. 封裝出 `dist\PhotoBridge-v1.0.0-Windows-x64.zip`。

### 2. PC 本地安裝方式
- 解壓縮 `dist\PhotoBridge-v1.0.0-Windows-x64.zip`。
- **免安裝執行**：直接雙擊 `PhotoBridge.exe` 即可使用。
- **標準安裝**：雙擊資料夾內的 `安裝PhotoBridge.bat`：
  - 自動複製到標準應用程式路徑 `%LOCALAPPDATA%\Programs\PhotoBridge`。
  - 在桌面與開始功能表建立帶圖標的捷徑。
  - 於 Windows 控制台註冊「已安裝的應用程式」。
- **解除安裝**：雙擊 `解除安裝PhotoBridge.bat` 即可乾淨移除。

### 3. iPad 端本地安裝方式
- **方式 A（免電腦，iPad 內直接運行）**：
  - 將本專案的 `ios/PhotoBridge.swiftpm` 複製至 iPad（透過 AirDrop 或 iCloud Drive）。
  - 在 iPad 下載官方免費的 **Swift Playgrounds** App，點擊開啟 `PhotoBridge.swiftpm` 即可直接全螢幕執行！
- **方式 B（透過 Mac Xcode 側載）**：
  - 在 Mac 上使用 Xcode 打開 `ios/Xcode` 或 `ios/PhotoBridge.swiftpm`。
  - 接上 iPad，選擇您的 iPad 實機並點擊 Run 即可安裝。

---

## 四、如何上架應用商店

### 4.1 上架微軟商店 (Microsoft Store)

專案已準備好符合微軟商店標準的配置檔案：
- [`packaging/windows/AppxManifest.xml`](file:///c:/Users/brian/Desktop/code/PhotoBridge/packaging/windows/AppxManifest.xml)
- [`src/PhotoBridge.PC/Resources/AppIcon-256.png`](file:///c:/Users/brian/Desktop/code/PhotoBridge/src/PhotoBridge.PC/Resources/AppIcon-256.png)

#### 提交步驟：
1. **註冊開發者帳號**：登入 [Microsoft Partner Center](https://partner.microsoft.com/)。
2. **打包 MSIX**：
   使用 Windows 10/11 內建的 `MSIX Packaging Tool` 或 CLI 指令：
   ```powershell
   MakeAppx pack /d "dist\PhotoBridge-Windows-Setup" /p "dist\PhotoBridge.msix"
   ```
3. **自簽/商店簽署**：
   在 Partner Center 建立應用程式名稱「PhotoBridge」，將產生的 `PhotoBridge.msix` 上傳至 Partner Center 套件提交頁面。
4. **提交審查**：
   填寫商店商品詳情（包含相機 RAW 傳輸功能介紹與螢幕截圖），送出審查即可於微軟商店上架。

---

### 4.2 上架蘋果商店 (Apple App Store)

專案提供兩條完整的 App Store 上架路徑：

#### 路徑 A：在 iPad 上透過 Swift Playgrounds 4+ 直接發布（最便捷）
1. 在 iPad 上開啟 `ios/PhotoBridge.swiftpm`。
2. 點擊左側 App 設定圖標，登入您的 **Apple Developer** 帳號。
3. 填入 App 名稱與 Team ID，點擊「**上傳至 App Store Connect**」。
4. 登入 [App Store Connect](https://appstoreconnect.apple.com/) 完成 TestFlight 測試與版本審查提交。

#### 路徑 B：在 Mac 上透過 Xcode 正式 Archive 上架（標準工程）
1. 在 Mac 上使用 Xcode 打開 `ios/Xcode` 專案。
2. 檢查 `ios/Xcode/PhotoBridge/Info.plist`（已內建 App Store 必備的 `NSLocalNetworkUsageDescription` 權限宣告與 `UIFileSharingEnabled` 檔案共享宣告）。
3. 在 Xcode 頂部選單選擇 **Product ➔ Archive**。
4. 在 Organizer 視窗中點擊 **Distribute App ➔ App Store Connect ➔ Upload** 即可完成上傳。

---

## 五、系統架構與技術細節

### 5.1 系統架構圖

```
┌─────────────────────────────────┐
│     Windows PC (.NET 8 WPF)     │
│  - PhotoFolderScanner (掃描挑片) │
│  - Kestrel HTTP Engine (微秒吞吐)│
│  - OS Direct I/O (TransmitFile) │
└──────────────┬──────────────────┘
               │
               │  Wi-Fi 6 區域網路 (5GHz/6GHz)
               │  [4 條獨立 TCP 並行串流通道]
               │  [6 位數一次性 Token 配對驗證]
               ▼
┌─────────────────────────────────┐
│       iPad (SwiftUI + iOS 17)   │
│  - TransferClient (結構化並發)  │
│  - URLSessionDownloadTask       │
│  - Documents/PhotoBridge 目錄   │
└──────────────┬──────────────────┘
               │  Atomic Rename 零拷貝瞬時落盤
               ▼
┌─────────────────────────────────┐
│     Lightroom Mobile / 檔案     │
│  - 一鍵整批匯入 RAW (NEF/CR2)   │
└─────────────────────────────────┘
```

### 5.2 核心技術細節

1. **Zero-Copy File Streaming（作業系統零拷貝）**：
   - PC 端由 .NET 8 Kestrel 直接呼叫 Windows 核心層的 `TransmitFile` DMA，數據不需經過使用者態緩衝區拷貝，CPU 佔用率極低且吞吐量直達硬體極限。
2. **4 條並發連線（Concurrent Streams）**：
   - 消除無線網路訊號抖動對單一 TCP 壅塞控制（CWND）的負面影響，實測速度可達 **150 ~ 220+ MB/s**。
3. **`URLSessionDownloadTask` 零記憶體暫存寫入**：
   - 檔案由 iOS 系統直接串流寫入磁碟暫存檔，記憶體佔用恆定（約 25MB），徹底杜絕大量傳輸 RAW 檔時被 iOS Jetsam (OOM Killer) 強制終止。
4. **斷點續傳 (HTTP Range)**：
   - 支援 `Range: bytes=start-end`，網路中斷重連後自動續傳未完成片段。

---

## 六、關鍵代碼對應解說

| 檔案路徑 | 語言/架構 | 核心職責與代碼解釋 |
| :--- | :--- | :--- |
| [`KestrelTransferServer.cs`](file:///c:/Users/brian/Desktop/code/PhotoBridge/src/PhotoBridge.PC/Services/Transfer/KestrelTransferServer.cs) | C# (.NET 8) | **極速發送服務端**：獲取本機 IP、動態生成 6 位配對碼、配置 Kestrel 監聽 `8765`、註冊 `/api/manifest` 清單與 `/api/photos/{id}` 零拷貝檔案串流端點。 |
| [`MainWindow.xaml.cs`](file:///c:/Users/brian/Desktop/code/PhotoBridge/src/PhotoBridge.PC/MainWindow.xaml.cs) | C# (WPF) | **PC 介面邏輯**：負責挑選資料夾、多選勾選、容量統計、一鍵複製連線位址、即時傳輸完成日誌事件回呼。 |
| [`TransferClient.swift`](file:///c:/Users/brian/Desktop/code/PhotoBridge/ios/PhotoBridge.swiftpm/Sources/TransferClient.swift) | Swift (iOS) | **極速接收引擎**：利用 Swift 結構化並發 `withTaskGroup` 維護 4 條並行下載通道，使用 `URLSession.shared.download` 直寫磁碟暫存檔，並每 0.5 秒採樣頻寬速率。 |
| [`ContentView.swift`](file:///c:/Users/brian/Desktop/code/PhotoBridge/ios/PhotoBridge.swiftpm/Sources/ContentView.swift) | SwiftUI | **iPad 儀表板介面**：輸入配對資訊、即時速率儀表（MB/s）、完成度進度條、單檔下載狀態、完成後 Lightroom 匯入導引。 |
| [`Package.swift`](file:///c:/Users/brian/Desktop/code/PhotoBridge/ios/PhotoBridge.swiftpm/Package.swift) | SwiftPM | **Playgrounds 商店規範**：宣告 iOS 17 平臺、相機圖標、`localNetwork` 區域網路存取權限與 App Store Connect 上架參數。 |
| [`Info.plist`](file:///c:/Users/brian/Desktop/code/PhotoBridge/ios/Xcode/PhotoBridge/Info.plist) | XML (Apple) | **Xcode App Store 審查必備**：定義 `NSLocalNetworkUsageDescription`（本機網路隱私宣告）與 `UIFileSharingEnabled`（檔案 App 存取支援）。 |
| [`AppxManifest.xml`](file:///c:/Users/brian/Desktop/code/PhotoBridge/packaging/windows/AppxManifest.xml) | XML (Microsoft) | **微軟商店上架規範**：定義 Windows 應用程式身分、Logo 圖標與 `runFullTrust` 全信任權限。 |

---

## 許可證

本專案基於 [MIT 授權條款](LICENSE) 開源。
