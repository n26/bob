import PackageDescription

let package = Package(
    name: "Bob",
    targets: [
        Target(name: "BobMain", dependencies: ["Bob"]),
    ],
    dependencies: [
    .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 4),
    ]
)
