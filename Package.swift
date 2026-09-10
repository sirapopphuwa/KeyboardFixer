// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyboardFixer",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "KeyboardFixer", targets: ["KeyboardFixer"])
    ],
    targets: [
        .target(
            name: "KeyboardFixer",
            path: "KeyboardFixer",
            exclude: [
                "AppModel.swift",
                "Info.plist",
                "KeyboardFixerApp.swift",
                "MenuBarView.swift",
                "Resources",
                "Services",
                "SettingsView.swift"
            ],
            sources: ["Converter", "Models"]
        ),
        .testTarget(
            name: "KeyboardFixerTests",
            dependencies: ["KeyboardFixer"],
            path: "KeyboardFixerTests"
        )
    ]
)
