import Foundation

/// A discounted "surprise basket" offer at a place — published by a SAVEAT
/// PRO merchant once one exists (`SAVEATBasketProvider`, still a stub as of
/// this writing).
///
/// Separate from `AntiWastePlace` on purpose: an offer *decorates* an
/// existing place (via `placeID`), it never creates one — a shop shows up on
/// the map because it is a real place, with or without a current offer
/// (§22). `quantityAvailable` here is always a read of the server's own
/// atomic count (§27) — this struct never decides stock on its own.
nonisolated struct BasketOffer: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var placeID: String
    /// The SAVEAT PRO merchant and location that published this offer, once
    /// one exists — `nil` for any offer predating that feature.
    var merchantID: String?
    var locationID: String?
    var title: String
    var description: String
    var basketType: BasketType
    var originalPrice: Double
    var discountedPrice: Double
    /// ISO 4217 — never assumed to be EUR (§43).
    var currencyCode: String
    /// How many units existed when this offer was published — kept
    /// alongside `quantityAvailable` so the UI can show "3/5 réservés"
    /// without a second lookup.
    var quantityInitial: Int
    var quantityAvailable: Int
    var pickupStart: Date
    var pickupEnd: Date
    /// Only characteristics the merchant has explicitly confirmed for this
    /// basket — never inferred from its title or category (§20).
    var dietaryInformation: [DietaryClaim]
    var allergenInformation: [String]?
    var status: BasketOfferStatus
    var imageURLString: String?
    var createdAt: Date
    var updatedAt: Date
    var publishedAt: Date?

    nonisolated var imageURL: URL? {
        guard let imageURLString, !imageURLString.isEmpty else { return nil }
        return URL(string: imageURLString)
    }

    nonisolated var isAvailable: Bool {
        status == .available && quantityAvailable > 0 && pickupEnd > .now
    }

    nonisolated var discountPercent: Int {
        guard originalPrice > 0 else { return 0 }
        return Int(((originalPrice - discountedPrice) / originalPrice * 100).rounded())
    }
}

/// §18-19 — a surprise basket's exact contents depend on the day's unsold
/// stock and are never promised in advance; a detailed basket lists real,
/// merchant-provided contents.
nonisolated enum BasketType: String, Codable, Sendable {
    case surprise
    case detailed

    nonisolated var title: String {
        switch self {
        case .surprise: S.Pro.basketTypeSurprise.s
        case .detailed: S.Pro.basketTypeDetailed.s
        }
    }
}

/// §35 — the offer's own lifecycle, driven by the merchant and by time
/// (pickup window closing), never guessed from `quantityAvailable` alone.
nonisolated enum BasketOfferStatus: String, Codable, Sendable {
    case draft
    case scheduled
    case available
    case soldOut = "sold_out"
    case pickupClosed = "pickup_closed"
    case completed
    case cancelled

    nonisolated var title: String {
        switch self {
        case .draft: S.Pro.offerStatusDraft.s
        case .scheduled: S.Pro.offerStatusScheduled.s
        case .available: S.Pro.offerStatusAvailable.s
        case .soldOut: S.Pro.offerStatusSoldOut.s
        case .pickupClosed: S.Pro.offerStatusPickupClosed.s
        case .completed: S.Pro.offerStatusCompleted.s
        case .cancelled: S.Pro.offerStatusCancelled.s
        }
    }
}

/// §20 — only what the professional can actually guarantee. `.glutenFree`,
/// `.lactoseFree`, `.halal` and `.kosher` need extra care from whatever UI
/// collects these (the spec calls for confirmation, not a casual toggle);
/// this type only models what can be stored, it doesn't enforce that.
nonisolated enum DietaryClaim: String, Codable, Sendable, CaseIterable, Identifiable {
    case vegetarian
    case vegan
    case porkFree = "pork_free"
    case glutenFree = "gluten_free"
    case lactoseFree = "lactose_free"
    case halal
    case kosher

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .vegetarian: S.Pro.dietaryVegetarian.s
        case .vegan: S.Pro.dietaryVegan.s
        case .porkFree: S.Pro.dietaryPorkFree.s
        case .glutenFree: S.Pro.dietaryGlutenFree.s
        case .lactoseFree: S.Pro.dietaryLactoseFree.s
        case .halal: S.Pro.dietaryHalal.s
        case .kosher: S.Pro.dietaryKosher.s
        }
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
