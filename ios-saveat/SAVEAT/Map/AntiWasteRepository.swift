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

/// Anything that can list SAVEAT Local places for a given map area. The map
/// talks only to this protocol, never to a concrete data source — swapping
/// or adding a provider (OpenStreetMap, ADEME, a future SAVEAT backend…)
/// never touches `AntiWasteMapView` or its view model (§18).
protocol AntiWastePlacesProviding: Sendable {
    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace]
}

/// Single access point the Map module talks to.
///
/// Fans out to every configured provider in parallel, then deduplicates
/// (§ Étape 4) before handing places back. Adding a new source is a one-line
/// change to `shared` below — nothing else in `Map/` moves.
nonisolated struct AntiWasteRepository: Sendable {
    private let providers: [AntiWastePlacesProviding]

    init(providers: [AntiWastePlacesProviding]) {
        self.providers = providers
    }

    /// Real open-data sources. `ADEMEProvider` is implemented and verified
    /// against the live API but deliberately **not** included here yet —
    /// live testing during Phase 3 found zero genuine food-solidarity
    /// matches for its keyword list across a large region, so shipping it
    /// active would add API calls without adding real places. See
    /// `ADEMEProvider`'s doc comment and the Phase 3 report.
    static let shared = AntiWasteRepository(providers: [
        OpenStreetMapProvider()
    ])

    /// Fictional data only — for SwiftUI Previews and offline development.
    static let preview = AntiWasteRepository(providers: [MockAntiWastePlacesService()])

    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        let padded = bbox.padded()
        let merged = await withTaskGroup(of: [AntiWastePlace].self) { group -> [AntiWastePlace] in
            for provider in providers {
                group.addTask { await provider.places(in: padded) }
            }
            var all: [AntiWastePlace] = []
            for await batch in group { all.append(contentsOf: batch) }
            return all
        }
        return PlaceDeduplicator.deduplicate(merged)
    }
}
