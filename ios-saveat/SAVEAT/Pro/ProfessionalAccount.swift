import Foundation

/// The person responsible for a `Merchant` on SAVEAT PRO — one signed-up
/// human, kept separate from the business itself (`Merchant`) so a chain
/// with several `MerchantLocation`s can eventually have more than one
/// account managing it without duplicating the business record.
///
/// No password or session token lives here — authentication is a separate
/// concern (§13: reuse SAVEAT's own auth once it exists, §22: nothing here
/// substitutes for real server-side identity checks). This only holds the
/// profile fields SAVEAT actually needs from the responsible person.
nonisolated struct ProfessionalAccount: Identifiable, Codable, Hashable, Sendable {
    var id: String
    /// The authenticated identity this account is signed in as.
    var userID: String
    var merchantID: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    /// ISO 3166-1 alpha-2, e.g. "FR" — which `BusinessRegistryProviding`
    /// implementation validated this account's merchant (§42).
    var countryCode: String
    var status: ProfessionalAccountStatus
    var createdAt: Date
    var updatedAt: Date

    nonisolated var fullName: String { "\(firstName) \(lastName)" }
}

nonisolated enum ProfessionalAccountStatus: String, Codable, Sendable {
    case pending
    case active
    case suspended
}
