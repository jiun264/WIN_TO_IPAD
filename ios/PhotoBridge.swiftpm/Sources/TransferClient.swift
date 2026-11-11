import Foundation
import Combine

public struct ManifestResponse: Codable {
    public let pairingCode: String
    public let count: Int
    public let totalBytes: Int64
    public let items: [PhotoManifestItem]
}

public struct PhotoManifestItem: Identifiable, Codable, Equatable {
    public let id: String
    public let fileName: String
    public let sizeBytes: Int64
    public let format: String

    public var sizeLabel: String {
        if sizeBytes >= 1024 * 1024 * 1024 {
            return String(format: "%.2f GB", Double(sizeBytes) / 1_073_741_824.0)
        } else {
            return String(format: "%.1f MB", Double(sizeBytes) / 1_048_576.0)
        }
    }
}

public enum TransferItemStatus: Equatable {
    case waiting
    case downloading
    case completed
    case failed(String)
}

public struct TransferItemState: Identifiable, Equatable {
    public var id: String { manifestItem.id }
    public let manifestItem: PhotoManifestItem
    public var status: TransferItemStatus
}

@MainActor
public final class TransferClient: ObservableObject {
    @Published public var serverAddress: String = ""
    @Published public var pairingCode: String = ""
    @Published public var isConnected: Bool = false
    @Published public var isTransferring: Bool = false
    @Published public var statusMessage: String = "請輸入 PC 顯示的位址與配對碼"

    @Published public var items: [TransferItemState] = []
    @Published public var completedCount: Int = 0
    @Published public var totalCount: Int = 0
    @Published public var transferredBytes: Int64 = 0
    @Published public var totalBytes: Int64 = 0
    @Published public var currentSpeedMBs: Double = 0.0

