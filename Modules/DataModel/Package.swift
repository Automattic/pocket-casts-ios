// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PocketCastsDataModel",
    platforms: [
        .iOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(
            name: "PocketCastsDataModel",
            type: .dynamic,
            targets: ["PocketCastsDataModel"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.2.0"),
        .package(path: "../Utils/"),
        .package(path: "../")
    ],
    targets: [
        .target(
            name: "PocketCastsDataModel",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "PocketCastsUtils", package: "Utils"),
                .product(name: "GRDBMacros", package: "Modules")
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-enable-testing"], .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "PocketCastsDataModelTests",
            dependencies: ["PocketCastsDataModel"],
            path: "Tests"
        )
    ]
)
