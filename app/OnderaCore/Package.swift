// swift-tools-version:5.10
import PackageDescription

// Pure logic for Ondera Leaf Walk: models, protocols, mocks, planners, maths.
// No UIKit / MapKit / AVFoundation here, so `swift test` runs on a Mac in seconds.
let package = Package(
    name: "OnderaCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "OnderaCore", targets: ["OnderaCore"]),
    ],
    targets: [
        .target(
            name: "OnderaCore",
            exclude: ["Shared/README.md", "Infra/README.md", "Walk/README.md", "EndScreen/README.md"]
        ),
        .testTarget(name: "OnderaCoreTests", dependencies: ["OnderaCore"]),
    ]
)
