import Foundation

/// A discounted "surprise basket" offer at a place, once SAVEAT actually has
/// its own basket partners.
///
/// Separate from `AntiWastePlace` on purpose: an offer *decorates* an
/// existing place (via `placeID`), it never creates one — a shop shows up on
/// the map because it is a real place, with or without a current offer.
nonisolated struct BasketOffer: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var placeID: String
    var title: String
    var description: String
    var originalPrice: Double
    var discountedPrice: Double
    var quantityAvailable: Int
    var pickupStart: Date
    var pickupEnd: Date
    var imageURLString: String?
    var updatedAt: Date

    nonisolated var imageURL: URL? {
        guard let imageURLString, !imageURLString.isEmpty else { return nil }
        return URL(string: imageURLString)
    }

    nonisolated var isAvailable: Bool {
        quantityAvailable > 0 && pickupEnd > .now
    }

    nonisolated var discountPercent: Int {
        guard originalPrice > 0 else { return 0 }
        return Int(((originalPrice - discountedPrice) / originalPrice * 100).rounded())
    }
}

/// Anything that can list current basket offers for a set of places. Mirrors
/// `AntiWastePlacesProviding`'s shape so a future SAVEAT backend, once real
/// merchants exist, is a drop-in replacement here too.
protocol BasketOffersProviding: Sendable {
    func offers(for placeIDs: [String]) async -> [BasketOffer]
}

/// Placeholder for SAVEAT's own future basket marketplace.
///
/// Returns nothing today — on purpose. Basket availability, quantities and
/// prices are never invented or estimated from open data; this provider only
/// turns on once real SAVEAT merchants or an authorised partner feed exist.
nonisolated struct SAVEATBasketProvider: BasketOffersProviding {
    func offers(for placeIDs: [String]) async -> [BasketOffer] {
        []
    }
}
