// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "HaoclawKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "HaoclawProtocol", targets: ["HaoclawProtocol"]),
        .library(name: "HaoclawKit", targets: ["HaoclawKit"]),
        .library(name: "HaoclawChatUI", targets: ["HaoclawChatUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/ElevenLabsKit", exact: "0.1.0"),
        .package(url: "https://github.com/gonzalezreal/textual", exact: "0.3.1"),
    ],
    targets: [
        .target(
            name: "HaoclawProtocol",
            path: "Sources/HaoclawProtocol",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "HaoclawKit",
            dependencies: [
                "HaoclawProtocol",
                .product(name: "ElevenLabsKit", package: "ElevenLabsKit"),
            ],
            path: "Sources/HaoclawKit",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "HaoclawChatUI",
            dependencies: [
                "HaoclawKit",
                .product(
                    name: "Textual",
                    package: "textual",
                    condition: .when(platforms: [.macOS, .iOS])),
            ],
            path: "Sources/HaoclawChatUI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "HaoclawKitTests",
            dependencies: ["HaoclawKit", "HaoclawChatUI"],
            path: "Tests/HaoclawKitTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
