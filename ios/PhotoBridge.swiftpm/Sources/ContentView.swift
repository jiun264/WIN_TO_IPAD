import SwiftUI

struct ContentView: View {
    @State private var pcAddress = ""
    @State private var pairingCode = ""
    @State private var isConnected = false
    @State private var statusMessage = "請在 PC 開啟 PhotoBridge，輸入配對資訊"

    var body: some View {
        NavigationStack {
            Form {
                Section("連接 PC") {
                    TextField("PC 位址，例如 192.168.1.20:8765", text: $pcAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    TextField("配對碼", text: $pairingCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button(isConnected ? "已連線" : "連線") {
                        statusMessage = "PC 配對服務尚未接通"
                    }
                    .disabled(isConnected)
                }

                Section("傳輸佇列") {
                    ContentUnavailableView(
                        "尚未加入照片",
                        systemImage: "photo.stack",
                        description: Text("從 PC 選取照片後，照片會顯示在這裡。")
                    )
                    .frame(maxWidth: .infinity)
                }

                Section("狀態") {
                    Label(statusMessage, systemImage: isConnected ? "checkmark.circle" : "info.circle")
                }
            }
            .navigationTitle("PhotoBridge")
        }
    }
}
