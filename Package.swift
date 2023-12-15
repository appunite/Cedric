// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cedric",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "Cedric",
            targets: ["Cedric"]),
    ],
    targets: [
        .target(
            name: "Cedric"
        ),
        .testTarget(
            name: "CedricTests",
            dependencies: ["Cedric"]
        ),
    ]
)
