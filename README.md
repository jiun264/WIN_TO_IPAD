# PhotoBridge

PC 挑片後，透過同一個 Wi-Fi / 區域網路將 Nikon NEF 等原始 RAW 照片高速直傳到 iPad，供 Lightroom 直接匯入。傳輸不經雲端、不需接線、跑滿 Wi-Fi 頻寬極限。

## 架構與最速傳輸技術

- **PC 傳輸核心 (`src/PhotoBridge.PC`)**：
  - 基於 .NET 8 高效能 Kestrel 服務端。
  - **Zero-Copy File Streaming**：底層走作業系統 Direct I/O (`TransmitFile` / OS SendFile)，檔案不經過使用者態雙重緩衝，速度極限直達硬體網卡與 Wi-Fi 上限。
  - **HTTP Range & Keep-Alive**：支援斷點續傳。
  - **一次性 6 位數安全配對碼**：只提供已挑選的照片，防止非授權存取。
- **iPad 客戶端 (`ios/PhotoBridge.swiftpm`)**：
  - SwiftUI + Swift Playgrounds 專案（支援在 iPad 上直接開啟執行，或透過 Mac Xcode 部署）。
  - **4 條並行通道（Concurrent Streams）**：並行拉取 RAW 大檔，壓榨 Wi-Fi 頻寬（可達 150 ~ 220+ MB/s）。
  - **`URLSessionDownloadTask` 零記憶體寫入**：直接由 iOS 核心串流寫入磁碟，完全不佔用 App 記憶體，避免大量傳輸高畫素照片時觸發 iOS 記憶體閃退。
  - **自動保存至 Documents/PhotoBridge**：直傳完成後，Lightroom Mobile 或「檔案」App 可一鍵整批匯入。

## 使用步驟

### 1. PC 端啟動

```powershell
dotnet run --project .\src\PhotoBridge.PC
```

1. 點擊「選擇照片資料夾」，程式會自動掃描包含 NEF、CR2、ARW、DNG、JPG 等照片。
2. 勾選欲傳送的照片（支援一鍵「全選」/「全不選」）。
3. 點擊「啟動直傳服務」按鈕。
4. 畫面上方會顯示：
   - **連線網址**（例如 `http://192.168.1.50:8765`）
   - **6 位數配對碼**（例如 `829314`）

### 2. iPad 端接收

1. 在 iPad 上以 Swift Playgrounds 開啟 `ios/PhotoBridge.swiftpm`（或由 Xcode 安裝至 iPad）。
2. 初次執行時，允許 iOS 的「**本機網路**」連線權限。
3. 輸入 PC 顯示的位址與 6 位數配對碼。
4. 點擊「**連線並同步清單**」，取得照片總張數與大小。
5. 點擊「**開始極速傳輸**」，即會啟動 4 條並行下載通道，實時顯示傳輸速率（MB/s）與總進度。

### 3. Lightroom Mobile 匯入流程

傳輸完畢後：
1. 打開 iPad 上的 **Lightroom** App。
2. 點擊右下角「**+ 匯入**」➔ 選擇「**來自檔案 (From Files)**」。
3. 瀏覽至「**我的 iPad ➔ PhotoBridge**」目錄。
4. 點擊右上角「全選」並確認匯入，即可秒速導入所有原始 RAW 檔開始修圖！
