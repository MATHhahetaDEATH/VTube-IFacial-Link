// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MacApp",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "VTubeLinkUI", targets: ["VTubeLinkUI"]),
        .executable(name: "VTubeLinkService", targets: ["VTubeLinkService"])
    ],
    targets: [
        .target(
            name: "VTubeLinkShared",
            dependencies: [],
            path: "Sources/VTubeLinkShared"
        ),
        .executableTarget(
            name: "VTubeLinkUI",
            dependencies: ["VTubeLinkShared"],
            path: "Sources/VTubeLinkUI"
        ),
        .executableTarget(
            name: "VTubeLinkService",
            dependencies: ["VTubeLinkShared"],
            path: "Sources/VTubeLinkService"
        )
    ]
)
