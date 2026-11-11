// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HandCursor",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "HandCursor",
            path: "Sources/HandCursor"
        )
    ]
)
