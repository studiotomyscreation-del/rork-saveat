import Foundation

/// A location shown on the map: either one real place, or a cluster of
/// several places grouped together because they'd render on top of each
/// other at the current zoom level.
///
/// Purely a SwiftUI-side concept — never touches MapKit's own clustering,
/// which only auto-clusters `Marker` content, not a custom `Annotation`
/// like `AntiWasteMapView`'s pin (no public API exists to give a custom
/// `Annotation` a clustering identifier in SwiftUI's `Map`).
nonisolated enum MapCluster: Identifiable, Hashable, Sendable {
    case single(AntiWastePlace)
    case group(id: String, latitude: Double, longitude: Double, places: [AntiWastePlace])

    nonisolated var id: String {
        switch self {
        case .single(let place): place.id
        case .group(let id, _, _, _): id
        }
    }

    nonisolated var latitude: Double {
        switch self {
        case .single(let place): place.latitude
        case .group(_, let latitude, _, _): latitude
        }
    }

    nonisolated var longitude: Double {
        switch self {
        case .single(let place): place.longitude
        case .group(_, _, let longitude, _): longitude
        }
    }
}

/// Groups nearby places into `MapCluster`s on a simple lat/lon grid sized
/// to the visible map span — coarser when zoomed out (a whole city
/// collapses to a few bubbles), finer when zoomed in, and disabled below
/// `minSpanToCluster` so pins close enough to walk between (the Paris
/// density seen in the RNA duplicate audit) always show individually.
nonisolated enum PlaceClusterer {
    /// Below this visible span (in degrees, both axes), clustering is
    /// switched off entirely — roughly a "few streets" zoom level.
    private static let minSpanToCluster: Double = 0.03

    /// How many grid cells fit across the visible span. Higher means
    /// finer clustering (smaller, more numerous groups).
    private static let gridDivisions: Double = 25

    nonisolated static func cluster(
        _ places: [AntiWastePlace],
        visibleLatitudeDelta: Double,
        visibleLongitudeDelta: Double
    ) -> [MapCluster] {
        guard visibleLatitudeDelta > minSpanToCluster || visibleLongitudeDelta > minSpanToCluster else {
            return places.map { .single($0) }
        }

        let latCell = max(visibleLatitudeDelta / gridDivisions, .leastNormalMagnitude)
        let lonCell = max(visibleLongitudeDelta / gridDivisions, .leastNormalMagnitude)

        var buckets: [String: [AntiWastePlace]] = [:]
        for place in places {
            let key = "\(Int((place.latitude / latCell).rounded()))_\(Int((place.longitude / lonCell).rounded()))"
            buckets[key, default: []].append(place)
        }

        return buckets.flatMap { key, group -> [MapCluster] in
            guard group.count > 1 else { return [.single(group[0])] }
            let avgLatitude = group.map(\.latitude).reduce(0, +) / Double(group.count)
            let avgLongitude = group.map(\.longitude).reduce(0, +) / Double(group.count)
            return [.group(id: "cluster-\(key)", latitude: avgLatitude, longitude: avgLongitude, places: group)]
        }
    }
}
