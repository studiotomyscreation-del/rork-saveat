import Foundation

/// A national business registry SAVEAT PRO can identify a merchant against.
///
/// One implementation per country (§42 of the SAVEAT PRO spec) — France
/// ships first via `FranceBusinessRegistryProvider`; every other country
/// stays unimplemented until a real, reliably licensed source exists for it
/// (§57: "ne pas implémenter les pays sans source fiable").
protocol BusinessRegistryProviding: Sendable {
    var countryCode: String { get }

    /// `identifier` is whatever the professional typed — a SIRET or a
    /// SIREN for France. Never throws for "not found"; that's a normal,
    /// expected outcome (`.notFound`), not a failure.
    func lookup(identifier: String) async throws -> BusinessLookupResult
}

nonisolated enum BusinessRegistryError: Error, Sendable {
    case invalidIdentifierFormat
    case serviceUnavailable
}

nonisolated enum BusinessLookupResult: Sendable {
    case single(BusinessRegistryRecord)
    /// More than one establishment matched and the professional must pick
    /// (§9) — always real records from the registry, never padded to look
    /// complete.
    case multiple([BusinessRegistryRecord])
    case notFound
}

/// One establishment as reported by a business registry.
///
/// This is a lookup result, not yet a `MerchantLocation` — a later phase
/// maps it into `Merchant`/`MerchantLocation` once the professional
/// confirms "C'est mon établissement" (§8).
nonisolated struct BusinessRegistryRecord: Identifiable, Sendable, Hashable {
    nonisolated var id: String { siret }

    var siren: String
    var siret: String
    var legalName: String
    var tradeName: String?
    /// APE/NAF code, when the registry provides one (§11). No
    /// human-readable label comes from this source — a later phase maps
    /// the food-relevant codes to labels from INSEE's own nomenclature,
    /// never guesses one from the code's digits.
    var activityCode: String?
    var administrativeStatus: MerchantAdministrativeStatus
    var address: String
    var postalCode: String
    var city: String
    var countryCode: String
    var isHeadquarters: Bool
    /// How many establishments this business has in total, when the
    /// registry reports it — lets the UI say "this business has other
    /// locations" even on a lookup that could only resolve one of them
    /// (see `FranceBusinessRegistryProvider`'s doc comment for why that
    /// can happen).
    var totalEstablishmentCount: Int?
}
