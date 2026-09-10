import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Toggle(
                "Launch at Login",
                isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                )
            )

            Toggle("Copy result automatically after Paste & Convert", isOn: $model.copyAutomatically)
            Toggle("Enable global shortcut (⌘⇧V)", isOn: $model.globalShortcutEnabled)

            Picker("Default conversion mode", selection: $model.conversionMode) {
                ForEach(ConversionMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            if let settingsError = model.settingsError {
                Text(settingsError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 470, height: 250)
    }
}
