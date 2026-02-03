// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TraeManager",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "TraeManager",
            path: "Sources"
        )
    ]
)
