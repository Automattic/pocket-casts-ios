// swift-tools-version: 5.10

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Modules",
    platforms: [
        .iOS(.v16), .watchOS(.v9), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Modules",
            targets: ["Modules"]
        ),
        .library(
            name: "PocketCastsDependencyInjection",
            targets: ["PocketCastsDependencyInjection"]
        ),
        .library(
            name: "GRDBMacros",
            targets: ["GRDBMacros"]
        ),
        .library(
            name: "PocketCastsUtils",
            targets: ["PocketCastsUtils"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
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
        ),
        .target(
            name: "GRDBMacros",
            dependencies: [
                "GRDBMacrosPlugin",
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/GRDBMacros"
        ),
        .macro(
            name: "GRDBMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/GRDBMacrosPlugin"
        ),
        .testTarget(
            name: "GRDBMacrosTests",
            dependencies: [
                "GRDBMacrosPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            path: "Tests/GRDBMacrosTests"
        ),
        .target(
            name: "PocketCastsUtils",
            path: "Sources/PocketCastsUtils",
            swiftSettings: [
                .unsafeFlags(["-enable-testing"], .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "PocketCastsUtilsTests",
            dependencies: ["PocketCastsUtils"],
            path: "Tests/PocketCastsUtilsTests"
        )
    ]
)
