import XCTest
@testable import KeyboardFixer

final class AutoDetectorTests: XCTestCase {
    private let detector = AutoDetector()

    func testDetectsEnglishWrongLayoutText() {
        XCTAssertEqual(detector.detect("z,vpkdlihk'cvr"), .englishToThai)
    }

    func testDetectsThaiWrongLayoutText() {
        XCTAssertEqual(detector.detect("ผมอยากสร้างแอพ"), .thaiToEnglish)
    }

    func testPunctuationAndNumbersAreUncertain() {
        XCTAssertEqual(detector.detect("1234 !!! --"), .uncertain)
    }

    func testMixedScriptsAreUncertain() {
        XCTAssertEqual(detector.detect("hello สวัสดี"), .uncertain)
    }

    func testShortInputIsUncertain() {
        XCTAssertEqual(detector.detect("a"), .uncertain)
        XCTAssertEqual(detector.detect("ก"), .uncertain)
    }

    func testURLLikeTextRemainsUncertainWhenMixed() {
        XCTAssertEqual(detector.detect("https://example.com/สวัสดี"), .uncertain)
    }

    func testURLAndEmailRemainUncertainInAutoMode() {
        XCTAssertEqual(detector.detect("https://example.com"), .uncertain)
        XCTAssertEqual(detector.detect("person@example.com"), .uncertain)
    }

    func testCodeLikeTextRemainsUncertainInAutoMode() {
        XCTAssertEqual(detector.detect("let value = hello"), .uncertain)
    }
}
