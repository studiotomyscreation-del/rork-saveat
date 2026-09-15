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

    func load() async {
        isLoading = true
        places = await repository.places()
        isLoading = false
    }

    // MARK: - Filtering

    var filteredPlaces: [AntiWastePlace] {
        places
            .filter { selectedCategory == nil || $0.category == selectedCategory }
            .filter { distanceKm(to: $0) <= radiusKm }
            .sorted { distanceKm(to: $0) < distanceKm(to: $1) }
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
