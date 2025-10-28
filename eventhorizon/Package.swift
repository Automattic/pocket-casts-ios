// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "EventHorizon",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "EventHorizonSDK",
            targets: ["EventHorizonSDK"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "EventHorizonSDK",
            url: "https://a8c-libs.s3.amazonaws.com/ios/EventHorizon/pocketcasts-2025-10-28-15-27-35/EventHorizon-pocketcasts-2025-10-28-15-27-35.xcframework.zip",
            checksum: "d7ed9ae9a85430c2e1840c4e6b116c5e965a9dff38488ea57f2a73dd56dbdc19"
        )
    ]
)
