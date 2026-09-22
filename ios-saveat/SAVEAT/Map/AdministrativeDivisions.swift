import Foundation

/// Routes to the right country-specific administrative-division deriver, so
/// a provider like `OpenStreetMapProvider` never has to know which
/// countries are supported or hardcode a single one (§ audit countryCode /
/// extension Belgique).
///
/// A plain dispatch factory, not a protocol: there is no need to iterate
/// over resolvers dynamically or store them polymorphically — each case is
/// a direct call to that country's own file, added one at a time as a real,
/// verified postal-code mapping exists for it (the same rigor as
/// `FrenchAdministrativeDivisions` itself: never a guess).
///
/// `FrenchAdministrativeDivisions.swift` is untouched by this file — this
/// only adds a routing layer in front of it.
nonisolated enum AdministrativeDivisions {
    /// The finer subdivision (French département…), or `nil` when
    /// `countryCode` isn't covered yet or the postal code doesn't parse.
    nonisolated static func subdivision(countryCode: String, postalCode: String) -> String? {
        switch countryCode {
        case "FR": FrenchAdministrativeDivisions.department(fromPostalCode: postalCode)
        case "BE": BelgianAdministrativeDivisions.province(fromPostalCode: postalCode)
        default: nil
        }
    }

    /// The broader subdivision (French région, Belgian région…), when this
    /// country's rules can derive one from the postal code alone. `nil` for
    /// France today — `OpenStreetMapProvider` already gets région from
    /// OSM's own `addr:state`/`addr:province` tags when present, so no
    /// postal-code derivation exists for it yet; add one here only if that
    /// stops being enough.
    nonisolated static func region(countryCode: String, postalCode: String) -> String? {
        switch countryCode {
        case "BE": BelgianAdministrativeDivisions.region(fromPostalCode: postalCode)
        default: nil
        }
    }
}
