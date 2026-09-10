import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            modePicker

            VStack(alignment: .leading, spacing: 6) {
                Text("Input")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $model.inputText)
                    .font(.body.monospaced())
                    .frame(minHeight: 82)
                    .padding(5)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }

            Image(systemName: "arrow.down")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Converts to")

            VStack(alignment: .leading, spacing: 6) {
                Text("Output")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $model.outputText)
                    .font(.body.monospaced())
                    .frame(minHeight: 82)
                    .padding(5)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }

            actionButtons

            if let statusMessage = model.statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(statusMessage.contains("uncertain") ? .orange : .secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity)
            }

            Divider()
            footer
        }
        .padding(16)
        .frame(width: 360)
        .animation(.easeInOut(duration: 0.18), value: model.statusMessage)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("KeyboardFixer")
                    .font(.headline)
                Text(model.conversionMode.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.title2)
                .foregroundStyle(.tint)
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $model.conversionMode) {
            ForEach(ConversionMode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Paste & Convert", systemImage: "doc.on.clipboard") {
                    model.pasteAndConvert()
                }
                .buttonStyle(.borderedProminent)

                Button("Copy Result", systemImage: "doc.on.doc") {
                    model.copyResult()
                }
                .disabled(model.outputText.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Button("Swap Direction", systemImage: "arrow.left.arrow.right") {
                    model.swapDirection()
                }
                Button("Clear", systemImage: "xmark") {
                    model.clear()
                }
                .disabled(model.inputText.isEmpty && model.outputText.isEmpty)
            }
            .controlSize(.small)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var footer: some View {
        HStack {
            Button("Settings…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            Button("About KeyboardFixer") {
                NSApp.orderFrontStandardAboutPanel(nil)
            }
            Spacer()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
