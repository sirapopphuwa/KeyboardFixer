import Foundation

enum ConversionDirection: String, CaseIterable, Identifiable, Sendable {
    case englishToThai
    case thaiToEnglish

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .englishToThai: "English → Thai"
        case .thaiToEnglish: "Thai → English"
        }
    }
}

enum ConversionMode: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case englishToThai
    case thaiToEnglish

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "Auto"
        case .englishToThai: "English → Thai"
        case .thaiToEnglish: "Thai → English"
        }
    }

    var direction: ConversionDirection? {
        switch self {
        case .automatic: nil
        case .englishToThai: .englishToThai
        case .thaiToEnglish: .thaiToEnglish
        }
    }
}

enum DetectionResult: Equatable, Sendable {
    case englishToThai
    case thaiToEnglish
    case uncertain

    var direction: ConversionDirection? {
        switch self {
        case .englishToThai: .englishToThai
        case .thaiToEnglish: .thaiToEnglish
        case .uncertain: nil
        }
    }
}
