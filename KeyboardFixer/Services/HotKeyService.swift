import Carbon
import Foundation

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

    private static let signature: OSType = 0x4B465852 // KFXR

    private let shortcut: Shortcut
    private var hotKeyReference: EventHotKeyRef?
    private var eventHandlerReference: EventHandlerRef?
    private var action: (() -> Void)?

    init(shortcut: Shortcut) {
        self.shortcut = shortcut
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                let service = Unmanaged<HotKeyService>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                guard status == noErr,
                      hotKeyID.signature == HotKeyService.signature,
                      hotKeyID.id == service.shortcut.identifier else {
                    return noErr
                }

                DispatchQueue.main.async {
                    service.action?()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerReference
        )
    }

    deinit {
        unregister()
        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
        }
    }

    func configure(enabled: Bool, action: @escaping () -> Void) {
        self.action = action
        enabled ? register() : unregister()
    }

    private func register() {
        guard hotKeyReference == nil else { return }
        let hotKeyID = EventHotKeyID(
            signature: Self.signature,
            id: shortcut.identifier
        )
        RegisterEventHotKey(
            shortcut.keyCode,
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )
    }

    private func unregister() {
        guard let hotKeyReference else { return }
        UnregisterEventHotKey(hotKeyReference)
        self.hotKeyReference = nil
    }
}
