// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "APISpec",
    products: [
        .library(name: "APISpec", targets: ["APISpec"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "2.1.0")),
    ],
    targets: [
        .target(name: "APISpec", dependencies: ["Vapor"]),
    ]
)
