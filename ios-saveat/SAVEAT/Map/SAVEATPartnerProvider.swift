import Foundation

/// SAVEAT's own network of verified partner places.
///
/// A partner place is only ever added once SAVEAT has actually verified it —
/// here, that means a professional who signed up through SAVEAT PRO with a
/// SIRET confirmed against the official French business registry
/// (`FranceBusinessRegistryProvider`), never inferred from open data.
/// Worldwide in scope, since a future partner network isn't bound to one
/// country either.
///
/// **Reads `ProAccountStore`'s own `UserDefaults` keys directly**, not
/// through `Environment` — a stateless `AntiWastePlacesProviding` value has
/// no way to receive an `@Observable` store, and `AntiWasteRepository.shared`
/// is built once at launch, before any environment exists. `ProAccountStore.Keys`
/// is `internal` rather than `private` specifically so this file can share
/// the exact same key strings instead of duplicating them.
///
/// SAVEAT has no backend yet (§13, §22 of the SAVEAT PRO spec — see
/// `ProAccountStore`'s own doc comment), so **this can only ever surface the
/// one merchant signed up on this same device** — there is no server to
/// relay another professional's basket to a different customer's phone.
/// That is a real, current limitation, not a bug: every basket-creation
/// screen says so (`basketFormLocalOnlyNotice`).
nonisolated struct SAVEATPartnerProvider: AntiWastePlacesProviding {
    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        guard let merchant = Self.decode(Merchant.self, key: ProAccountStore.Keys.merchant),
              let location = Self.decode(MerchantLocation.self, key: ProAccountStore.Keys.location)
        else { return [] }

        guard (bbox.minLatitude...bbox.maxLatitude).contains(location.latitude),
              (bbox.minLongitude...bbox.maxLongitude).contains(location.longitude)
        else { return [] }

        let offers: [BasketOffer] = Self.decode([BasketOffer].self, key: ProAccountStore.Keys.offers) ?? []
        let activeOffer = offers.first { $0.isAvailable }

        return [Self.place(merchant: merchant, location: location, offer: activeOffer)]
    }

    // MARK: - Mapping

    private static func place(merchant: Merchant, location: MerchantLocation, offer: BasketOffer?) -> AntiWastePlace {
        AntiWastePlace(
            id: "saveat-pro-\(location.id)",
            name: merchant.displayName,
            category: .basket,
            latitude: location.latitude,
            longitude: location.longitude,
            address: location.address,
            city: location.city,
            postalCode: location.postalCode,
            countryCode: location.countryCode,
            description: Self.description(merchant: merchant, location: location),
            openingHours: location.openingHours,
            websiteURLString: merchant.websiteURLString,
            phone: merchant.phone,
            partnerName: merchant.displayName,
            offerTitle: offer?.title,
            offerDescription: offer.map(offerSummary),
            isPartner: true,
            source: .saveat,
            sourceID: location.id,
            isVerified: true
        )
    }

    /// Merchant free text plus the location's own pickup instructions
    /// (§8 — "Sonnez à la porte de service", "Présentez votre e-mail de
    /// confirmation"…), when the professional wrote one. Falls back to a
    /// generic line so the place is never shown with a blank description.
    private static func description(merchant: Merchant, location: MerchantLocation) -> String {
        let parts = [merchant.merchantDescription, location.pickupInstructions]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? S.Map.saveatPartnerDescription.s : parts.joined(separator: " — ")
    }

    private static func offerSummary(_ offer: BasketOffer) -> String {
        let priceText = S.Map.basketOfferPriceFormat.f(
            Format.euro(offer.discountedPrice),
            Format.euro(offer.originalPrice),
            offer.discountPercent
        )
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: offer.pickupStart)
        let endComponents = calendar.dateComponents([.hour, .minute], from: offer.pickupEnd)
        let start = Units.time(hour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0)
        let end = Units.time(hour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0)
        let pickupText = S.Map.basketOfferPickupFormat.f(start, end)
        let parts = [offer.description, priceText, pickupText].filter { !$0.isEmpty }
        return parts.joined(separator: "\n")
    }

    // MARK: - Decoding

    private static func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
