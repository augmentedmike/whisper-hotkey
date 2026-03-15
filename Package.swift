// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WhisperHotkey",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/exPHAT/SwiftWhisper.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "WhisperHotkey",
            dependencies: ["SwiftWhisper"],
            path: "Sources"
        ),
    ]
)
