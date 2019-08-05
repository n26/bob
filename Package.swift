// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "Bob",
    products: [
        .library(name: "Bob", targets: ["Bob"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "Bob", dependencies: ["Vapor"]),
    ]
)
