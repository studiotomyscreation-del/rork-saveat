import Foundation

/// GS1 mod-10 check digit, shared by every GTIN length (GTIN-8, -12, -13, -14).
///
/// Weights alternate 3, 1, 3, 1… starting from the digit right next to the
/// check digit, so the same routine serves every length without padding.
nonisolated enum GTINCheckDigit {

    /// Value of an ASCII digit `0`–`9`, or nil for anything else — including
    /// non-Latin digits ("٣", "３") that `Character.wholeNumberValue` would accept.
    nonisolated static func digitValue(_ character: Character) -> Int? {
        guard let ascii = character.asciiValue, ascii >= 48, ascii <= 57 else { return nil }
        return Int(ascii) - 48
    }

    /// Check digit for `body` (every digit except the check digit itself).
    /// Nil when `body` is empty or holds anything but ASCII digits.
    nonisolated static func compute(for body: String) -> Character? {
        guard !body.isEmpty else { return nil }
        var sum = 0
        for (offset, character) in body.reversed().enumerated() {
            guard let value = digitValue(character) else { return nil }
            sum += value * (offset.isMultiple(of: 2) ? 3 : 1)
        }
        let digit = (10 - sum % 10) % 10
        return Character(String(digit))
    }

    /// True when the last digit of `digits` is the correct check digit for the rest.
    nonisolated static func isValid(_ digits: String) -> Bool {
        guard digits.count >= 2, let last = digits.last,
              let expected = compute(for: String(digits.dropLast())) else { return false }
        return last == expected
    }
}
