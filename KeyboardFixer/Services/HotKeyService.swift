import Carbon
import Foundation

private let keyboardFixerHotKeySignature: OSType = 0x4B465852 // KFXR

private final class HotKeyCenter {
    static let shared = HotKeyCenter()

    private var actions: [UInt32: () -> Void] = [:]
    private var eventHandlerReference: EventHandlerRef?
    private(set) var isInstalled = false

    private init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return OSStatus(eventNotHandledErr)
                }

                var hotKeyID = EventHotKeyID()
                let parameterStatus = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard parameterStatus == noErr,
                      hotKeyID.signature == keyboardFixerHotKeySignature else {
                    return OSStatus(eventNotHandledErr)
                }

                let center = Unmanaged<HotKeyCenter>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                return center.performAction(for: hotKeyID.id)
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerReference
        )

        isInstalled = status == noErr
    }

    deinit {
        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
        }
    }

    func setAction(_ action: @escaping () -> Void, for identifier: UInt32) {
        actions[identifier] = action
    }

    func removeAction(for identifier: UInt32) {
        actions.removeValue(forKey: identifier)
    }

    private func performAction(for identifier: UInt32) -> OSStatus {
        guard let action = actions[identifier] else {
            return OSStatus(eventNotHandledErr)
        }

        DispatchQueue.main.async(execute: action)
        return noErr
    }
}

final class HotKeyService {
    enum Shortcut {
        case clipboardConversion
        case selectedTextReplacement

        fileprivate var identifier: UInt32 {
            switch self {
            case .clipboardConversion: 1
            case .selectedTextReplacement: 2
            }
        }

        fileprivate var keyCode: UInt32 {
            switch self {
            case .clipboardConversion: UInt32(kVK_ANSI_V)
            case .selectedTextReplacement: UInt32(kVK_ANSI_X)
            }
        }
    }

    private let shortcut: Shortcut
    private let center = HotKeyCenter.shared
    private var hotKeyReference: EventHotKeyRef?
    private var action: (() -> Void)?

    init(shortcut: Shortcut) {
        self.shortcut = shortcut
    }

    deinit {
        unregister()
    }

    @discardableResult
    func configure(enabled: Bool, action: @escaping () -> Void) -> Bool {
        self.action = action

        guard enabled else {
            return unregister()
        }

        guard register() else { return false }
        center.setAction({ [weak self] in self?.action?() }, for: shortcut.identifier)
        return true
    }

    private func register() -> Bool {
        guard center.isInstalled else { return false }
        guard hotKeyReference == nil else { return true }

        let hotKeyID = EventHotKeyID(
            signature: keyboardFixerHotKeySignature,
            id: shortcut.identifier
        )
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )
        return status == noErr
    }

    @discardableResult
    private func unregister() -> Bool {
        center.removeAction(for: shortcut.identifier)
        guard let hotKeyReference else { return true }

        let status = UnregisterEventHotKey(hotKeyReference)
        self.hotKeyReference = nil
        return status == noErr
    }
}
