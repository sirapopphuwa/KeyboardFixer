import Foundation

enum PhysicalKey: String, CaseIterable, Sendable {
    case grave
    case one, two, three, four, five, six, seven, eight, nine, zero
    case minus, equal
    case q, w, e, r, t, y, u, i, o, p
    case leftBracket, rightBracket, backslash
    case a, s, d, f, g, h, j, k, l
    case semicolon, quote
    case z, x, c, v, b, n, m
    case comma, period, slash
}

struct KeyboardKey: Hashable, Sendable {
    let key: PhysicalKey
    let shifted: Bool
}
