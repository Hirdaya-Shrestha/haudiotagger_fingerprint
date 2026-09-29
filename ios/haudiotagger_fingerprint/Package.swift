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
            url: "https://github.com/Hirdaya-Shrestha/haudiotagger_fingerprint/releases/download/v0.2.0/ios.zip",
            checksum: "c93d6146571a6dcdf443450e3ba18b542797bcdcf5814e18ea3a275968b12d73"
        ),
        .target(
            name: "haudiotagger_fingerprint",
            dependencies: ["haudiotagger_fingerprintFFI"],
            path: "Sources/haudiotagger_fingerprint"
        )
    ]
)
