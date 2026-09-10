import Foundation

struct AutoDetector: Sendable {
    private let minimumStrongCharacters = 2
    private let dominanceThreshold = 0.75

    func detect(_ text: String) -> DetectionResult {
        guard !looksLikeProtectedContent(text) else {
            return .uncertain
        }

        var latinLetters = 0
        var thaiScalars = 0

        for scalar in text.unicodeScalars {
            if isLatinLetter(scalar) {
                latinLetters += 1
            } else if isThaiMeaningfulScalar(scalar) {
                thaiScalars += 1
            }
        }

        let meaningfulCount = latinLetters + thaiScalars
        guard meaningfulCount >= minimumStrongCharacters else {
            return .uncertain
        }

        // Mixed-script prose is intentionally left alone in Auto mode.
        if latinLetters > 0, thaiScalars > 0 {
            return .uncertain
        }

        let latinRatio = Double(latinLetters) / Double(meaningfulCount)
        let thaiRatio = Double(thaiScalars) / Double(meaningfulCount)

        if latinLetters >= minimumStrongCharacters, latinRatio >= dominanceThreshold {
            return .englishToThai
        }
        if thaiScalars >= minimumStrongCharacters, thaiRatio >= dominanceThreshold {
            return .thaiToEnglish
        }
        return .uncertain
    }

    private func isLatinLetter(_ scalar: Unicode.Scalar) -> Bool {
        (0x41...0x5A).contains(scalar.value) || (0x61...0x7A).contains(scalar.value)
    }

    private func isThaiMeaningfulScalar(_ scalar: Unicode.Scalar) -> Bool {
        // Includes Thai base letters, vowels, tone marks, and other combining marks.
        (0x0E00...0x0E7F).contains(scalar.value)
    }

    private func looksLikeProtectedContent(_ text: String) -> Bool {
        let lowercaseText = text.lowercased()
        if lowercaseText.contains("://") || lowercaseText.hasPrefix("www.") {
            return true
        }

        // An at-sign surrounded by non-whitespace is enough to protect a likely email.
        if let atIndex = text.firstIndex(of: "@"),
           atIndex != text.startIndex,
           text.index(after: atIndex) != text.endIndex {
            let before = text[text.index(before: atIndex)]
            let after = text[text.index(after: atIndex)]
            if !before.isWhitespace, !after.isWhitespace {
                return true
            }
        }

        let codeSignals = ["</", "=>", "{", "}", "func ", "let ", "var "]
        return codeSignals.contains { text.contains($0) }
    }
}
