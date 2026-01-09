// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "JCProxy",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "JCProxy",
            targets: ["JCProxy"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "JCProxy",
            path: "Sources/JCProxyBinary/JCProxy.xcframework"
        ),
    ]
)
