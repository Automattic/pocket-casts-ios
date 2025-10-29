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
            url: "https://a8c-libs.s3.amazonaws.com/ios/EventHorizon/pocketcasts-2025-10-29-13-17-22/EventHorizon-pocketcasts-2025-10-29-13-17-22.xcframework.zip",
            checksum: "c38257013511e179d8534a2a30337f5abdf16b3901fc15a6aca5498bdc90d6e2"
        )
    ]
)
