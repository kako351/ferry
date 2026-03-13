// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ADBDesktop",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ADBDesktop",
            path: "ADBDesktop"
        )
    ]
)
