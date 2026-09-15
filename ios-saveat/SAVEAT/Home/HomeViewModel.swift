import CoreLocation
import Foundation
import Observation

/// The one thing the SAVEAT V2 Home screen (`NewHomeView`) needs that
/// `AppStore` doesn't already track: a live "what's nearby" preview from the
/// SAVEAT Local map data (§18 — same `AntiWasteRepository`, independent of
/// the map's own view model). Everything else Home shows — stock, savings,
/// recipe suggestions — is read straight from `AppStore` in the view itself,
/// exactly like the existing `HomeView` already does.
@Observable
@MainActor
final class HomeViewModel {
    private let repository: AntiWasteRepository
    let locationManager: LocationManager

    private(set) var nearbyPlaces: [AntiWastePlace] = []
    private(set) var isLoadingNearby = false
    private var hasLoadedNearby = false

    init(repository: AntiWasteRepository = .shared, locationManager: LocationManager = LocationManager()) {
        self.repository = repository
        self.locationManager = locationManager
    }

    /// Loads a small radius around the current (or France-wide fallback)
    /// position, once per screen lifetime — Home is a summary, not the map
    /// itself, so it never needs to refetch on every appearance.
    func loadNearbyIfNeeded() async {
        guard !hasLoadedNearby else { return }
        hasLoadedNearby = true
        isLoadingNearby = true

        let center = locationManager.userLocation?.coordinate ?? AntiWasteMapViewModel.franceFallbackCenter
        let bbox = GeoBoundingBox(
            minLatitude: center.latitude - 0.09,
            maxLatitude: center.latitude + 0.09,
            minLongitude: center.longitude - 0.09,
            maxLongitude: center.longitude + 0.09
        )
        nearbyPlaces = await repository.places(in: bbox)
        isLoadingNearby = false
    }
}
