import XCTest
@testable import KeyboardFixer

final class KeyboardConverterTests: XCTestCase {
    private let converter = KeyboardConverter()
    private let english = EnglishUSLayout()
    private let thai = ThaiKedmaneeLayout()

    func testEnglishWrongLayoutPhrase() {
        XCTAssertEqual(
            converter.convert("z,vpkdlihk'cvr", direction: .englishToThai),
            "ผมอยากสร้างแอพ"
        )
    }

    func testIndividualEnglishKeys() {
        XCTAssertEqual(converter.convert("a", direction: .englishToThai), "ฟ")
        XCTAssertEqual(converter.convert("A", direction: .englishToThai), "ฤ")
        XCTAssertEqual(converter.convert("z", direction: .englishToThai), "ผ")
        XCTAssertEqual(converter.convert("Z", direction: .englishToThai), "(")
        XCTAssertEqual(converter.convert("1", direction: .englishToThai), "ๅ")
        XCTAssertEqual(converter.convert("!", direction: .englishToThai), "+")
    }

    func testThaiReversePhrase() {
        XCTAssertEqual(
            converter.convert("ผมอยากสร้างแอพ", direction: .thaiToEnglish),
            "z,vpkdlihk'cvr"
        )
    }

    func testShiftedReverseConversion() {
        XCTAssertEqual(converter.convert("ฤ(", direction: .thaiToEnglish), "AZ")
        XCTAssertEqual(converter.convert("+๑๒๓", direction: .thaiToEnglish), "!@#$")
    }

    func testEveryEnglishKeyRoundTrips() throws {
        XCTAssertEqual(english.keyMap.count, PhysicalKey.allCases.count * 2)
        XCTAssertEqual(thai.keyMap.count, PhysicalKey.allCases.count * 2)

        for physicalKey in PhysicalKey.allCases {
            for shifted in [false, true] {
                let key = KeyboardKey(key: physicalKey, shifted: shifted)
                let scalar = try XCTUnwrap(english.keyMap[key])
                let original = String(scalar)
                let thaiText = converter.convert(original, direction: .englishToThai)
                let roundTrip = converter.convert(thaiText, direction: .thaiToEnglish)
                XCTAssertEqual(roundTrip, original, "Failed key: \(physicalKey), shifted: \(shifted)")
            }
        }
    }

    func testEveryUnambiguousThaiKeyRoundTrips() throws {
        let reverseMap = thai.reverseMap

        for physicalKey in PhysicalKey.allCases {
            for shifted in [false, true] {
                let key = KeyboardKey(key: physicalKey, shifted: shifted)
                let scalar = try XCTUnwrap(thai.keyMap[key])
                guard reverseMap[scalar]?.count == 1 else { continue }
                let original = String(scalar)
                let englishText = converter.convert(original, direction: .thaiToEnglish)
                let roundTrip = converter.convert(englishText, direction: .englishToThai)
                XCTAssertEqual(roundTrip, original, "Failed key: \(physicalKey), shifted: \(shifted)")
            }
        }
    }

    func testWhitespaceAndUnknownScalarsArePreserved() {
        XCTAssertEqual(
            converter.convert("hello\nworld", direction: .englishToThai),
            "้ำสสน\nไนพสก"
        )
        XCTAssertEqual(
            converter.convert(" \n\t🧑🏽‍💻é", direction: .englishToThai),
            " \n\t🧑🏽‍💻é"
        )
    }

    func testThaiCombiningMarksAreConvertedInScalarOrder() {
        XCTAssertEqual(converter.convert("้่๊๋์ํ็ิีึืฺุู", direction: .thaiToEnglish), "hjUJNYHbu7n6^B")
    }

    func testReverseMapRetainsDuplicateCandidatesInStableOrder() {
        let first = KeyboardKey(key: .grave, shifted: false)
        let second = KeyboardKey(key: .one, shifted: false)
        let layout = DuplicateLayout(keyMap: [first: "x", second: "x"])

        XCTAssertEqual(layout.reverseMap["x"], [first, second])
    }
}

private struct DuplicateLayout: KeyboardLayout {
    let name = "Duplicate test layout"
    let keyMap: [KeyboardKey: Unicode.Scalar]
}
