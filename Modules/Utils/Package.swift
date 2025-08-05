// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PocketCastsUtils",
    platforms: [
        .iOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(
            name: "PocketCastsUtils",
            type: .dynamic,
            targets: ["PocketCastsUtils"]
        )
    ],
    targets: [
        .target(
            name: "PocketCastsUtils",
            path: "Sources"
        ),
        .testTarget(
            name: "PocketCastsUtilsTests",
            dependencies: ["PocketCastsUtils"],
            path: "Tests"
        )
    ]
)
