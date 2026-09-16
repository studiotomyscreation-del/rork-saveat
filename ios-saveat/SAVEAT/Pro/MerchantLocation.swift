import CoreLocation
import Foundation

/// One physical shop front a `Merchant` operates from.
///
/// This is what eventually surfaces as an `AntiWastePlace` on the map via
/// `SAVEATPartnerProvider` (§23) — a location becomes a map place, never the
/// other way around, keeping the existing Place/Offer split intact.
nonisolated struct MerchantLocation: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var merchantID: String
    var siret: String
    var address: String
    var postalCode: String
    var city: String
    /// ISO 3166-1 alpha-2.
    var countryCode: String
    /// Geocoded once from the registry's own address at sign-up — never
    /// placed manually while a valid geocode exists (§12).
    var latitude: Double
    var longitude: Double
    /// IANA identifier (e.g. "Europe/Paris"). Every pickup time on this
    /// location's offers reads against this zone, never the reader's own
    /// (§43).
    var timeZone: String
    var openingHours: String?
    var pickupInstructions: String?
    var createdAt: Date
    var updatedAt: Date

    nonisolated var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    nonisolated var fullAddress: String {
        "\(address), \(postalCode) \(city)"
    }
}
