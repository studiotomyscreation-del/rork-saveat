import CoreLocation
import Foundation

/// Real stores from NOUS Anti-Gaspi (https://www.nousantigaspi.com), a French
/// anti-waste grocery chain — **not** a SAVEAT partner: no business
/// relationship exists here, this is a curated list of publicly listed
/// addresses. Every address below comes straight from the chain's own
/// official website, one page per store, cross-checked against its
/// `/magasins-sitemap.xml`.
///
/// Added because `OpenStreetMapProvider` alone leaves the map empty in areas
/// OSM's crowd-sourced tagging hasn't reached yet, and a real named chain's
/// own store list is exactly the kind of concrete source worth adding on top
/// of it (§ recherche de sources réelles pour la carte anti-gaspi).
///
/// Deliberately **not** tagged `.partner`/`isPartner: true` — that flag is
/// reserved for an actual SAVEAT business relationship (`SAVEATPartnerProvider`).
/// `isVerified` stays `false` too: this is a curated snapshot of the chain's
/// own published addresses, not a SAVEAT staff visit.
///
/// Coordinates are never hand-typed — every address is forward-geocoded
/// through `CLGeocoder` (Apple's own service, same approach as
/// `CountryDataProviderResolver`, no third-party key) and cached for the
/// app's lifetime, so a mistyped lat/long can never ship silently.
///
/// This list is a manual snapshot, not a live feed, so it will drift as NOUS
/// Anti-Gaspi opens or closes stores — refresh it periodically from the
/// sitemap above.
nonisolated struct NousAntiGaspiProvider: AntiWastePlacesProviding {
    /// Every address is in France — never queried for a map area resolved to
    /// another country (§ architecture internationale).
    nonisolated var supportedCountries: ProviderCountryScope { .countries(["FR"]) }

    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        let all = await GeocodeCache.shared.resolvedPlaces(for: Self.stores)
        return all.filter {
            (bbox.minLatitude...bbox.maxLatitude).contains($0.latitude)
                && (bbox.minLongitude...bbox.maxLongitude).contains($0.longitude)
        }
    }

    // MARK: - Seed data

    struct Store: Sendable {
        let name: String
        let street: String
        let postalCode: String
        let city: String
        let phone: String?
        let pageURLString: String
    }

    /// Snapshot taken from https://www.nousantigaspi.com/magasins-sitemap.xml
    /// and each store's own page, September 2026.
    static let stores: [Store] = [
        Store(name: "NOUS anti-gaspi Bordeaux Fondaudège", street: "131 rue Fondaudège", postalCode: "33000", city: "Bordeaux", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/bordeaux-fondaudege/"),
        Store(name: "NOUS anti-gaspi Bordeaux Victoire", street: "10 place de la Victoire", postalCode: "33000", city: "Bordeaux", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/bordeaux_victoire/"),
        Store(name: "NOUS anti-gaspi Bordeaux Sainte-Colombe", street: "21 rue Sainte-Colombe", postalCode: "33000", city: "Bordeaux", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/bordeaux/"),
        Store(name: "NOUS anti-gaspi Nantes Mercoeur", street: "7 rue Mercoeur", postalCode: "44000", city: "Nantes", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/nantes-mercoeur/"),
        Store(name: "NOUS anti-gaspi Nantes Pitre Chevalier", street: "3 rue Pitre Chevalier", postalCode: "44000", city: "Nantes", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/nantes-pitre-chevalier/"),
        Store(name: "NOUS anti-gaspi Le Pouliguen", street: "18 rue de Cornen", postalCode: "44510", city: "Le Pouliguen", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/le-pouliguen/"),
        Store(name: "NOUS anti-gaspi Rennes Liberté", street: "21 boulevard de la Liberté", postalCode: "35000", city: "Rennes", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/rennes-liberte/"),
        Store(name: "NOUS anti-gaspi Châteaugiron", street: "Rue des Comptoirs, Centre commercial Univer", postalCode: "35410", city: "Châteaugiron", phone: "02 23 37 67 28", pageURLString: "https://www.nousantigaspi.com/magasins/chateaugiron/"),
        Store(name: "NOUS anti-gaspi Cesson-Sévigné", street: "12 rue de la Rigourdière", postalCode: "35510", city: "Cesson-Sévigné", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/cesson-sevigne/"),
        Store(name: "NOUS anti-gaspi Melesse", street: "ZA de la Métairie", postalCode: "35520", city: "Melesse", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/melesse/"),
        Store(name: "NOUS anti-gaspi Saint-Jouan-des-Guérets", street: "1 rue de Siochan", postalCode: "35430", city: "Saint-Jouan-des-Guérets", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/saint-jouan-des-guerets/"),
        Store(name: "NOUS anti-gaspi Dinard – La Richardais", street: "Zone de la Jannaie", postalCode: "35780", city: "La Richardais", phone: "02 99 88 35 34", pageURLString: "https://www.nousantigaspi.com/magasins/dinard-la-richardais/"),
        Store(name: "NOUS anti-gaspi Taden-Dinan", street: "ZAC de la Paquenais", postalCode: "22100", city: "Taden", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/dinan/"),
        Store(name: "NOUS anti-gaspi Lille", street: "73 rue Léon Gambetta", postalCode: "59000", city: "Lille", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/lille/"),
        Store(name: "NOUS anti-gaspi Boulogne Aguesseau", street: "111 rue de Paris", postalCode: "92100", city: "Boulogne-Billancourt", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/magasin-nous-anti-gaspi-boulogne-aguesseau/"),
        Store(name: "NOUS anti-gaspi Boulogne Billancourt", street: "5 rue Tony Garnier", postalCode: "92100", city: "Boulogne-Billancourt", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/boulogne-billancourt/"),
        Store(name: "NOUS anti-gaspi Paris Marcadet", street: "110 rue Marcadet", postalCode: "75018", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/magasin-nous-anti-gaspi-paris-marcadet/"),
        Store(name: "NOUS anti-gaspi Paris Croix-Nivert", street: "220 rue de la Croix Nivert", postalCode: "75015", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-croix-nivert/"),
        Store(name: "NOUS anti-gaspi Paris Saint-Denis", street: "24 boulevard Saint-Denis", postalCode: "75010", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-boulevard-st-denis/"),
        Store(name: "NOUS anti-gaspi Paris Lecourbe", street: "68 rue Lecourbe", postalCode: "75015", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris_lecourbe/"),
        Store(name: "NOUS anti-gaspi Paris Richard Lenoir", street: "9 boulevard Richard-Lenoir", postalCode: "75011", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-richard-lenoir/"),
        Store(name: "NOUS anti-gaspi Paris Bagnolet", street: "18 rue de Bagnolet", postalCode: "75020", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-bagnolet/"),
        Store(name: "NOUS anti-gaspi Paris Général Leclerc", street: "46 avenue du Général Leclerc", postalCode: "75014", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-general-leclerc/"),
        Store(name: "NOUS anti-gaspi Paris Vaugirard", street: "282 rue de Vaugirard", postalCode: "75015", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-vaugirard/"),
        Store(name: "NOUS anti-gaspi Paris Avenue de Clichy", street: "95 avenue de Clichy", postalCode: "75017", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-avenue-de-clichy/"),
        Store(name: "NOUS anti-gaspi Paris Pyrénées", street: "51 rue des Pyrénées", postalCode: "75020", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-pyrenees/"),
        Store(name: "NOUS anti-gaspi Paris Poissonnière", street: "44 rue du Faubourg Poissonnière", postalCode: "75010", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-poissonniere/"),
        Store(name: "NOUS anti-gaspi Paris Jean Jaurès", street: "137 avenue Jean Jaurès", postalCode: "75019", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-jean-jaures/"),
        Store(name: "NOUS anti-gaspi Paris Saint Maur", street: "126 rue Saint Maur", postalCode: "75011", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-saint-maur/"),
        Store(name: "NOUS anti-gaspi Paris Reuilly", street: "38 rue de Reuilly", postalCode: "75012", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-reuilly/"),
        Store(name: "NOUS anti-gaspi Paris Amsterdam", street: "86 rue d'Amsterdam", postalCode: "75009", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-amsterdam/"),
        Store(name: "NOUS anti-gaspi Paris Place des Fêtes", street: "64 rue du Pré Saint-Gervais", postalCode: "75019", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-place-des-fetes/"),
        Store(name: "NOUS anti-gaspi Paris Montparnasse", street: "11 rue de l'Ouest", postalCode: "75014", city: "Paris", phone: nil, pageURLString: "https://www.nousantigaspi.com/magasins/paris-montparnasse/")
    ]

    // MARK: - Geocoding

    /// Forward-geocodes `NousAntiGaspiProvider.stores` once per app run and
    /// caches the result — 32 sequential `CLGeocoder` calls only ever happen
    /// once (Apple's guidance is one request at a time per geocoder, so this
    /// stays sequential rather than fanning out with a task group). Every
    /// later call to `places(in:)`, from any bounding box, reads the cache.
    private actor GeocodeCache {
        static let shared = GeocodeCache()

        private let geocoder = CLGeocoder()
        private var resolved: [AntiWastePlace]?

        func resolvedPlaces(for stores: [Store]) async -> [AntiWastePlace] {
            if let resolved { return resolved }
            var places: [AntiWastePlace] = []
            for store in stores {
                if let place = await geocode(store) {
                    places.append(place)
                }
            }
            resolved = places
            return places
        }

        private func geocode(_ store: Store) async -> AntiWastePlace? {
            let fullAddress = "\(store.street), \(store.postalCode) \(store.city), France"
            guard let placemark = try? await geocoder.geocodeAddressString(fullAddress).first,
                  let location = placemark.location else { return nil }
            return AntiWastePlace(
                id: "nousantigaspi-\(store.pageURLString)",
                name: store.name,
                category: .antiWasteStore,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                address: store.street,
                city: store.city,
                postalCode: store.postalCode,
                countryCode: "FR",
                description: S.Map.nousAntiGaspiDescription.s,
                websiteURLString: store.pageURLString,
                phone: store.phone,
                source: .nousAntiGaspi,
                sourceID: store.pageURLString,
                sourceURLString: store.pageURLString,
                isVerified: false
            )
        }
    }
}
