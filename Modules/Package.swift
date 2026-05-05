// swift-tools-version: 5.10

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Modules",
    platforms: [
        .iOS(.v16), .watchOS(.v9), .macOS(.v10_15), .tvOS(.v17)
    ],
    products: XcodeSupport.products + [
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
        ),
        .library(
            name: "PocketCastsSharedModels",
            targets: ["PocketCastsSharedModels"]
        ),
        .library(
            name: "PocketCastsDataModel",
            targets: ["PocketCastsDataModel"]
        ),
        .library(
            name: "PocketCastsServer",
            targets: ["PocketCastsServer"]
        ),
        .library(
            name: "EndOfYear",
            targets: ["EndOfYear"]
        ),
        .library(
            name: "Modules",
            targets: ["Modules"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "510.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.0.0"),
        .package(url: "https://github.com/danielebogo/Swime", branch: "master"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0"),
        .package(url: "https://github.com/ra1028/DifferenceKit", from: "1.2.0"),
        .package(url: "https://github.com/krisk/fuse-swift", from: "1.4.0"),
        .package(url: "https://github.com/shiftyjelly/SwipeCellKit", from: "2.7.6"),
        .package(url: "https://github.com/Automattic/Automattic-Tracks-iOS", from: "4.2.1"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.23.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.1.0"),
        .package(url: "https://github.com/Automattic/Agrume", from: "5.6.12"),
        .package(url: "https://github.com/joeldev/JLRoutes", from: "2.1.1"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.10.2"),
        .package(url: "https://github.com/dagronf/SwiftSubtitles", from: "1.8.3"),
        .package(url: "https://github.com/Automattic/google-cast", from: "1.0.1"),
        .package(url: "https://github.com/ksemianov/WrappingHStack", from: "0.2.0"),
        .package(url: "https://github.com/Automattic/pocket-casts-ios-fingerprint", branch: "trunk"),
    ],
    targets: XcodeSupport.targets + [
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
        ),
        .target(
            name: "PocketCastsSharedModels",
            path: "Sources/PocketCastsSharedModels"
        ),
        .testTarget(
            name: "PocketCastsSharedModelsTests",
            dependencies: ["PocketCastsSharedModels"],
            path: "Tests/PocketCastsSharedModelsTests"
        ),
        .target(
            name: "PocketCastsDataModel",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                "PocketCastsUtils",
                "GRDBMacros",
            ],
            path: "Sources/PocketCastsDataModel",
            swiftSettings: [
                .unsafeFlags(["-enable-testing"], .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "PocketCastsDataModelTests",
            dependencies: ["PocketCastsDataModel"],
            path: "Tests/PocketCastsDataModelTests"
        ),
        .target(
            name: "PocketCastsServer",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "Swime", package: "Swime"),
                "PocketCastsDataModel",
                "PocketCastsUtils",
            ],
            path: "Sources/PocketCastsServer",
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
            path: "Tests/PocketCastsServerTests",
            resources: [.copy("Fixtures")]
        ),
        .target(
            name: "EndOfYear",
            dependencies: [
                "PocketCastsDataModel",
                "PocketCastsServer",
                "PocketCastsUtils",
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            path: "Sources/EndOfYear"
        ),
        .binaryTarget(
            name: "EventHorizonSDK",
            url: "https://a8c-libs.s3.amazonaws.com/ios/EventHorizon/pocket-casts-2026-04-29-13-55-38/EventHorizon-pocket-casts-2026-04-29-13-55-38.xcframework.zip",
            checksum: "773066f52a81fcc6405efbdeaf825a67d36cfe2b4d3e1855f508b6cf8faa7133"
        ),
        .target(
            name: "Modules",
            path: "Sources/Modules"
        ),
        .testTarget(
            name: "ModulesTests",
            dependencies: ["Modules"],
            path: "Tests/ModulesTests"
        )
    ]
)

// MARK: - XcodeSupport (Xcode Targets)

// Below are dependencies for the respective Xcode targets.
//
// You can add internal or third-party dependencies to these targets or even
// source files and resources.
//
// - note: SwiftPM automatically detects which modules are shared between
//   multiple targets and decides when to use dynamic frameworks.

enum XcodeTargetNames {
    static let appClip = "Pocket Casts App Clip"
    static let notificationExtension = "NotificationExtension"
    static let podcasts = "podcasts"
    static let pocketCastsWatchApp = "Pocket Casts Watch App"
    static let podcastsIntents = "PodcastsIntents"
    static let podcastsIntentsUI = "PodcastsIntentsUI"
    static let widgetExtension = "WidgetExtension"
    static let pocketCastsTvApp = "Pocket Casts TV App"
}

enum XcodeSupport {
    static var products: [Product] {
        [
            XcodeTargetNames.appClip,
            XcodeTargetNames.notificationExtension,
            XcodeTargetNames.podcasts,
            XcodeTargetNames.pocketCastsWatchApp,
            XcodeTargetNames.podcastsIntents,
            XcodeTargetNames.podcastsIntentsUI,
            XcodeTargetNames.widgetExtension,
            XcodeTargetNames.pocketCastsTvApp,
        ].map { .supportingProduct(forXcodeTarget: $0) }
    }

    static var targets: [Target] {
        [
            .xcodeTarget(
                XcodeTargetNames.podcasts,
                dependencies: [
                    "PocketCastsDataModel",
                    "PocketCastsServer",
                    "PocketCastsUtils",
                    "PocketCastsSharedModels",
                    "PocketCastsDependencyInjection",
                    "EventHorizonSDK",
                    .product(name: "Lottie", package: "lottie-ios"),
                    .product(name: "DifferenceKit", package: "DifferenceKit"),
                    .product(name: "Fuse", package: "fuse-swift"),
                    .product(name: "SwipeCellKit", package: "SwipeCellKit"),
                    .product(name: "AutomatticEncryptedLogs", package: "Automattic-Tracks-iOS"),
                    .product(name: "AutomatticTracks", package: "Automattic-Tracks-iOS"),
                    .product(name: "FirebaseAnalyticsWithoutAdIdSupport", package: "firebase-ios-sdk"),
                    .product(name: "FirebasePerformance", package: "firebase-ios-sdk"),
                    .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                    .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                    .product(name: "Agrume", package: "Agrume"),
                    .product(name: "JLRoutes", package: "JLRoutes"),
                    .product(name: "Kingfisher", package: "Kingfisher"),
                    .product(name: "SwiftSubtitles", package: "SwiftSubtitles"),
                    .product(name: "GoogleCast", package: "google-cast"),
                    .product(name: "WrappingHStack", package: "WrappingHStack"),
                    .product(name: "Fingerprint", package: "pocket-casts-ios-fingerprint"),
                    "EndOfYear",
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.appClip,
                dependencies: [
                    "PocketCastsDataModel",
                    "PocketCastsServer",
                    "PocketCastsUtils",
                    "PocketCastsDependencyInjection",
                    "EventHorizonSDK",
                    .product(name: "AutomatticTracks", package: "Automattic-Tracks-iOS"),
                    .product(name: "FirebaseAnalyticsWithoutAdIdSupport", package: "firebase-ios-sdk"),
                    .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                    .product(name: "Kingfisher", package: "Kingfisher"),
                    .product(name: "Lottie", package: "lottie-ios"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.pocketCastsWatchApp,
                dependencies: [
                    "PocketCastsDataModel",
                    "PocketCastsServer",
                    "PocketCastsUtils",
                    "PocketCastsDependencyInjection",
                    "EventHorizonSDK",
                    .product(name: "AutomatticTracks", package: "Automattic-Tracks-iOS"),
                    .product(name: "Kingfisher", package: "Kingfisher"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.notificationExtension,
                dependencies: [
                    "PocketCastsServer",
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.podcastsIntents,
                dependencies: [
                    "PocketCastsSharedModels",
                    .product(name: "Fuse", package: "fuse-swift"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.podcastsIntentsUI,
                dependencies: [
                    .product(name: "Fuse", package: "fuse-swift"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.widgetExtension,
                dependencies: [
                    "PocketCastsUtils",
                    "PocketCastsSharedModels",
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.pocketCastsTvApp,
                dependencies: [
                    "PocketCastsUtils"
                ]
            ),
        ]
    }
}

extension Product {
    static func supportingProduct(forXcodeTarget targetName: String) -> Product {
        .library(
            name: "XcodeTarget_\(targetName)",
            targets: ["XcodeTarget_\(targetName)"]
        )
    }
}

extension Target {
    static func xcodeTarget(_ name: String, dependencies: [Dependency]) -> Target {
        .target(
            name: name.supportingName,
            dependencies: dependencies,
            path: "Sources/XcodeSupport/\(name.replacing(" ", with: "-").supportingName)"
        )
    }
}

extension String {
    var supportingName: String {
        "XcodeTarget_\(self)"
    }

    var asDependency: Target.Dependency {
        .target(name: self.supportingName)
    }
}
