// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "PocketCastsModules",
    platforms: [
        .iOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(
            name: "PocketCastsModules",
            type: .dynamic,
            targets: ["PocketCastsModules"]
        )
    ],
    targets: [
        .target(
            name: "PocketCastsModules",
            path: "Sources/PocketCastsModules"
        ),
        .testTarget(
            name: "PocketCastsModulesTests",
            dependencies: ["PocketCastsModules"],
            path: "Tests/PocketCastsModulesTests"
        )
    ]
)
