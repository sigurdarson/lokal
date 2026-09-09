// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LokalCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "LokalCore", targets: ["LokalCore"])
    ],
    targets: [
        .target(
            name: "LokalCore",
            resources: [.copy("Services/services.json")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "LokalCoreTests",
            dependencies: ["LokalCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
