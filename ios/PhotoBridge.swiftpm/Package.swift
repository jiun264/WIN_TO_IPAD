// swift-tools-version: 5.9
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "PhotoBridge",
    platforms: [.iOS(.v17)],
    products: [
        .iOSApplication(
            name: "PhotoBridge",
            targets: ["PhotoBridge"],
            bundleIdentifier: "com.jiun264.PhotoBridge",
            teamIdentifier: "",
            displayVersion: "1.0.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .camera),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [.portrait, .landscapeLeft, .landscapeRight],
            capabilities: [
                .localNetwork(purposeString: "需要本機區域網路連線以高速直傳照片至 iPad"),
                .outgoingNetworkConnections()
            ]
        )
    ],
    targets: [
        .executableTarget(name: "PhotoBridge", path: "Sources")
    ]
)
