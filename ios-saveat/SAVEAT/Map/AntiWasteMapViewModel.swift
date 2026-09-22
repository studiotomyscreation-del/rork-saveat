import CoreLocation
import Foundation
import Observation

/// State and logic for the SAVEAT Local map. Independent of `AppStore`: the
/// map has its own data source (`AntiWasteRepository`) and its own local
/// favorites, exactly like the rest of the Map module is meant to stay
/// swappable without touching the household stock.
@Observable
@MainActor
final class AntiWasteMapViewModel {
    private enum Keys {
        static let favorites = "saveat.map.favorites.v1"
    }

    /// Paris — used only as a map center before a real position is known.
    static let franceFallbackCenter = CLLocationCoordinate2D(latitude: 46.8, longitude: 2.4)

    private(set) var places: [AntiWastePlace] = []
    private(set) var isLoading = false

    var selectedCategory: AntiWasteCategory?
    var radiusKm: Double = 10
    var selectedPlace: AntiWastePlace?
    private(set) var favoriteIDs: Set<String>

    let locationManager: LocationManager
    private let repository: AntiWasteRepository

    private var lastFetchedBBox: GeoBoundingBox?
    private var loadTask: Task<Void, Never>?

    init(repository: AntiWasteRepository = .shared, locationManager: LocationManager = LocationManager()) {
        self.repository = repository
        self.locationManager = locationManager
        if let data = UserDefaults.standard.data(forKey: Keys.favorites),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteIDs = decoded
        } else {
            favoriteIDs = []
        }
    }

    /// Loads places for the visible map area, skipping the network call
    /// entirely when the new area is comfortably inside the last one fetched
    /// (panning a little must not refire OpenStreetMap/ADEME on every frame).
    func load(in bbox: GeoBoundingBox, force: Bool = false) async {
        if !force, let lastFetchedBBox, lastFetchedBBox.generouslyContains(bbox) {
            return
        }
        isLoading = true
        places = await repository.places(in: bbox)
        lastFetchedBBox = bbox
        isLoading = false
    }

    /// Debounced entry point for map-camera changes: cancels any load still
    /// waiting and starts a fresh one after a short pause, so a quick pan
    /// gesture triggers one network round-trip, not one per intermediate frame.
    func scheduleLoad(in bbox: GeoBoundingBox) {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await self?.load(in: bbox)
        }
    }

    // MARK: - Filtering

    /// True right after permission is granted but before the first real GPS
    /// fix arrives — a normal few-second window, not an error. Distinct from
    /// "not authorized" (`.denied`/`.restricted`/`.notDetermined`), where
    /// falling back to Paris is the deliberate "browse the map of France"
    /// behaviour and stays untouched (§ audit messages de localisation:
    /// without this check, this window silently reused the Paris fallback
    /// too, showing "no place nearby" to someone who just hadn't gotten a
    /// fix yet).
    var isResolvingLocation: Bool {
        locationManager.status == .authorized && locationManager.userLocation == nil
    }

    var filteredPlaces: [AntiWastePlace] {
        guard !isResolvingLocation else { return [] }
        return places
            .filter { selectedCategory == nil || $0.category == selectedCategory }
            .filter { distanceKm(to: $0) <= radiusKm }
            .sorted { distanceKm(to: $0) < distanceKm(to: $1) }
    }

    /// Categories actually present on the map right now. Drives the filter
    /// sheet so a category with no real data today (baskets, partner deals —
    /// see the Phase 3 report) never appears as a selectable, empty promise.
    var availableCategories: [AntiWasteCategory] {
        let present = Set(places.map(\.category))
        return AntiWasteCategory.visibleCases.filter { present.contains($0) }
    }

    /// Distance from the current (or fallback) position, in kilometres.
    func distanceKm(to place: AntiWastePlace) -> Double {
        let origin = locationManager.userLocation
            ?? CLLocation(latitude: Self.franceFallbackCenter.latitude, longitude: Self.franceFallbackCenter.longitude)
        let destination = CLLocation(latitude: place.latitude, longitude: place.longitude)
        return origin.distance(from: destination) / 1000
    }

    func distanceText(to place: AntiWastePlace) -> String {
        Units.distance(kilometers: distanceKm(to: place))
    }

    // MARK: - Favorites

    func isFavorite(_ place: AntiWastePlace) -> Bool {
        favoriteIDs.contains(place.id)
    }

    func toggleFavorite(_ place: AntiWastePlace) {
        if favoriteIDs.contains(place.id) {
            favoriteIDs.remove(place.id)
        } else {
            favoriteIDs.insert(place.id)
        }
        guard let data = try? JSONEncoder().encode(favoriteIDs) else { return }
        UserDefaults.standard.set(data, forKey: Keys.favorites)
    }
}
