// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "haudiotagger_fingerprint",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "haudiotagger-fingerprint", targets: ["haudiotagger_fingerprint"])
    ],
    targets: [
        .binaryTarget(
            name: "haudiotagger_fingerprintFFI",
            url: "https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint/releases/download/v0.1.4/ios.zip",
            checksum: "d0f1cd225d45c4a7f110b5548f80c2e4f1d2f53f12866658959e6ab78857d960"
        ),
        .target(
            name: "haudiotagger_fingerprint",
            dependencies: ["haudiotagger_fingerprintFFI"],
            path: "Sources/haudiotagger_fingerprint"
        )
    ]
)
