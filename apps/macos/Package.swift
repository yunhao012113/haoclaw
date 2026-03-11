// swift-tools-version: 6.1
// Package manifest for the Haoclaw macOS companion (menu bar app + IPC library).

import PackageDescription

let package = Package(
    name: "Haoclaw",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "HaoclawIPC", targets: ["HaoclawIPC"]),
        .library(name: "HaoclawDiscovery", targets: ["HaoclawDiscovery"]),
        .executable(name: "Haoclaw", targets: ["Haoclaw"]),
        .executable(name: "haoclaw-mac", targets: ["HaoclawMacCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess", exact: "1.2.2"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.8.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.1"),
        .package(url: "https://github.com/steipete/Peekaboo.git", branch: "main"),
        .package(path: "../shared/HaoclawKit"),
        .package(path: "../../Swabble"),
    ],
    targets: [
        .target(
            name: "HaoclawIPC",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "HaoclawDiscovery",
            dependencies: [
                .product(name: "HaoclawKit", package: "HaoclawKit"),
            ],
            path: "Sources/HaoclawDiscovery",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "Haoclaw",
            dependencies: [
                "HaoclawIPC",
                "HaoclawDiscovery",
                .product(name: "HaoclawKit", package: "HaoclawKit"),
                .product(name: "HaoclawChatUI", package: "HaoclawKit"),
                .product(name: "HaoclawProtocol", package: "HaoclawKit"),
                .product(name: "SwabbleKit", package: "swabble"),
                .product(name: "MenuBarExtraAccess", package: "MenuBarExtraAccess"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "PeekabooBridge", package: "Peekaboo"),
                .product(name: "PeekabooAutomationKit", package: "Peekaboo"),
            ],
            exclude: [
                "Resources/Info.plist",
            ],
            resources: [
                .copy("Resources/Haoclaw.icns"),
                .copy("Resources/DeviceModels"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "HaoclawMacCLI",
            dependencies: [
                "HaoclawDiscovery",
                .product(name: "HaoclawKit", package: "HaoclawKit"),
                .product(name: "HaoclawProtocol", package: "HaoclawKit"),
            ],
            path: "Sources/HaoclawMacCLI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "HaoclawIPCTests",
            dependencies: [
                "HaoclawIPC",
                "Haoclaw",
                "HaoclawDiscovery",
                .product(name: "HaoclawProtocol", package: "HaoclawKit"),
                .product(name: "SwabbleKit", package: "swabble"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
