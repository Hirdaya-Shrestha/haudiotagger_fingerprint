// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "haudiotagger_fingerprint",
    platforms: [.macOS(.v10_14)],
    products: [
        .library(name: "haudiotagger_fingerprint", targets: ["haudiotagger_fingerprint"])
    ],
    targets: [
        .binaryTarget(
            name: "haudiotagger_fingerprintFFI",
            url: "https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint/releases/download/v2.1.0/macos.zip",
            checksum: "7087dd670150a139bab0d4647efb73cc3c81acfe9a2bd762cfe51bdbbd0d0b62"
        ),
        .target(
            name: "haudiotagger_fingerprint",
            dependencies: ["haudiotagger_fingerprintFFI"],
            path: "Sources/haudiotagger_fingerprint"
        )
    ]
)
