import Foundation

/// Derives a Belgian province and région from a postal code — a real,
/// verified mapping (cross-checked against Wikipedia FR/EN and real
/// municipalities at each range boundary: 1299→1300 is Bruxelles-Capitale
/// → Brabant wallon, 1499→1500 is Brabant wallon → Brabant flamand,
/// 5680→6000 and 6599→6600 are the Hainaut/Luxembourg split), never a
/// guess.
///
/// Unlike France's single leading-two-digits rule, Belgium splits some
/// thousand-blocks between two provinces at the HUNDREDS level, not the
/// thousands level — e.g. "3xxx" is Brabant flamand for 3000–3499 and
/// Limbourg for 3500–3999. Every boundary below is that real split, never
/// just the leading digit.
nonisolated enum BelgianAdministrativeDivisions {
    /// `nil` when `postalCode` isn't a well-formed 4-digit Belgian postal code.
    nonisolated static func province(fromPostalCode postalCode: String) -> String? {
        guard let code = Self.code(fromPostalCode: postalCode) else { return nil }
        switch code {
        case 1000...1299: "Bruxelles-Capitale"
        case 1300...1499: "Brabant wallon"
        case 1500...1999, 3000...3499: "Brabant flamand"
        case 2000...2999: "Anvers"
        case 3500...3999: "Limbourg"
        case 4000...4999: "Liège"
        case 5000...5999: "Namur"
        case 6000...6599, 7000...7999: "Hainaut"
        case 6600...6999: "Luxembourg"
        case 8000...8999: "Flandre-Occidentale"
        case 9000...9999: "Flandre-Orientale"
        default: nil
        }
    }

    /// `nil` when `postalCode` isn't well-formed or falls outside every
    /// known range above. Bruxelles-Capitale is its own région (no
    /// province since the 1995 reform) — never grouped with a province.
    nonisolated static func region(fromPostalCode postalCode: String) -> String? {
        guard let code = Self.code(fromPostalCode: postalCode) else { return nil }
        switch code {
        case 1000...1299: "Bruxelles-Capitale"
        case 1300...1499, 4000...4999, 5000...5999, 6000...7999: "Wallonie"
        case 1500...3999, 8000...9999: "Flandre"
        default: nil
        }
    }

    private nonisolated static func code(fromPostalCode postalCode: String) -> Int? {
        let digits = postalCode.filter(\.isNumber)
        guard digits.count == 4 else { return nil }
        return Int(digits)
    }
}
