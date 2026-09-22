import Foundation

/// A geographic search area, in plain degrees — deliberately not `MKCoordinateRegion`
/// so every provider (and every unit test) stays free of a MapKit import.
nonisolated struct GeoBoundingBox: Sendable, Equatable {
    var minLatitude: Double
    var maxLatitude: Double
    var minLongitude: Double
    var maxLongitude: Double

    nonisolated var centerLatitude: Double { (minLatitude + maxLatitude) / 2 }
    nonisolated var centerLongitude: Double { (minLongitude + maxLongitude) / 2 }

    /// True when `other` is comfortably inside this box — used to skip a
    /// refetch when the visible map region only moved a little (§ "ne pas
    /// surcharger l'API Overpass").
    nonisolated func generouslyContains(_ other: GeoBoundingBox) -> Bool {
        let latPad = (maxLatitude - minLatitude) * 0.15
        let lonPad = (maxLongitude - minLongitude) * 0.15
        return other.minLatitude >= minLatitude + latPad
            && other.maxLatitude <= maxLatitude - latPad
            && other.minLongitude >= minLongitude + lonPad
            && other.maxLongitude <= maxLongitude - lonPad
    }

    /// Widened by a fixed margin so a provider fetches a bit more than the
    /// visible viewport — panning slightly then doesn't always trigger a
    /// brand-new network call.
    nonisolated func padded(by factor: Double = 0.3) -> GeoBoundingBox {
        let latPad = (maxLatitude - minLatitude) * factor
        let lonPad = (maxLongitude - minLongitude) * factor
        return GeoBoundingBox(
            minLatitude: minLatitude - latPad,
            maxLatitude: maxLatitude + latPad,
            minLongitude: minLongitude - lonPad,
            maxLongitude: maxLongitude + lonPad
        )
    }
}

/// Which territory a provider's data actually covers.
///
/// Kept as an explicit type rather than a bare `Set<String>` so "no
/// restriction" (OpenStreetMap) and "this exact list of ISO 3166-1 alpha-2
/// codes" (ADEME → `["FR"]`) can never be confused with each other.
nonisolated enum ProviderCountryScope: Sendable, Equatable {
    case worldwide
    case countries(Set<String>)

    /// `true` when this provider should be asked for places in `countryCode`.
    /// A `nil` code (geocoding failed or hasn't resolved yet) only reaches
    /// worldwide providers — a country-scoped one would rather stay silent
    /// than risk showing a French dataset over Berlin because geocoding blipped.
    nonisolated func supports(_ countryCode: String?) -> Bool {
        switch self {
        case .worldwide:
            return true
        case .countries(let codes):
            guard let countryCode else { return false }
            return codes.contains(countryCode)
        }
    }
}

/// Anything that can list SAVEAT Local places for a given map area. The map
/// talks only to this protocol, never to a concrete data source — swapping
/// or adding a provider (OpenStreetMap, ADEME, a future SAVEAT backend…)
/// never touches `AntiWasteMapView` or its view model (§18).
protocol AntiWastePlacesProviding: Sendable {
    /// Territory this provider's data actually covers. Defaults to
    /// `.worldwide` below — a provider only overrides this when its data
    /// source is genuinely national (see `ADEMEProvider`).
    nonisolated var supportedCountries: ProviderCountryScope { get }
    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace]
}

extension AntiWastePlacesProviding {
    nonisolated var supportedCountries: ProviderCountryScope { .worldwide }
}

