import Foundation

/// Real épiceries solidaires in Mulhouse, from Mulhouse Alsace Agglomération's
/// own open dataset on data.gouv.fr — "Epiceries Solidaires sur Mulhouse"
/// (https://www.data.gouv.fr/fr/datasets/epiceries-solidaires-sur-mulhouse/,
/// Licence Ouverte 2.0 / Etalab, last updated 27 May 2026 at the time this
/// was written).
///
/// Pilot provider for the data.gouv.fr strategy (§ Partie A of the map
/// sources plan) — validates that a real, structured, geolocated municipal
/// open-data source can feed `.solidarityGrocery`, the one category that
/// neither OpenStreetMap nor ADEME could populate. Coordinates below are
/// copied verbatim from the source's own `geo_point_2d` field (full
/// precision) — never geocoded, since the dataset already publishes exact
/// lat/lon.
///
/// The source dataset has **no postal code field** — only `code_insee`
/// (68224 for every record, Mulhouse's own INSEE commune code) and a street
/// address. `city` and `department` below are derived from that INSEE code
/// (a real, verifiable administrative fact, not a guess); `postalCode` is
/// left empty rather than invented, mirroring how `OpenStreetMapProvider`
/// already handles a source that doesn't publish one.
nonisolated struct MulhouseOpenDataProvider: AntiWastePlacesProviding {
    nonisolated var supportedCountries: ProviderCountryScope { .countries(["FR"]) }

    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        Self.stores.compactMap { store in
            guard (bbox.minLatitude...bbox.maxLatitude).contains(store.latitude),
                  (bbox.minLongitude...bbox.maxLongitude).contains(store.longitude)
            else { return nil }
            return Self.place(from: store)
        }
    }

    // MARK: - Seed data

    private struct Store {
        let id: String
        let name: String
        let street: String
        let latitude: Double
        let longitude: Double
        let phone: String
    }

    /// Snapshot taken from the dataset's JSON export, September 2026:
    /// https://data.mulhouse-alsace.fr/api/explore/v2.1/catalog/datasets/68224_localisation_caracteristiques_epicerie_solidaire/exports/json
    private static let stores: [Store] = [
        Store(
            id: "afp-caserne-solidaire",
            name: "AFP La Caserne Solidaire",
            street: "2 rue de Bennwihr",
            latitude: 47.7722862254939,
            longitude: 7.32206020469555,
            phone: "03 89 51 38 80"
        ),
        Store(
            id: "caritas-marche-solidaire-des-collines",
            name: "CARITAS Marché Solidaire des Collines",
            street: "6 rue Pierre Loti",
            latitude: 47.734967850451476,
            longitude: 7.299974580446159,
            phone: "09 77 72 77 84"
        ),
        Store(
            id: "caritas-espace-drouot",
            name: "CARITAS - Espace Caritas Drouot",
            street: "1 rue de Bretagne",
            latitude: 47.76088658453559,
            longitude: 7.36247619259485,
            phone: "03 89 31 85 40"
        ),
        Store(
            id: "armee-du-salut-essentiel",
            name: "Armée du Salut - Épicerie solidaire l'Essentiel",
            street: "18 avenue D.M.C.",
            latitude: 47.751728976171286,
            longitude: 7.310293311644673,
            phone: "03 68 70 81 81"
        ),
        Store(
            id: "croix-rouge-mulhouse",
            name: "Croix-Rouge française - Unité locale de Mulhouse",
            street: "83 rue Koechlin",
            latitude: 47.755057143402496,
            longitude: 7.3346804132337455,
            phone: "06 81 98 42 54"
        )
    ]

    // MARK: - Mapping

    private static func place(from store: Store) -> AntiWastePlace {
        AntiWastePlace(
            id: "datagouv-mulhouse-\(store.id)",
            name: store.name,
            category: .solidarityGrocery,
            latitude: store.latitude,
            longitude: store.longitude,
            address: store.street,
            city: "Mulhouse",
            postalCode: "",
            // Commune INSEE 68224 (Mulhouse) → département 68 (Haut-Rhin),
            // région Grand Est — real administrative facts tied to this
            // dataset's own commune code, not derived from a postal code
            // (the source has none) and not guessed.
            department: "68",
            countryCode: "FR",
            region: "Grand Est",
            description: S.Map.solidarityGroceryDescription.s,
            phone: store.phone,
            source: .dataGouvFr,
            sourceID: store.id,
            sourceURLString: "https://www.data.gouv.fr/fr/datasets/epiceries-solidaires-sur-mulhouse/",
            license: "Licence Ouverte 2.0 (Etalab) — Mulhouse Alsace Agglomération",
            isVerified: false
        )
    }
}
