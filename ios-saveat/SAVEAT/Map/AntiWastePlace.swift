import CoreLocation
import Foundation
import SwiftUI

/// A category shown on the SAVEAT Local map.
///
/// `localProducer` exists so the model and repository already support it
/// (§15/§22), but it is deliberately excluded from `visibleCases` — no
/// producer data ships yet, and the category is not offered as a filter.
nonisolated enum AntiWasteCategory: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case basket
    case antiWasteStore
    case communityFridge
    case association
    case partner
    case deal
    case restaurant
    case localProducer

    nonisolated var id: String { rawValue }

    /// Every category the map can filter on today.
    nonisolated static var visibleCases: [AntiWasteCategory] {
        allCases.filter { $0 != .localProducer }
    }

    nonisolated var title: String {
        switch self {
        case .basket: S.Map.categoryBasket.s
        case .antiWasteStore: S.Map.categoryAntiWasteStore.s
        case .communityFridge: S.Map.categoryCommunityFridge.s
        case .association: S.Map.categoryAssociation.s
        case .partner: S.Map.categoryPartner.s
        case .deal: S.Map.categoryDeal.s
        case .restaurant: S.Map.categoryRestaurant.s
        case .localProducer: S.Map.categoryLocalProducer.s
        }
    }

    nonisolated var icon: String {
        switch self {
        case .basket: "basket.fill"
        case .antiWasteStore: "cart.fill"
        case .communityFridge: "refrigerator.fill"
        case .association: "heart.fill"
        case .partner: "storefront.fill"
        case .deal: "percent"
        case .restaurant: "fork.knife"
        case .localProducer: "leaf.fill"
        }
    }

    nonisolated var tint: Color {
        switch self {
        case .basket: SaveatColors.brand
        case .antiWasteStore: SaveatColors.forestDeep
        case .communityFridge: SaveatColors.lavender
        case .association: SaveatColors.alert
        case .partner: SaveatColors.promo
        case .deal: SaveatColors.promo
        case .restaurant: SaveatColors.brandLight
        case .localProducer: SaveatColors.brand
        }
    }
}

/// Where an `AntiWastePlace` record came from.
///
/// Kept on every place so the UI can show a proper attribution — required by
/// OpenStreetMap's ODbL and by ADEME's Licence Ouverte — and so deduplication
/// can decide which of two matching records to keep.
nonisolated enum DataSource: String, Codable, Hashable, Sendable {
    case openStreetMap
    case ademe
    case saveat
    case partner

    nonisolated var attributionText: String {
        switch self {
        case .openStreetMap: "© OpenStreetMap contributors"
        case .ademe: "Data ADEME"
        case .saveat, .partner: "SAVEAT"
        }
    }
}

/// One point on the SAVEAT Local map — a basket, a community fridge, a
/// partner store, an association or a deal.
///
/// Distance is deliberately **not** a stored property: it depends on the
/// viewer's current position and would go stale the moment they move.
/// `AntiWasteMapViewModel.distanceKm(to:)` computes it on demand instead.
nonisolated struct AntiWastePlace: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var name: String
    var category: AntiWasteCategory
    var latitude: Double
    var longitude: Double
    var address: String
    var city: String
    var postalCode: String
    var description: String
    var openingHours: String?
    var websiteURLString: String?
    var phone: String?
    var partnerName: String?
    var offerTitle: String?
    var offerDescription: String?
    var imageURLString: String?
    var isPartner: Bool = false
    var isFeatured: Bool = false

    /// Where this record was fetched from.
    var source: DataSource = .saveat
    /// The record's own identifier at the source (an OSM node id, an ADEME
    /// `identifiant`…), kept for deduplication and for linking back.
    var sourceID: String = ""
    /// Direct link to the record at its source, when one exists (e.g. the
    /// OSM node page).
    var sourceURLString: String?
    /// The licence this record is published under, e.g. "ODbL" or
    /// "Licence Ouverte 2.0" — shown next to the source in the detail sheet.
    var license: String?
    /// When the source last reported this record as up to date.
    var lastUpdated: Date?
    /// True only for a record SAVEAT has itself reviewed (a partner, a
    /// manually checked place). Every OSM/ADEME import starts `false` —
    /// open data is never presented as independently verified by SAVEAT.
    var isVerified: Bool = false

    /// True for every place coming from `MockAntiWastePlacesService`. Shown
    /// as a visible "Exemple" badge — never presented as a real place or a
    /// real partnership (§18).
    var isTestData: Bool = false

    nonisolated var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    nonisolated var websiteURL: URL? {
        guard let websiteURLString, !websiteURLString.isEmpty else { return nil }
        return URL(string: websiteURLString)
    }

    nonisolated var imageURL: URL? {
        guard let imageURLString, !imageURLString.isEmpty else { return nil }
        return URL(string: imageURLString)
    }

    nonisolated var sourceURL: URL? {
        guard let sourceURLString, !sourceURLString.isEmpty else { return nil }
        return URL(string: sourceURLString)
    }

    nonisolated var fullAddress: String {
        "\(address), \(postalCode) \(city)"
    }
}
