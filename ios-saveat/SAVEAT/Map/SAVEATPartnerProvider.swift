import Foundation

/// Placeholder for SAVEAT's own network of verified partner places.
///
/// Mirrors `SAVEATBasketProvider` (`BasketOffer.swift`): returns nothing
/// today, on purpose. A partner place is only ever added once SAVEAT has
/// actually verified it — never inferred from open data, which is why this
/// stays separate from `OpenStreetMapProvider`/`ADEMEProvider` instead of
/// tagging their imports as partners. Worldwide in scope, since a future
/// partner network isn't bound to one country either.
nonisolated struct SAVEATPartnerProvider: AntiWastePlacesProviding {
    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        []
    }
}
