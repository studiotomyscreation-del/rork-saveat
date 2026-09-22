import Foundation

/// Derives a French département code from a postal code — a real,
/// deterministic administrative mapping (never a guess), used wherever a
/// source gives an address but not the département directly.
///
/// Shared across Map providers (`OpenStreetMapProvider` today, future ADEME/
/// data.gouv.fr imports) so this rule lives in exactly one place.
nonisolated enum FrenchAdministrativeDivisions {
    /// `nil` when `postalCode` isn't a well-formed 5-digit French postal code.
    ///
    /// Overseas départements (Guadeloupe 971, Martinique 972, Guyane 973,
    /// Réunion 974, Mayotte 976…) keep their 3-digit code. Corsica is split
    /// by postal-code range — 200xx/201xx is Corse-du-Sud (2A), 202xx–206xx
    /// is Haute-Corse (2B); every other metropolitan département is simply
    /// the first two digits.
    nonisolated static func department(fromPostalCode postalCode: String) -> String? {
        let digits = postalCode.filter(\.isNumber)
        guard digits.count == 5 else { return nil }

        if digits.hasPrefix("97") || digits.hasPrefix("98") {
            return String(digits.prefix(3))
        }
        if digits.hasPrefix("20"), let firstThree = Int(digits.prefix(3)) {
            return firstThree <= 201 ? "2A" : "2B"
        }
        return String(digits.prefix(2))
    }
}
