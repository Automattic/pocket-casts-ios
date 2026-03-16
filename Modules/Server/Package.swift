// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PocketCastsServer",
    platforms: [
        .iOS(.v16), .watchOS(.v9)
    ], products: [
        .library(
            name: "PocketCastsServer",
            type: .dynamic,
            targets: ["PocketCastsServer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.0.0"),
        .package(url: "https://github.com/danielebogo/Swime", branch: "master"),
        .package(path: "../")
    ],
    targets: [
        .target(
            name: "PocketCastsServer",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "Swime", package: "Swime"),
                .product(name: "PocketCastsDataModel", package: "Modules"),
                .product(name: "PocketCastsUtils", package: "Modules")
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-enable-testing"], .when(configuration: .debug))
            ],
            linkerSettings: [
                .linkedFramework("CFNetwork", .when(platforms: [.iOS])),
                .linkedFramework("AuthenticationServices", .when(platforms: [.iOS, .watchOS]))
            ]
        ),
        .testTarget(
            name: "PocketCastsServerTests",
            dependencies: ["PocketCastsServer"],
            path: "Tests",
            resources: [.copy("Fixtures")]
        )
    ]
)
