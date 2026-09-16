import Foundation

/// A food business on SAVEAT PRO — the legal/commercial entity, not a
/// specific shop front (see `MerchantLocation` for that, §9: one SIREN can
/// cover several establishments).
///
/// Identity always comes from a business registry via `businessIdentifier`/
/// `businessIdentifierType`, never from free text the professional types
/// (§6-11) — nothing here is invented or self-declared unless the field's
/// own comment says so.
nonisolated struct Merchant: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var legalName: String
    /// Public-facing name ("enseigne"), when the registry provides one
    /// separately from `legalName`.
    var tradeName: String?
    /// The registry identifier this merchant was found and confirmed
    /// with — a SIRET for France today (§42).
    var businessIdentifier: String
    var businessIdentifierType: BusinessIdentifierType
    /// APE/NAF-style code, only when the registry provides one (§11).
    var activityCode: String?
    var activityLabel: String?
    var administrativeStatus: MerchantAdministrativeStatus
    var phone: String?
    var websiteURLString: String?
    var logoURLString: String?
    var coverImageURLString: String?
    /// Free text the professional writes themselves (§14) — never
    /// generated on their behalf.
    var merchantDescription: String?
    var createdAt: Date
    var updatedAt: Date

    nonisolated var displayName: String { tradeName ?? legalName }

    nonisolated var websiteURL: URL? {
        guard let websiteURLString, !websiteURLString.isEmpty else { return nil }
        return URL(string: websiteURLString)
    }

    nonisolated var logoURL: URL? {
        guard let logoURLString, !logoURLString.isEmpty else { return nil }
        return URL(string: logoURLString)
    }

    nonisolated var coverImageURL: URL? {
        guard let coverImageURLString, !coverImageURLString.isEmpty else { return nil }
        return URL(string: coverImageURLString)
    }
}

/// Which national business registry `businessIdentifier` was validated
/// against. France ships first (`siret`, backed by `FranceBusinessRegistryProvider`
/// in a later phase); every other case is reserved for when a real,
/// reliable provider exists for that country — never added speculatively
/// (§42, §57: "ne pas implémenter les pays sans source fiable").
nonisolated enum BusinessIdentifierType: String, Codable, Sendable {
    case siret
}

/// What the registry itself reports about the establishment — never a
/// claim about the responsible person's identity. Drives the
/// "✓ Établissement identifié" badge, never "✓ Professionnel vérifié"
/// (§10).
nonisolated enum MerchantAdministrativeStatus: String, Codable, Sendable {
    case active
    case closed
    /// The registry didn't return a clear status. Treated like `closed`
    /// for activation purposes — never auto-activate without evidence
    /// (§10).
    case unknown
}