/// Single access point the Map module talks to.
///
/// Resolves which country the visible area is in, keeps only the providers
/// that cover it, fans out to those in parallel, then deduplicates
/// (§ Étape 4) before handing places back. Adding a new source is a one-line
/// change to `shared` below — nothing else in `Map/` moves, and a provider
/// scoped to one country never fires outside it (§ architecture internationale).
nonisolated struct AntiWasteRepository: Sendable {
    private let providers: [AntiWastePlacesProviding]
    private let countryResolver: CountryDataProviderResolver

    init(providers: [AntiWastePlacesProviding], countryResolver: CountryDataProviderResolver = .shared) {
        self.providers = providers
        self.countryResolver = countryResolver
    }

    /// Real open-data sources. `ADEMEProvider` is implemented and verified
    /// against the live API but deliberately **not** included here yet —
    /// live testing during Phase 3 found zero genuine food-solidarity
    /// matches for its keyword list across a large region, so shipping it
    /// active would add API calls without adding real places. See
    /// `ADEMEProvider`'s doc comment and the Phase 3 report.
    ///
    /// `NousAntiGaspiProvider` is a curated, France-only snapshot of a real
    /// anti-waste grocery chain's own published store addresses — added to
    /// fill in where `OpenStreetMapProvider`'s crowd-sourced tagging hasn't
    /// reached yet. See that provider's doc comment for how it was sourced
    /// and why it's still not a "SAVEAT partner" record.
    ///
    /// DÉSACTIVÉ ci-dessous (retiré de `shared`, pas supprimé) le 22/09/2026,
    /// le temps qu'un accord officiel avec l'enseigne NOUS Anti-Gaspi soit
    /// confirmé — ces adresses restent un snapshot public non contractuel,
    /// pas un partenariat SAVEAT. Réactiver = décommenter la ligne
    /// `NousAntiGaspiProvider()` juste en dessous, rien d'autre à toucher.
    ///
    /// `SAVEATPartnerProvider` surfaces the one real SAVEAT PRO merchant
    /// signed up on this device, if any — see its own doc comment for why
    /// that stays a single-device, no-backend limitation for now.
    ///
    /// `MulhouseOpenDataProvider` is the pilot for a new source family —
    /// municipal/territorial open data published on data.gouv.fr. Only one
    /// city today (5 real épiceries solidaires), added to validate the whole
    /// pipeline (model, dedup, attribution) before scaling to more cities —
    /// see that provider's doc comment and the map-sources import report.
    ///
    /// `LiegeOpenDataProvider` is the Belgian pilot for the same idea, on
    /// Open Data Wallonie-Bruxelles (ODWB) instead of data.gouv.fr — see
    /// that provider's doc comment for sourcing details and the 2 excluded
    /// non-operational records.
    ///
    /// No other national provider is wired in as of the international
    /// architecture pass — the research phase found no food-donation open
    /// dataset for Germany, Spain, Italy, Brazil or the USA that is both
    /// national in scope and clearly licensed for this use. See that
    /// report. `OpenStreetMapProvider` alone already covers every country
    /// (`.worldwide`), which is why the map works the same in Bordeaux,
    /// Berlin or São Paulo today.
    static let shared = AntiWasteRepository(providers: [
        OpenStreetMapProvider(),
        // NousAntiGaspiProvider(), // désactivé le 22/09/2026 — voir commentaire ci-dessus, en attente d'accord officiel avec l'enseigne
        MulhouseOpenDataProvider(),
        LiegeOpenDataProvider(),
        SAVEATPartnerProvider()
    ])

    /// Fictional data only — for SwiftUI Previews and offline development.
    static let preview = AntiWasteRepository(providers: [MockAntiWastePlacesService()])

    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        let padded = bbox.padded()
        // Reverse-geocoding costs a real round-trip and Apple rate-limits it,
        // so it only runs when a country-scoped provider is actually in play
        // — today that's nobody (see `shared` below), so this stays free.
        let hasCountryScopedProvider = providers.contains {
            if case .countries = $0.supportedCountries { true } else { false }
        }
        let countryCode = hasCountryScopedProvider ? await countryResolver.countryCode(for: padded) : nil
        let activeProviders = providers.filter { $0.supportedCountries.supports(countryCode) }
        let merged = await withTaskGroup(of: [AntiWastePlace].self) { group -> [AntiWastePlace] in
            for provider in activeProviders {
                group.addTask { await provider.places(in: padded) }
            }
            var all: [AntiWastePlace] = []
            for await batch in group { all.append(contentsOf: batch) }
            return all
        }
        return PlaceDeduplicator.deduplicate(merged)
    }
}
