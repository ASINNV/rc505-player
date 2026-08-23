// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RC505Player",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "RC505Player",
            path: "Sources/RC505Player"
        )
    ]
)
