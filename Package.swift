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
                "Services/AccessibilityService.swift",
                "Services/HotKeyService.swift",
                "Services/LaunchAtLoginService.swift",
                "SettingsView.swift"
            ],
            sources: ["Converter", "Models", "Services/ClipboardService.swift"]
        ),
        .testTarget(
            name: "KeyboardFixerTests",
            dependencies: ["KeyboardFixer"],
            path: "KeyboardFixerTests"
        )
    ]
)
