// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [
        .iOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(
            name: "Modules",

            targets: ["Modules"]
        ),
        .library(
            name: "PocketCastsDependencyInjection",

            targets: ["PocketCastsDependencyInjection"]
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
        ),
        .target(
            name: "PocketCastsDependencyInjection",
            path: "Sources/PocketCastsDependencyInjection"
        ),
        .testTarget(
            name: "PocketCastsDependencyInjectionTests",
            dependencies: ["PocketCastsDependencyInjection"],
            path: "Tests/PocketCastsDependencyInjectionTests"
        )
    ]
)
