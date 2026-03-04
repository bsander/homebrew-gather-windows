// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "gather-windows",
    platforms: [
        .macOS(.v14)  // Requires macOS 14+ for Swift Concurrency
    ],
    products: [
        .executable(
            name: "gather-windows-swift",
            targets: ["gather-windows"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "gather-windows",
            dependencies: [],
            path: "Sources/gather-windows",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        .testTarget(
            name: "gather-windowsTests",
            dependencies: ["gather-windows"],
            path: "Tests/gather-windowsTests"
        ),
    ]
)
