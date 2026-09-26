// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "haudiotagger_fingerprint",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "haudiotagger_fingerprint", targets: ["haudiotagger_fingerprint"])
    ],
    targets: [
        .binaryTarget(
            name: "haudiotagger_fingerprintFFI",
            url: "https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint/releases/download/v2.1.0/ios.zip",
            checksum: "1dea167c5e3161eeb3b52949d2935721c1f0ce6739d81ef3f9ab9a1d3cb11564"
        ),
        .target(
            name: "haudiotagger_fingerprint",
            dependencies: ["haudiotagger_fingerprintFFI"],
            path: "Sources/haudiotagger_fingerprint"
        )
    ]
)
