import SwiftUI

struct ContentView: View {
    @StateObject private var client = TransferClient()
    @AppStorage("last_pc_address") private var savedPcAddress = "192.168.1."
    @AppStorage("last_pairing_code") private var savedPairingCode = ""

    var body: some View {
        NavigationStack {
            Form {
                // 1. 連線至 PC 面板
                Section("1. 連線至 PC") {
                    HStack {
                        Image(systemName: "desktopcomputer")
                            .foregroundColor(.blue)
                        TextField("PC 位址 (例如 192.168.1.50:8765)", text: $client.serverAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }

                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                        TextField("6 位數配對碼 (例如 829314)", text: $client.pairingCode)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.numberPad)
                    }

                    Button {
                        savedPcAddress = client.serverAddress
                        savedPairingCode = client.pairingCode
                        Task {
                            await client.fetchManifest()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if client.isConnected {
                                Image(systemName: "arrow.clockwise")
                                Text("重新整理清單")
                            } else {
                                Image(systemName: "link")
                                Text("連線並同步清單")
                            }
                            Spacer()
                        }
                        .fontWeight(.semibold)
                    }
                    .disabled(client.isTransferring)
                }

                // 2. 傳輸狀態與儀表板
                if client.isConnected {
                    Section("2. 極速傳輸儀表板") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("即時速率")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f MB/s", client.currentSpeedMBs))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(client.currentSpeedMBs > 0 ? .green : .primary)
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text("完成進度")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(client.completedCount) / \(client.totalCount) 張")
                                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                                }
                            }

                            // 總進度條
                            ProgressView(value: Double(client.completedCount), total: max(1.0, Double(client.totalCount)))
                                .tint(.blue)

                            if client.isTransferring {
                                Button(role: .destructive) {
                                    client.cancelTransfer()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "stop.circle.fill")
                                        Text("停止傳輸")
                                        Spacer()
                                    }
                                }
                            } else {
                                Button {
                                    client.startFastTransfer()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "bolt.fill")
                                        Text("開始極速傳輸 (4 條並行通道)")
                                        Spacer()
                                    }
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // 3. 系統狀態
                Section("狀態") {
                    HStack {
                        Image(systemName: client.isConnected ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundColor(client.isConnected ? .green : .blue)
                        Text(client.statusMessage)
                            .font(.callout)
                    }

                    if client.completedCount > 0 && client.completedCount == client.totalCount {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("💡 如何在 Lightroom 匯入：")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("打開 Lightroom App ➔ 點擊「+ 匯入」➔ 選擇「來自檔案」➔ 瀏覽至「我的 iPad > PhotoBridge」即可全選匯入！")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                // 4. 照片清單
                if !client.items.isEmpty {
                    Section("照片清單 (\(client.items.count))") {
                        List(client.items) { item in
                            HStack {
                                Image(systemName: iconForFormat(item.manifestItem.format))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)

                                VStack(alignment: .leading) {
                                    Text(item.manifestItem.fileName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Text("\(item.manifestItem.format) • \(item.manifestItem.sizeLabel)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                switch item.status {
                                case .waiting:
                                    Image(systemName: "clock")
                                        .foregroundColor(.secondary)
                                case .downloading:
                                    ProgressView()
                                        .scaleEffect(0.8)
                                case .completed:
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                case .failed(let msg):
                                    Text(msg)
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("PhotoBridge")
            .onAppear {
                if client.serverAddress.isEmpty && !savedPcAddress.isEmpty {
                    client.serverAddress = savedPcAddress
                }
                if client.pairingCode.isEmpty && !savedPairingCode.isEmpty {
                    client.pairingCode = savedPairingCode
                }
            }
        }
    }

    private func iconForFormat(_ format: String) -> String {
        switch format.uppercased() {
        case "NEF", "CR2", "ARW", "DNG":
            return "camera.badge.ellipsis"
        default:
            return "photo"
        }
    }
}