    private var session: URLSession
    private var transferTask: Task<Void, Never>?
    private var speedTimer: Timer?
    private var lastBytesForSpeed: Int64 = 0

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600
        config.httpMaximumConnectionsPerHost = 4
        self.session = URLSession(configuration: config)
    }

    /// 取得檔案存放的目錄 (Documents/PhotoBridge)
    public static var destinationDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory,  in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("PhotoBridge", isDirectory: true)
        
        var isDir: ObjCBool = true
        if !FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return dir
    }

    /// 1. 測試連線並同步清單
    public func fetchManifest() async {
        guard !serverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "請輸入 PC 位址"
            return
        }

        var normalizedUrl = serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedUrl.lowercased().hasPrefix("http://") && !normalizedUrl.lowercased().hasPrefix("https://") {
            normalizedUrl = "http://" + normalizedUrl
        }
        serverAddress = normalizedUrl

        guard let baseUrl = URL(string: normalizedUrl) else {
            statusMessage = "無效的伺服器位址"
            return
        }

        let cleanCode = pairingCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanCode.isEmpty else {
            statusMessage = "請輸入 6 位數配對碼"
            return
        }

        let manifestUrl = baseUrl.appendingPathComponent("api/manifest")
        var components = URLComponents(url: manifestUrl, resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: "code", value: cleanCode)]

        guard let targetUrl = components?.url else {
            statusMessage = "網址建構失敗"
            return
        }

        statusMessage = "連線並取得照片清單中..."

        do {
            let (data, response) = try await session.data(from: targetUrl)
            guard let httpResponse = response as? HTTPURLResponse else {
                statusMessage = "伺服器未回應"
                return
            }

            if httpResponse.statusCode == 401 {
                statusMessage = "配對碼錯誤，請重新確認 PC 畫面"
                return
            }

            guard httpResponse.statusCode == 200 else {
                statusMessage = "伺服器錯誤 (狀態碼: \(httpResponse.statusCode))"
                return
            }

            let manifest = try JSONDecoder().decode(ManifestResponse.self, from: data)
            self.items = manifest.items.map { TransferItemState(manifestItem: $0, status: .waiting) }
            self.totalCount = manifest.count
            self.totalBytes = manifest.totalBytes
            self.completedCount = 0
            self.transferredBytes = 0
            self.isConnected = true
            self.statusMessage = "已連線！共有 \(manifest.count) 張照片（合計 \(formatBytes(manifest.totalBytes))）"
        } catch {
            self.statusMessage = "連線失敗: \(error.localizedDescription)"
        }
    }

    /// 2. 啟動極速多線程傳輸
    public func startFastTransfer() {
        guard isConnected, !items.isEmpty, !isTransferring else { return }

        isTransferring = true
        statusMessage = "極速傳輸中..."
        startSpeedMeter()

        transferTask = Task {
            let baseUrl = URL(string: self.serverAddress)!
            let code = self.pairingCode.trimmingCharacters(in: .whitespacesAndNewlines)
            let destDir = Self.destinationDirectory

            // 最大並發下載連線數（榨乾 Wi-Fi 頻寬）
            let maxConcurrent = 4
            let queue = self.items.map { $0.manifestItem }
            var currentIndex = 0
            let total = queue.count

            await withTaskGroup(of: (String, Bool, String?).self) { group in
                // 先塞入第一批任務
                for _ in 0..<min(maxConcurrent, total) {
                    if currentIndex < total {
                        let item = queue[currentIndex]
                        currentIndex += 1
                        group.addTask {
                            return await self.downloadSinglePhoto(item: item, baseUrl: baseUrl, code: code, destDir: destDir)
                        }
                    }
                }

                // 當任一個下載完成，立即補上下一個任務
                for await (id, success, errorMsg) in group {
                    self.updateItemStatus(id: id, success: success, errorMsg: errorMsg)

                    if currentIndex < total {
                        let nextItem = queue[currentIndex]
                        currentIndex += 1
                        group.addTask {
                            return await self.downloadSinglePhoto(item: nextItem, baseUrl: baseUrl, code: code, destDir: destDir)
                        }
                    }
                }
            }

            self.stopSpeedMeter()
            self.isTransferring = false
            self.statusMessage = "🎉 傳輸完成！已存入「檔案/PhotoBridge」目錄"
        }
    }

    /// 單一照片極速下載（底層使用系統原生 DownloadTask 直寫磁碟，不吃記憶體）
    private nonisolated func downloadSinglePhoto(
        item: PhotoManifestItem,
        baseUrl: URL,
        code: String,
        destDir: URL
    ) async -> (String, Bool, String?) {
        let photoUrl = baseUrl.appendingPathComponent("api/photos/\(item.id)")
        var components = URLComponents(url: photoUrl, resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: "code", value: code)]

        guard let targetUrl = components?.url else {
            return (item.id, false, "URL 格式無效")
        }

        do {
            // URLSession.download 直寫磁碟暫存檔，零記憶體佔用
            let (tempLocation, response) = try await session.download(from: targetUrl)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return (item.id, false, "下載失敗")
            }

            let destinationUrl = destDir.appendingPathComponent(item.fileName)
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                try? FileManager.default.removeItem(at: destinationUrl)
            }

            // 零拷貝瞬時搬移
            try FileManager.default.moveItem(at: tempLocation, to: destinationUrl)
            return (item.id, true, nil)
        } catch {
            return (item.id, false, error.localizedDescription)
        }
    }

    private func updateItemStatus(id: String, success: Bool, errorMsg: String?) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if success {
            items[index].status = .completed
            completedCount += 1
            transferredBytes += items[index].manifestItem.sizeBytes
        } else {
            items[index].status = .failed(errorMsg ?? "失敗")
        }
    }

    private func startSpeedMeter() {
        lastBytesForSpeed = transferredBytes
        speedTimer?.invalidate()
        speedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                let current = self.transferredBytes
                let delta = current - self.lastBytesForSpeed
                self.lastBytesForSpeed = current
                self.currentSpeedMBs = max(0, Double(delta) / 1024.0 / 1024.0 / 0.5)
            }
        }
    }

    private func stopSpeedMeter() {
        speedTimer?.invalidate()
        speedTimer = nil
        currentSpeedMBs = 0.0
    }

    public func cancelTransfer() {
        transferTask?.cancel()
        transferTask = nil
        stopSpeedMeter()
        isTransferring = false
        statusMessage = "傳輸已取消"
    }

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes >= 1024 * 1024 * 1024 {
            return String(format: "%.2f GB", Double(bytes) / 1_073_741_824.0)
        } else {
            return String(format: "%.1f MB", Double(bytes) / 1_048_576.0)
        }
    }
}
