// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "gather-windows",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Gather Windows",
            targets: ["gather-windows"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "gather-windows",
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
