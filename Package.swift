// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "calbuddy",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "CalBuddyLib",
            path: "Sources/CalBuddyLib"
        ),
        .executableTarget(
            name: "calbuddy",
            dependencies: ["CalBuddyLib"],
            path: "Sources/CalBuddy"
        ),
        .testTarget(
            name: "CalBuddyTests",
            dependencies: ["CalBuddyLib"]
        )
    ]
)
