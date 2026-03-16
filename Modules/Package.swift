// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [
        .iOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(
            name: "Modules",
            type: .dynamic,
            targets: ["Modules"]
        )
    ],
    targets: [
        .target(
            name: "Modules",
            path: "Sources/Modules"
        ),
        .testTarget(
            name: "ModulesTests",
            dependencies: ["Modules"],
            path: "Tests/ModulesTests"
        )
    ]
)
