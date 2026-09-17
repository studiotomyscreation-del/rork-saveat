import Foundation
import Observation

/// Local-only home for the professional's own account and business record.
///
/// SAVEAT has no backend yet (see the Phase 1 audit — 100% local app, no
/// server, no auth), so "creating a SAVEAT PRO account" today means saving
/// these two records on this device only. Never synced, never shared with
/// anyone, and lost if the app is reinstalled — until a real backend exists
/// (§13, §22). Same `UserDefaults` + `@Observable` pattern as `AppStore`.
@Observable
final class ProAccountStore {
    private enum Keys {
        static let account = "saveat.pro.account.v1"
        static let merchant = "saveat.pro.merchant.v1"
    }

    private(set) var account: ProfessionalAccount? {
        didSet { persist(account, key: Keys.account) }
    }
    private(set) var merchant: Merchant? {
        didSet { persist(merchant, key: Keys.merchant) }
    }

    var hasAccount: Bool { account != nil }

    init() {
        account = Self.load(Keys.account)
        merchant = Self.load(Keys.merchant)
    }

    /// Saves the merchant and responsible-person records once the
    /// established business is confirmed and the form is filled in (§13).
    /// Everything here comes from `record` (registry-verified) or the
    /// person's own input — nothing invented. IDs are generated on-device,
    /// never issued by a server that doesn't exist yet.
    func createAccount(
        from record: BusinessRegistryRecord,
        firstName: String,
        lastName: String,
        email: String,
        phone: String
    ) {
        let now = Date()
        let newMerchant = Merchant(
            id: UUID().uuidString,
            legalName: record.legalName,
            tradeName: record.tradeName,
            businessIdentifier: record.siret,
            businessIdentifierType: .siret,
            activityCode: record.activityCode,
            activityLabel: nil,
            administrativeStatus: record.administrativeStatus,
            phone: nil,
            websiteURLString: nil,
            logoURLString: nil,
            coverImageURLString: nil,
            merchantDescription: nil,
            createdAt: now,
            updatedAt: now
        )
        merchant = newMerchant
        account = ProfessionalAccount(
            id: UUID().uuidString,
            userID: UUID().uuidString,
            merchantID: newMerchant.id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            countryCode: record.countryCode,
            status: .pending,
            createdAt: now,
            updatedAt: now
        )
    }

    /// Leaves SAVEAT PRO on this device. The professional can sign up again
    /// any time — never called automatically.
    func reset() {
        account = nil
        merchant = nil
    }

    private func persist<T: Encodable>(_ value: T?, key: String) {
        guard let value else {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func load<T: Decodable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
