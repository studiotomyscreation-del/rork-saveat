import CoreLocation
import Observation

/// Thin wrapper around `CLLocationManager` for the SAVEAT Local map.
///
/// Never requests permission on its own — the map screen asks explicitly,
/// through a visible button, the same careful timing already used for
/// notifications in `NotificationService`. Delegate callbacks are
/// `nonisolated` and hop to the main actor, mirroring `BarcodeCameraService`.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    nonisolated enum Status: Sendable {
        case notDetermined
        case denied
        case restricted
        case authorized
    }

    private(set) var status: Status = .notDetermined
    private(set) var userLocation: CLLocation?
    /// Bumped on every location update. `CLLocation` isn't `Equatable`, so
    /// views observe this plain counter with `.onChange(of:)` instead of
    /// `userLocation` directly.
    private(set) var updateCount = 0

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        status = Self.status(from: manager.authorizationStatus)
    }

    /// Shows the system prompt. Call only from an explicit user action.
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard status == .authorized else { return }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    private nonisolated static func status(from authorization: CLAuthorizationStatus) -> Status {
        switch authorization {
        case .authorizedWhenInUse, .authorizedAlways: .authorized
        case .denied: .denied
        case .restricted: .restricted
        case .notDetermined: .notDetermined
        @unknown default: .notDetermined
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = Self.status(from: manager.authorizationStatus)
        Task { @MainActor [weak self] in
            self?.status = newStatus
            if newStatus == .authorized {
                self?.startUpdating()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor [weak self] in
            self?.userLocation = last
            self?.updateCount += 1
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // A transient failure (no fix yet, signal loss) is never surfaced as
        // an error to the user — the map simply keeps its last known state.
    }
}
