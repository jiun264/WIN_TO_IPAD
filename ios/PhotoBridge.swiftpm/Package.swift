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
            bundleIdentifier: "com.photobridge.app",
            teamIdentifier: "",
            displayVersion: "0.1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .globe),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [.pad],
            supportedInterfaceOrientations: [.portrait, .landscapeLeft, .landscapeRight]
        )
    ],
    targets: [
        .executableTarget(name: "PhotoBridge", path: "Sources")
    ]
)
