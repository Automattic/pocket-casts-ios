// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Fingerprint",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "Fingerprint", targets: ["Fingerprint"]),
    ],
    targets: [
        .target(
            name: "Fingerprint",
            dependencies: ["FingerprintFFI"],
            path: "Sources/Fingerprint"
        ),
        .binaryTarget(
            name: "FingerprintFFI",
            path: "Fingerprint.xcframework"
        ),
    ]
)
