// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MontyWorkout",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MontyWorkout",
            path: "Sources/MontyWorkout",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
