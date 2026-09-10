import ApplicationServices
import Carbon
import Foundation

struct AccessibilityService {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    func requestPermission() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }

    func copySelection() {
        postCommandKey(CGKeyCode(kVK_ANSI_C))
    }

    func pasteReplacingSelection() {
        postCommandKey(CGKeyCode(kVK_ANSI_V))
    }

    private func postCommandKey(_ keyCode: CGKeyCode) {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
