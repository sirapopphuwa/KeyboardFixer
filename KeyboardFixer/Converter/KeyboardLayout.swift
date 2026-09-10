import Foundation

protocol KeyboardLayout: Sendable {
    var name: String { get }
    var keyMap: [KeyboardKey: Unicode.Scalar] { get }
}

extension KeyboardLayout {
    /// All source keys are retained. If a layout emits the same scalar from
    /// multiple keys, conversion uses the first key in physical keyboard order.
    var reverseMap: [Unicode.Scalar: [KeyboardKey]] {
        var result: [Unicode.Scalar: [KeyboardKey]] = [:]

        for physicalKey in PhysicalKey.allCases {
            for shifted in [false, true] {
                let keyboardKey = KeyboardKey(key: physicalKey, shifted: shifted)
                guard let scalar = keyMap[keyboardKey] else { continue }
                result[scalar, default: []].append(keyboardKey)
            }
        }

        return result
    }
}

enum KeyboardLayoutBuilder {
    static func makeMap(
        unshifted: String,
        shifted: String
    ) -> [KeyboardKey: Unicode.Scalar] {
        let unshiftedScalars = Array(unshifted.unicodeScalars)
        let shiftedScalars = Array(shifted.unicodeScalars)
        var result: [KeyboardKey: Unicode.Scalar] = [:]

        for (index, physicalKey) in PhysicalKey.allCases.enumerated() {
            if unshiftedScalars.indices.contains(index) {
                result[KeyboardKey(key: physicalKey, shifted: false)] = unshiftedScalars[index]
            }
            if shiftedScalars.indices.contains(index) {
                result[KeyboardKey(key: physicalKey, shifted: true)] = shiftedScalars[index]
            }
        }

        return result
    }
}
