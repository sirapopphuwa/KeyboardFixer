import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("General") {
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { model.launchAtLogin },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )

                Toggle("Copy result automatically after Paste & Convert", isOn: $model.copyAutomatically)

                Picker("Default conversion mode", selection: $model.conversionMode) {
                    ForEach(ConversionMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }

            Section("Keyboard Shortcuts") {
                Toggle("Convert clipboard with ⌘⇧V", isOn: $model.globalShortcutEnabled)
                Toggle("Replace selected text with ⌘⇧X", isOn: $model.selectedTextShortcutEnabled)

                HStack {
                    Label(
                        model.accessibilityGranted ? "Accessibility allowed" : "Accessibility required for ⌘⇧X",
                        systemImage: model.accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(model.accessibilityGranted ? .green : .orange)

                    Spacer()

                    if !model.accessibilityGranted {
                        Button("Allow…") {
                            model.requestAccessibilityPermission()
                        }
                    }
                }
                .font(.caption)
            }

            if let settingsError = model.settingsError {
                Text(settingsError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 500, height: 360)
        .onAppear {
            model.refreshAccessibilityStatus()
        }
    }
}
