import SwiftUI

@main
struct KeyboardFixerApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Image(systemName: model.confirmationIconVisible ? "checkmark.circle.fill" : "keyboard.badge.ellipsis")
                .accessibilityLabel("KeyboardFixer")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}
