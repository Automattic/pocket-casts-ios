// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PocketCastsDataModel",
    platforms: [
        .iOS(.v15), .watchOS(.v7)
    ],
    products: [
        .library(
            name: "PocketCastsDataModel",
            type: .dynamic,
            targets: ["PocketCastsDataModel"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ccgus/fmdb.git", from: "2.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.27.0"),
        .package(path: "../Utils/")
    ],
    targets: [
        .target(
            name: "PocketCastsDataModel",
            dependencies: [
                .product(name: "FMDB", package: "fmdb"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "PocketCastsUtils", package: "Utils")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PocketCastsDataModelTests",
            dependencies: ["PocketCastsDataModel"],
            path: "Tests"
        )
    ]
)
