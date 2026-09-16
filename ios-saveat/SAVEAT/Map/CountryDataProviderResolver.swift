import CoreLocation
import Foundation

/// Resolves which country a map area is in, so `AntiWasteRepository` can
/// keep only the providers that actually cover it.
///
/// Deliberately geography-based, never language-based: a French-speaking
/// reader browsing New York must get American sources, not French ones
/// (§ "le choix des providers ne doit pas dépendre de la langue"). Country
/// detection comes from reverse-geocoding the visible area itself.
///
/// Uses `CLGeocoder`, Apple's own service — no third-party geocoding API key,
/// no new license to track. Apple asks clients not to hammer it, so results
/// are cached per rounded grid cell: panning inside the same city/country
/// never re-geocodes.
actor CountryDataProviderResolver {
    static let shared = CountryDataProviderResolver()

    private let geocoder = CLGeocoder()
    /// ISO 3166-1 alpha-2 code, or `nil` when geocoding found no country
    /// (open ocean, or the lookup failed) — cached either way so a bad
    /// network moment doesn't retry on every pan.
    private var cache: [GridCell: String?] = [:]

    /// ~1° of latitude/longitude (well under 150 km at the equator) — coarse
    /// enough that a country only needs resolving once per region, precise
    /// enough that no cell realistically straddles more than one country's
    /// interior (a border city may still flip between neighbours right at
    /// the line, which only ever affects which *extra* national source is
    /// consulted — `OpenStreetMapProvider` covers it worldwide regardless).
    private struct GridCell: Hashable {
        let lat: Int
        let lon: Int

        init(latitude: Double, longitude: Double) {
            lat = Int(latitude.rounded())
            lon = Int(longitude.rounded())
        }
    }

    /// The ISO 3166-1 alpha-2 country code covering `bbox`'s center, or
    /// `nil` when it can't be determined — callers treat `nil` as "match
    /// worldwide providers only", never as an error to surface.
    func countryCode(for bbox: GeoBoundingBox) async -> String? {
        let cell = GridCell(latitude: bbox.centerLatitude, longitude: bbox.centerLongitude)
        if let cached = cache[cell] {
            return cached
        }

        let location = CLLocation(latitude: bbox.centerLatitude, longitude: bbox.centerLongitude)
        let code = await Self.reverseGeocode(location, using: geocoder)
        cache[cell] = code
        return code
    }

    private static func reverseGeocode(_ location: CLLocation, using geocoder: CLGeocoder) async -> String? {
        await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                continuation.resume(returning: placemarks?.first?.isoCountryCode)
            }
        }
    }
}
