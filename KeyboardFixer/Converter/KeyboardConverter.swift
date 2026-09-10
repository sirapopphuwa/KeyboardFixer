import Foundation

struct KeyboardConverter: Sendable {
    let englishLayout: any KeyboardLayout
    let thaiLayout: any KeyboardLayout

    init(
        englishLayout: any KeyboardLayout = EnglishUSLayout(),
        thaiLayout: any KeyboardLayout = ThaiKedmaneeLayout()
    ) {
        self.englishLayout = englishLayout
        self.thaiLayout = thaiLayout
    }

    func convert(_ text: String, direction: ConversionDirection) -> String {
        let source: any KeyboardLayout
        let destination: any KeyboardLayout

        switch direction {
        case .englishToThai:
            source = englishLayout
            destination = thaiLayout
        case .thaiToEnglish:
            source = thaiLayout
            destination = englishLayout
        }

        let sourceReverseMap = source.reverseMap
        var output = String.UnicodeScalarView()
        output.reserveCapacity(text.unicodeScalars.count)

        for scalar in text.unicodeScalars {
            guard let sourceKey = sourceReverseMap[scalar]?.first,
                  let convertedScalar = destination.keyMap[sourceKey] else {
                output.append(scalar)
                continue
            }
            output.append(convertedScalar)
        }

        return String(output)
    }
}
