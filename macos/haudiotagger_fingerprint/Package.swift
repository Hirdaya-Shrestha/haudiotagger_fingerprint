// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "haudiotagger_fingerprint",
    platforms: [.macOS(.v10_14)],
    products: [
        .library(name: "haudiotagger-fingerprint", targets: ["haudiotagger_fingerprint"])
    ],
    targets: [
        .binaryTarget(
            name: "haudiotagger_fingerprintFFI",
            url: "https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint/releases/download/v0.1.2/macos.zip",
            checksum: "a2602eae061db3d113e728ac06b334d3c92af78cf4156765dd103a3b946a18ff"
        ),
        .target(
            name: "haudiotagger_fingerprint",
            dependencies: ["haudiotagger_fingerprintFFI"],
            path: "Sources/haudiotagger_fingerprint"
        )
    ]
)
