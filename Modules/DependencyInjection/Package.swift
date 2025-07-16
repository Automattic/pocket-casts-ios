// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PocketCastsDependencyInjection",
    platforms: [
        .iOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(
            name: "PocketCastsDependencyInjection",
            type: .dynamic,
            targets: ["PocketCastsDependencyInjection"]),
    ],
    targets: [
        .target(
            name: "PocketCastsDependencyInjection",
            path: "Sources"
        ),
        .testTarget(
            name: "PocketCastsDependencyInjectionTests",
            dependencies: ["PocketCastsDependencyInjection"],
            path: "Tests"
        ),
    ]
)
