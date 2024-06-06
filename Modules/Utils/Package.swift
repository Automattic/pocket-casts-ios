// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PocketCastsUtils",
    platforms: [
        .iOS(.v15), .watchOS(.v8)
    ],
    products: [
        .library(
            name: "PocketCastsUtils",
            type: .dynamic,
            targets: ["PocketCastsUtils"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Pulse.git", from: "4.2.3")
    ],
    targets: [
        .target(
            name: "PocketCastsUtils",
            dependencies: ["Pulse", .product(name: "PulseUI", package: "Pulse")],
            path: "Sources"
        ),
        .testTarget(
            name: "PocketCastsUtilsTests",
            dependencies: ["PocketCastsUtils"],
            path: "Tests"
        )
    ]
)
