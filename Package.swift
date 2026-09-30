// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacTV",
    platforms: [.macOS(.v14)],
    products: [.library(name: "MacTVCore", targets: ["MacTVCore"])],
    targets: [
        .target(
            name: "MacTVCore",
            path: "Sources/MacTV",
            exclude: [
                "AppShell",
                "Home",
                "Settings",
                "SharedUI",
                "MacTVApp.swift",
                "Services/ApplicationServices.swift"
            ],
            sources: [
                "Models/AppModels.swift",
                "Models/NavigationMath.swift",
                "Services/Persistence.swift"
            ]
        ),
        .testTarget(
            name: "MacTVTests",
            dependencies: ["MacTVCore"],
            path: "Tests/MacTVTests"
        )
    ]
)
