// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HeurikaCore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "HeurikaCore", targets: ["HeurikaCore"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HeurikaCore",
            dependencies: [],
            path: "Sources/HeurikaCore"
        ),
        .testTarget(
            name: "HeurikaCoreTests",
            dependencies: ["HeurikaCore"],
            path: "Tests/HeurikaCoreTests"
        )
    ]
)
