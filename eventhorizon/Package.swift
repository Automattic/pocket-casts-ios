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
            url: "https://wzieba-mobile-libs.s3.eu-central-1.amazonaws.com/ios/EventHorizon/20251009175120/EventHorizon-20251009175120.xcframework.zip",
            checksum: "9cbbac3e2d886f4b662ba4b1df9cdf9a99adc8c6aa48f2b619948f5eae9839a6"
        )
    ]
)
