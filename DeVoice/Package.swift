// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeVoice",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DeVoice",
            path: "Sources",
            exclude: ["Info.plist"]
        )
    ]
)
