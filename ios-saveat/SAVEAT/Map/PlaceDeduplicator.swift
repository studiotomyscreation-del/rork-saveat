import Foundation

/// Merges places coming back from several providers so the same real-world
/// address is never shown twice just because OpenStreetMap and ADEME both
/// happen to know about it (§ Étape 4).
///
/// Two records are treated as the same place when they sit within about
/// 60 m of each other **and** either share a normalized name or share a
/// postal code together with a name that starts the same way — coordinates
/// alone are not enough (two different shops can share a building), and
/// name alone is not enough either (a chain can have several branches).
nonisolated enum PlaceDeduplicator {
    /// Meters below which two points are considered "the same address".
    private static let sameLocationRadiusMeters: Double = 60

    /// Source priority when two records describe the same place — the
    /// higher-priority one is kept, the other dropped. A future SAVEAT/partner
    /// record always wins over open data, since it is directly maintained by
    /// SAVEAT; between the two open sources, OpenStreetMap wins because its
    /// tags map directly onto a SAVEAT category, while the ADEME match is a
    /// best-effort keyword match (see `ADEMEProvider`).
    private static func priority(_ source: DataSource) -> Int {
        switch source {
        case .partner: 0
        case .saveat: 1
        case .openStreetMap: 2
        case .ademe: 3
        }
    }

    nonisolated static func deduplicate(_ places: [AntiWastePlace]) -> [AntiWastePlace] {
        let ordered = places.sorted { priority($0.source) < priority($1.source) }
        var kept: [AntiWastePlace] = []

        for place in ordered {
            let isDuplicate = kept.contains { existing in
                isSamePlace(existing, place)
            }
            if !isDuplicate {
                kept.append(place)
            }
        }
        return kept
    }

    private nonisolated static func isSamePlace(_ a: AntiWastePlace, _ b: AntiWastePlace) -> Bool {
        guard distanceMeters(a, b) <= sameLocationRadiusMeters else { return false }

        let nameA = MealEngine.normalize(a.name)
        let nameB = MealEngine.normalize(b.name)
        if !nameA.isEmpty, !nameB.isEmpty, nameA == nameB { return true }

        let samePostalCode = !a.postalCode.isEmpty && a.postalCode == b.postalCode
        let namesStartTheSame = !nameA.isEmpty && !nameB.isEmpty
            && (nameA.hasPrefix(nameB.prefix(6)) || nameB.hasPrefix(nameA.prefix(6)))
        return samePostalCode && namesStartTheSame
    }

    /// Straight-line distance between two places, in meters (equirectangular
    /// approximation — plenty accurate at this scale, no CoreLocation needed).
    private nonisolated static func distanceMeters(_ a: AntiWastePlace, _ b: AntiWastePlace) -> Double {
        let earthRadius = 6_371_000.0
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180

        let sinLat = sin(dLat / 2)
        let sinLon = sin(dLon / 2)
        let h = sinLat * sinLat + cos(lat1) * cos(lat2) * sinLon * sinLon
        return 2 * earthRadius * asin(min(1, sqrt(h)))
    }
}
