import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    private enum DefaultsKey {
        static let conversionMode = "conversionMode"
        static let copyAutomatically = "copyAutomatically"
        static let globalShortcutEnabled = "globalShortcutEnabled"
    }

    @Published var inputText = "" {
        didSet { updateOutputForCurrentInput() }
    }
    @Published var outputText = ""
    @Published var statusMessage: String?
    @Published var confirmationIconVisible = false

    @Published var conversionMode: ConversionMode {
        didSet {
            defaults.set(conversionMode.rawValue, forKey: DefaultsKey.conversionMode)
            updateOutputForCurrentInput()
        }
    }
    @Published var copyAutomatically: Bool {
        didSet { defaults.set(copyAutomatically, forKey: DefaultsKey.copyAutomatically) }
    }
    @Published var globalShortcutEnabled: Bool {
        didSet {
            defaults.set(globalShortcutEnabled, forKey: DefaultsKey.globalShortcutEnabled)
            configureHotKey()
        }
    }
    @Published private(set) var launchAtLogin: Bool
    @Published var settingsError: String?

    private let converter = KeyboardConverter()
    private let detector = AutoDetector()
    private let clipboard = ClipboardService()
    private let hotKeyService = HotKeyService()
    private let launchAtLoginService = LaunchAtLoginService()
    private let defaults: UserDefaults
    private var statusTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            DefaultsKey.copyAutomatically: true,
            DefaultsKey.globalShortcutEnabled: true,
            DefaultsKey.conversionMode: ConversionMode.automatic.rawValue
        ])

        conversionMode = ConversionMode(
            rawValue: defaults.string(forKey: DefaultsKey.conversionMode) ?? ""
        ) ?? .automatic
        copyAutomatically = defaults.bool(forKey: DefaultsKey.copyAutomatically)
        globalShortcutEnabled = defaults.bool(forKey: DefaultsKey.globalShortcutEnabled)
        launchAtLogin = LaunchAtLoginService().isEnabled
        configureHotKey()
    }

    func pasteAndConvert() {
        guard let text = clipboard.readPlainText() else {
            showStatus("Clipboard has no plain text", confirmation: false)
            return
        }
        inputText = text
        updateOutputForCurrentInput()

        let isUncertain = conversionMode == .automatic && detector.detect(text) == .uncertain
        if copyAutomatically, !isUncertain {
            copyResult()
        }
    }

    func copyResult() {
        guard !outputText.isEmpty else {
            showStatus("Nothing to copy", confirmation: false)
            return
        }
        if clipboard.writePlainText(outputText) {
            showStatus("Copied ✓", confirmation: true)
        } else {
            showStatus("Could not write to clipboard", confirmation: false)
        }
    }

    func swapDirection() {
        switch conversionMode {
        case .automatic, .thaiToEnglish:
            conversionMode = .englishToThai
        case .englishToThai:
            conversionMode = .thaiToEnglish
        }
    }

    func clear() {
        inputText = ""
        outputText = ""
        statusMessage = nil
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginService.setEnabled(enabled)
            launchAtLogin = launchAtLoginService.isEnabled
            settingsError = nil
        } catch {
            launchAtLogin = launchAtLoginService.isEnabled
            settingsError = error.localizedDescription
        }
    }

    private func updateOutputForCurrentInput() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }

        if let direction = conversionMode.direction {
            outputText = converter.convert(inputText, direction: direction)
            statusMessage = nil
            return
        }

        let detection = detector.detect(inputText)
        guard let direction = detection.direction else {
            outputText = inputText
            statusMessage = "Direction uncertain — choose a mode"
            return
        }
        outputText = converter.convert(inputText, direction: direction)
        statusMessage = nil
    }

    private func configureHotKey() {
        hotKeyService.configure(enabled: globalShortcutEnabled) { [weak self] in
            self?.performHotKeyConversion()
        }
    }

    private func performHotKeyConversion() {
        guard let text = clipboard.readPlainText() else {
            showStatus("Clipboard has no plain text", confirmation: false)
            return
        }

        inputText = text
        updateOutputForCurrentInput()

        if conversionMode == .automatic, detector.detect(text) == .uncertain {
            showStatus("Direction uncertain — clipboard unchanged", confirmation: false)
            return
        }

        if clipboard.writePlainText(outputText) {
            showStatus("Clipboard converted ✓", confirmation: true)
        } else {
            showStatus("Could not write to clipboard", confirmation: false)
        }
    }

    private func showStatus(_ message: String, confirmation: Bool) {
        statusTask?.cancel()
        statusMessage = message
        confirmationIconVisible = confirmation

        statusTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.statusMessage = nil
            self?.confirmationIconVisible = false
        }
    }
}
