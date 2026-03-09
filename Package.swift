// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "gather-windows",
    platforms: [
        .macOS(.v14)  // Requires macOS 14+ for Swift Concurrency
    ],
    products: [
        .executable(
            name: "gather-windows",
            targets: ["gather-windows"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "gather-windows",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
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
