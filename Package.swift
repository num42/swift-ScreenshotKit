// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScreenshotKit",
    products: [
        .library(
            name: "ScreenshotKit",
            targets: ["ScreenshotKit"]
        ),
    ],
    targets: [
        .target(
            name: "ScreenshotKit"
        )
    ]
)
