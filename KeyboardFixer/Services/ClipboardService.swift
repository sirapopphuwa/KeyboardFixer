import AppKit

struct ClipboardSnapshot {
    fileprivate let items: [[NSPasteboard.PasteboardType: Data]]
}

struct ClipboardService {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func readPlainText() -> String? {
        pasteboard.string(forType: .string)
    }

    var changeCount: Int {
        pasteboard.changeCount
    }

    @discardableResult
    func writePlainText(_ text: String) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }

    func snapshot() -> ClipboardSnapshot {
        let items = pasteboard.pasteboardItems?.map { item in
            item.types.reduce(into: [NSPasteboard.PasteboardType: Data]()) { result, type in
                if let data = item.data(forType: type) {
                    result[type] = data
                }
            }
        } ?? []
        return ClipboardSnapshot(items: items)
    }

    @discardableResult
    func restore(_ snapshot: ClipboardSnapshot, ifChangeCountMatches expectedChangeCount: Int) -> Bool {
        guard pasteboard.changeCount == expectedChangeCount else { return false }

        pasteboard.clearContents()
        guard !snapshot.items.isEmpty else { return true }

        let items = snapshot.items.map { storedItem in
            let item = NSPasteboardItem()
            for (type, data) in storedItem {
                item.setData(data, forType: type)
            }
            return item
        }
        return pasteboard.writeObjects(items)
    }
}
