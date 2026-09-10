import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    private enum DefaultsKey {
        static let conversionMode = "conversionMode"
        static let copyAutomatically = "copyAutomatically"
        static let globalShortcutEnabled = "globalShortcutEnabled"
        static let selectedTextShortcutEnabled = "selectedTextShortcutEnabled"
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
            configureHotKeys()
        }
    }
    @Published var selectedTextShortcutEnabled: Bool {
        didSet {
            defaults.set(selectedTextShortcutEnabled, forKey: DefaultsKey.selectedTextShortcutEnabled)
            configureHotKeys()
        }
    }
    @Published private(set) var launchAtLogin: Bool
    @Published private(set) var accessibilityGranted: Bool
    @Published var settingsError: String?

    private let converter = KeyboardConverter()
    private let detector = AutoDetector()
    private let clipboard = ClipboardService()
    private let clipboardHotKeyService = HotKeyService(shortcut: .clipboardConversion)
    private let selectedTextHotKeyService = HotKeyService(shortcut: .selectedTextReplacement)
    private let accessibilityService = AccessibilityService()
    private let launchAtLoginService = LaunchAtLoginService()
    private let defaults: UserDefaults
    private var statusTask: Task<Void, Never>?
    private var selectedTextTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            DefaultsKey.copyAutomatically: true,
            DefaultsKey.globalShortcutEnabled: true,
            DefaultsKey.selectedTextShortcutEnabled: true,
            DefaultsKey.conversionMode: ConversionMode.automatic.rawValue
        ])

        conversionMode = ConversionMode(
            rawValue: defaults.string(forKey: DefaultsKey.conversionMode) ?? ""
        ) ?? .automatic
        copyAutomatically = defaults.bool(forKey: DefaultsKey.copyAutomatically)
        globalShortcutEnabled = defaults.bool(forKey: DefaultsKey.globalShortcutEnabled)
        selectedTextShortcutEnabled = defaults.bool(forKey: DefaultsKey.selectedTextShortcutEnabled)
        launchAtLogin = LaunchAtLoginService().isEnabled
        accessibilityGranted = AccessibilityService().isTrusted
        configureHotKeys()
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

    func requestAccessibilityPermission() {
        accessibilityGranted = accessibilityService.requestPermission()
        if accessibilityGranted {
            showStatus("Accessibility enabled ✓", confirmation: true)
        } else {
            showStatus("Allow KeyboardFixer in Accessibility, then try ⌘⇧X again", confirmation: false)
        }
    }

    func refreshAccessibilityStatus() {
        accessibilityGranted = accessibilityService.isTrusted
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

    private func configureHotKeys() {
        clipboardHotKeyService.configure(enabled: globalShortcutEnabled) { [weak self] in
            self?.performHotKeyConversion()
        }
        selectedTextHotKeyService.configure(enabled: selectedTextShortcutEnabled) { [weak self] in
            self?.performSelectedTextReplacement()
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

    private func performSelectedTextReplacement() {
        accessibilityGranted = accessibilityService.isTrusted
        guard accessibilityGranted else {
            requestAccessibilityPermission()
            return
        }

        selectedTextTask?.cancel()
        selectedTextTask = Task { [weak self] in
            await self?.replaceSelectedText()
        }
    }

    private func replaceSelectedText() async {
        let originalClipboard = clipboard.snapshot()
        let marker = "KeyboardFixer.Selection.\(UUID().uuidString)"

        guard clipboard.writePlainText(marker) else {
            showStatus("Could not prepare clipboard", confirmation: false)
            return
        }

        let markerChangeCount = clipboard.changeCount
        try? await Task.sleep(nanoseconds: 100_000_000)
        guard !Task.isCancelled else {
            clipboard.restore(originalClipboard, ifChangeCountMatches: markerChangeCount)
            return
        }

        accessibilityService.copySelection()
        var copiedChangeCount = markerChangeCount
        for _ in 0..<10 {
            try? await Task.sleep(nanoseconds: 50_000_000)
            copiedChangeCount = clipboard.changeCount
            if copiedChangeCount != markerChangeCount || Task.isCancelled {
                break
            }
        }

        guard !Task.isCancelled else {
            clipboard.restore(originalClipboard, ifChangeCountMatches: copiedChangeCount)
            return
        }

        guard copiedChangeCount != markerChangeCount,
              let selectedText = clipboard.readPlainText(),
              !selectedText.isEmpty,
              selectedText != marker else {
            clipboard.restore(originalClipboard, ifChangeCountMatches: copiedChangeCount)
            showStatus("Select editable text, then press ⌘⇧X", confirmation: false)
            return
        }

        let convertedText: String
        if let direction = conversionMode.direction {
            convertedText = converter.convert(selectedText, direction: direction)
        } else {
            guard let direction = detector.detect(selectedText).direction else {
                clipboard.restore(originalClipboard, ifChangeCountMatches: copiedChangeCount)
                showStatus("Direction uncertain — selection unchanged", confirmation: false)
                return
            }
            convertedText = converter.convert(selectedText, direction: direction)
        }

        guard convertedText != selectedText else {
            clipboard.restore(originalClipboard, ifChangeCountMatches: copiedChangeCount)
            showStatus("No convertible text found", confirmation: false)
            return
        }

        inputText = selectedText
        outputText = convertedText

        guard clipboard.writePlainText(convertedText) else {
            clipboard.restore(originalClipboard, ifChangeCountMatches: copiedChangeCount)
            showStatus("Could not write converted text", confirmation: false)
            return
        }

        let convertedChangeCount = clipboard.changeCount
        accessibilityService.pasteReplacingSelection()
        showStatus("Selection fixed ✓", confirmation: true)

        try? await Task.sleep(nanoseconds: 500_000_000)
        clipboard.restore(originalClipboard, ifChangeCountMatches: convertedChangeCount)
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
