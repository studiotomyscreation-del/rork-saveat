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
    /// `amenity=food_sharing` — a shared shelf/box/cabinet for surplus food,
    /// kept distinct from `communityFridge` (§11 of the map-sources import —
    /// OSM tags both concepts differently, and so does this taxonomy now).
    case foodSharing
    /// An épicerie solidaire — subsidized groceries for people in need, a
    /// different concept from `antiWasteStore` (a discount anti-waste
    /// grocery anyone can walk into).
    case solidarityGrocery
    /// A food bank / distribution point (`social_facility=food_bank`) —
    /// split out of `association` because not every one of these is freely
    /// open to the public the way a community fridge is (§1 of the import
    /// brief: "les food_bank ne sont pas toutes des points anti-gaspi
    /// accessibles librement").
    case foodDistribution

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
        case .foodSharing: S.Map.categoryFoodSharing.s
        case .solidarityGrocery: S.Map.categorySolidarityGrocery.s
        case .foodDistribution: S.Map.categoryFoodDistribution.s
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
        case .foodSharing: "shippingbox.fill"
        case .solidarityGrocery: "bag.fill"
        case .foodDistribution: "hand.raised.fill"
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
        case .foodSharing: SaveatColors.lavender
        case .solidarityGrocery: SaveatColors.forestDeep
        case .foodDistribution: SaveatColors.alert
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
    /// `NousAntiGaspiProvider` — real store addresses curated from the
    /// chain's own public website, not a SAVEAT partnership (see that
    /// provider's doc comment). Attributed to them, never to SAVEAT.
    case nousAntiGaspi
    /// Any provider sourced from an open dataset published on data.gouv.fr
    /// by a French public administration (a commune, an agglomération, a
    /// département…) — `MulhouseOpenDataProvider` today, more to come. The
    /// specific publishing organisation and exact licence live on
    /// `AntiWastePlace.license` per record (they vary by dataset), while
    /// this case is only the generic "where this kind of data comes from"
    /// label — see `AntiWastePlaceDetailView.attribution`.
    case dataGouvFr
    /// Any provider sourced from Open Data Wallonie-Bruxelles (`odwb.be`) —
    /// the Belgian equivalent of `dataGouvFr`, kept as its own case rather
    /// than reused because the attribution text below names the actual
    /// catalog ("data.gouv.fr" would be factually wrong under a Belgian
    /// record). `LiegeOpenDataProvider` today. Publishing organisation and
    /// exact licence (e.g. "CC BY") still live on `AntiWastePlace.license`
    /// per record.
    case odwb

    nonisolated var attributionText: String {
        switch self {
        case .openStreetMap: "© OpenStreetMap contributors"
        case .ademe: "Data ADEME"
        case .saveat, .partner: "SAVEAT"
        case .nousAntiGaspi: "NOUS Anti-Gaspi"
        case .dataGouvFr: "data.gouv.fr"
        case .odwb: "Open Data Wallonie-Bruxelles"
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
    /// French département code ("33", "75", "2A"…), for sources that need
    /// finer granularity than `region`. Derived deterministically from the
    /// postal code where the source doesn't provide it directly (see
    /// `FrenchAdministrativeDivisions.department(fromPostalCode:)`) — never
    /// guessed for a non-French address.
    var department: String? = nil
    /// ISO 3166-1 alpha-2 country code (e.g. "FR", "US"), when the source
    /// publishes or implies one. Never guessed from the app's language —
    /// only from the record itself or from a provider that only ever
    /// covers one country (`ADEMEProvider` always sets "FR").
    var countryCode: String? = nil
    /// State / province / administrative region, for countries where a city
    /// and postal code alone don't disambiguate a place (e.g. US "TX").
    var region: String? = nil
    /// ISO 4217 currency code for any price shown on this place's offer,
    /// when one applies. Never assumed to be EUR (§ modèle international).
    var currencyCode: String? = nil
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
