import CoreLocation
import Foundation
import Observation

/// Local-only home for the professional's own account, business record,
/// shop location and basket offers.
///
/// SAVEAT has no backend yet (see the Phase 1 audit — 100% local app, no
/// server, no auth), so "creating a SAVEAT PRO account" today means saving
/// these records on this device only. Never synced, never shared with
/// anyone, and lost if the app is reinstalled — until a real backend exists
/// (§13, §22). Same `UserDefaults` + `@Observable` pattern as `AppStore`.
///
/// A basket published here is only ever visible on **this same device's**
/// map (`SAVEATPartnerProvider` reads these exact keys) — there is no server
/// to relay it to a customer's phone yet. Every screen that lets a
/// professional publish a basket must say that plainly.
@Observable
final class ProAccountStore {
    /// Not `private` — `SAVEATPartnerProvider` reads the same `UserDefaults`
    /// keys directly (it has no way to receive this store via `Environment`,
    /// being a stateless `AntiWastePlacesProviding` value), so the key
    /// strings live in exactly one place rather than being duplicated.
    enum Keys {
        static let account = "saveat.pro.account.v1"
        static let merchant = "saveat.pro.merchant.v1"
        static let location = "saveat.pro.location.v1"
        static let offers = "saveat.pro.offers.v1"
    }

    private(set) var account: ProfessionalAccount? {
        didSet { persist(account, key: Keys.account) }
    }
    private(set) var merchant: Merchant? {
        didSet { persist(merchant, key: Keys.merchant) }
    }
    /// Geocoded once at sign-up from the registry's own address (§12) — see
    /// `geocodeLocation`. `nil` when geocoding failed; the professional still
    /// has an account, it just can't appear on the map yet.
    private(set) var location: MerchantLocation? {
        didSet { persist(location, key: Keys.location) }
    }
    private(set) var offers: [BasketOffer] = [] {
        didSet { persist(offers, key: Keys.offers) }
    }

    var hasAccount: Bool { account != nil }

    /// The single basket currently shown on the map, if any — SAVEAT PRO
    /// only ever surfaces one active offer per location today (see
    /// `publishOffer`'s doc comment for why).
    var currentOffer: BasketOffer? { offers.first { $0.isAvailable } }

    init() {
        account = Self.load(Keys.account)
        merchant = Self.load(Keys.merchant)
        location = Self.load(Keys.location)
        offers = Self.load(Keys.offers) ?? []
    }

    /// Saves the merchant and responsible-person records once the
    /// established business is confirmed and the form is filled in (§13).
    /// Everything here comes from `record` (registry-verified) or the
    /// person's own input — nothing invented. IDs are generated on-device,
    /// never issued by a server that doesn't exist yet.
    ///
    /// Also geocodes `record`'s own address into `location` — async because
    /// that's a real network round-trip through `CLGeocoder`, never a
    /// hand-typed coordinate.
    func createAccount(
        from record: BusinessRegistryRecord,
        firstName: String,
        lastName: String,
        email: String,
        phone: String
    ) async {
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
        location = await Self.geocodeLocation(for: record, merchantID: newMerchant.id)
    }

    /// Publishes a new basket at the professional's own location, replacing
    /// whatever was showing before.
    ///
    /// One active offer at a time, deliberately: `AntiWastePlace` carries a
    /// single `offerTitle`/`offerDescription` pair per place (§22 — an offer
    /// decorates a place, it doesn't multiply it), so a merchant with several
    /// simultaneous baskets isn't representable on the map without a bigger
    /// model change. Publishing again here simply supersedes the previous
    /// offer rather than stacking it.
    func publishOffer(
        title: String,
        description: String,
        basketType: BasketType,
        originalPrice: Double,
        discountedPrice: Double,
        quantity: Int,
        pickupStart: Date,
        pickupEnd: Date,
        dietaryInformation: [DietaryClaim]
    ) {
        guard let merchant, let location else { return }
        let now = Date()
        for index in offers.indices where offers[index].isAvailable {
            offers[index].status = .cancelled
            offers[index].updatedAt = now
        }
        let offer = BasketOffer(
            id: UUID().uuidString,
            placeID: location.id,
            merchantID: merchant.id,
            locationID: location.id,
            title: title,
            description: description,
            basketType: basketType,
            originalPrice: originalPrice,
            discountedPrice: discountedPrice,
            currencyCode: "EUR",
            quantityInitial: quantity,
            quantityAvailable: quantity,
            pickupStart: pickupStart,
            pickupEnd: pickupEnd,
            dietaryInformation: dietaryInformation,
            allergenInformation: nil,
            status: .available,
            imageURLString: nil,
            createdAt: now,
            updatedAt: now,
            publishedAt: now
        )
        offers.insert(offer, at: 0)
    }

    /// Pulls the current basket off the map without deleting its history.
    func cancelCurrentOffer() {
        guard let index = offers.firstIndex(where: { $0.isAvailable }) else { return }
        offers[index].status = .cancelled
        offers[index].updatedAt = Date()
    }

    /// Leaves SAVEAT PRO on this device. The professional can sign up again
    /// any time — never called automatically.
    func reset() {
        account = nil
        merchant = nil
        location = nil
        offers = []
    }

    // MARK: - Geocoding

    /// Same technique as `NousAntiGaspiProvider`: never a hand-typed
    /// lat/long, always `CLGeocoder` on the real address. Only France exists
    /// as a registry today (`FranceBusinessRegistryProvider`), so the time
    /// zone is hardcoded to Europe/Paris rather than the signing-up phone's
    /// own zone — a French business owner travelling abroad while signing up
    /// must not get their own shop's pickup times shown in the wrong zone.
    /// Revisit this the day a second country's registry ships.
    private static func geocodeLocation(for record: BusinessRegistryRecord, merchantID: String) async -> MerchantLocation? {
        let geocoder = CLGeocoder()
        let fullAddress = "\(record.address), \(record.postalCode) \(record.city), France"
        guard let placemark = try? await geocoder.geocodeAddressString(fullAddress).first,
              let coordinate = placemark.location?.coordinate else { return nil }
        let now = Date()
        return MerchantLocation(
            id: UUID().uuidString,
            merchantID: merchantID,
            siret: record.siret,
            address: record.address,
            postalCode: record.postalCode,
            city: record.city,
            countryCode: record.countryCode,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timeZone: "Europe/Paris",
            openingHours: nil,
            pickupInstructions: nil,
            createdAt: now,
            updatedAt: now
        )
    }

    // MARK: - Persistence

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
