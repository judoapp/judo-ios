// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "JudoSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "JudoSDK",
            // TODO: consider commenting `type: .dynamic` before public release. it's here to use Xcode Previews in Sample app, to work around an Xcode bug.
//            type: .dynamic,
            targets: ["JudoSDK", "JudoModel"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker", .revision("8ff37ffda243669ba7827f639f91f99b53fa4b49"))
    ],
    targets: [
        .target(
            name: "JudoSDK",
            dependencies: ["JudoModel"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "JudoModel"
        ),
        .testTarget(
            name: "JudoServiceTests",
            dependencies: ["JudoSDK", "Mocker"]
        )
    ]
)
