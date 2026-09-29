import Foundation

/// UPC-E (zero-suppressed UPC) → UPC-A expansion, per the GS1 / UCC rules.
///
/// A UPC-E symbol is `N d1 d2 d3 d4 d5 d6 C`: number system `N` (0 or 1), six
/// data digits and the check digit **of the expanded UPC-A**. The last data
/// digit `d6` says where the suppressed zeros go:
///
/// - `d6` 0, 1, 2 → manufacturer `d1 d2 d6 0 0`, item `0 0 d3 d4 d5`
/// - `d6` 3       → manufacturer `d1 d2 d3 0 0`, item `0 0 0 d4 d5`
/// - `d6` 4       → manufacturer `d1 d2 d3 d4 0`, item `0 0 0 0 d5`
/// - `d6` 5 … 9   → manufacturer `d1 d2 d3 d4 d5`, item `0 0 0 0 d6`
///
/// This is not padding: the zeros are re-inserted in the middle of the code.
nonisolated enum UPCE {

    /// The 12-digit UPC-A a UPC-E stands for, keeping the UPC-E's own check digit
    /// (it already is the UPC-A check digit). Validate the result with
    /// `GTINCheckDigit.isValid` — a misread UPC-E expands to an invalid UPC-A.
    ///
    /// Nil when `code` is not UPC-E shaped: not 8 ASCII digits, or a number
    /// system other than 0 or 1.
    nonisolated static func expand(_ code: String) -> String? {
        let d = Array(code)
        guard d.count == 8,
              d.allSatisfy({ GTINCheckDigit.digitValue($0) != nil }),
              d[0] == "0" || d[0] == "1" else { return nil }

        let x = Array(d[1...6])
        let manufacturer: [Character]
        let item: [Character]
        switch x[5] {
        case "0", "1", "2":
            manufacturer = [x[0], x[1], x[5], "0", "0"]
            item = ["0", "0", x[2], x[3], x[4]]
        case "3":
            manufacturer = [x[0], x[1], x[2], "0", "0"]
            item = ["0", "0", "0", x[3], x[4]]
        case "4":
            manufacturer = [x[0], x[1], x[2], x[3], "0"]
            item = ["0", "0", "0", "0", x[4]]
        default:
            manufacturer = [x[0], x[1], x[2], x[3], x[4]]
            item = ["0", "0", "0", "0", x[5]]
        }
        return String([d[0]] + manufacturer + item + [d[7]])
    }
}
