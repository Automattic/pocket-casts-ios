// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PocketCastsServer",
    platforms: [
        .iOS(.v15), .watchOS(.v7)
    ], products: [
        .library(
            name: "PocketCastsServer",
            type: .dynamic,
            targets: ["PocketCastsServer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.0.0"),
        .package(path: "../DataModel/"),
        .package(path: "../Utils/")
    ],
    targets: [
        .target(
            name: "PocketCastsServer",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "PocketCastsDataModel", package: "DataModel"),
                .product(name: "PocketCastsUtils", package: "Utils")
            ],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("CFNetwork", .when(platforms: [.iOS])),
                .linkedFramework("AuthenticationServices", .when(platforms: [.iOS, .watchOS]))
            ]
        ),
        .testTarget(
            name: "PocketCastsServerTests",
            dependencies: ["PocketCastsServer"],
            path: "Tests"
        )
    ]
)
