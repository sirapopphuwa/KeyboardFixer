import AppKit
import XCTest
@testable import KeyboardFixer

final class ClipboardServiceTests: XCTestCase {
    func testSnapshotRestoresClipboardWhenUnchanged() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("KeyboardFixerTests.\(UUID().uuidString)"))
        let service = ClipboardService(pasteboard: pasteboard)

        XCTAssertTrue(service.writePlainText("original"))
        let snapshot = service.snapshot()
        XCTAssertTrue(service.writePlainText("temporary"))
        let expectedChangeCount = service.changeCount

        XCTAssertTrue(service.restore(snapshot, ifChangeCountMatches: expectedChangeCount))
        XCTAssertEqual(service.readPlainText(), "original")
    }

    func testSnapshotDoesNotOverwriteNewerClipboardContent() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("KeyboardFixerTests.\(UUID().uuidString)"))
        let service = ClipboardService(pasteboard: pasteboard)

        XCTAssertTrue(service.writePlainText("original"))
        let snapshot = service.snapshot()
        XCTAssertTrue(service.writePlainText("temporary"))
        let staleChangeCount = service.changeCount
        XCTAssertTrue(service.writePlainText("newer content"))

        XCTAssertFalse(service.restore(snapshot, ifChangeCountMatches: staleChangeCount))
        XCTAssertEqual(service.readPlainText(), "newer content")
    }
}
