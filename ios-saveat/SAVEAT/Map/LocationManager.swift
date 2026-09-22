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
    /// True after a *persistent* failure — Location Services switched off at
    /// the system level (Réglages > Confidentialité > Service de
    /// localisation), not just this app's own permission. `authorizationStatus`
    /// can still read `.authorizedWhenInUse` in this case (the app-level grant
    /// never changed), so this is the only signal the map has for it (§ audit
    /// messages de localisation). Cleared the moment a real fix arrives.
    private(set) var hasSystemLocationFailure = false

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
            self?.hasSystemLocationFailure = false
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Most failures here are transient (`.locationUnknown` — no fix yet,
        // signal loss) and fire constantly during ordinary GPS acquisition;
        // surfacing those would flicker an error on and off for no reason,
        // so they stay silent exactly as before. `.denied` from THIS
        // delegate method specifically means Location Services are off at
        // the system level — distinct from `authorizationStatus`, which
        // only tracks this app's own permission and won't reflect that.
        guard let clError = error as? CLError, clError.code == .denied else { return }
        Task { @MainActor [weak self] in
            self?.hasSystemLocationFailure = true
        }
    }
}
