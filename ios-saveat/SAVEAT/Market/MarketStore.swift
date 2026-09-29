import Foundation
import Observation

/// Observable face of the market for SwiftUI, with the manual override.
///
/// Changing the market only changes formats and commercial conventions —
/// no food, date, history, preference or subscription is touched.
@Observable
final class MarketStore {
    private(set) var context: MarketContext
    /// `nil` while the app follows the phone's region.
    private(set) var manualCountryCode: String?

    /// Markets offered in Settings: the four launch markets first, then the
    /// countries SAVEAT already has languages or data sources for.
    static let selectableCountries: [String] = ["FR", "US", "CA", "GB", "BE", "CH", "ES", "IT", "DE", "BR"]

    init() {
        let stored = MarketContext.normalized(UserDefaults.standard.string(forKey: MarketRuntime.overrideStorageKey))
        manualCountryCode = stored
        let resolved = MarketContext.resolve(
            manualCountryCode: stored,
            deviceRegionCode: Locale.current.region?.identifier
        )
        context = resolved
        MarketRuntime.set(resolved)
    }

    /// The phone's own country, or the fallback when it reports none.
    var deviceCountryCode: String {
        MarketContext.normalized(Locale.current.region?.identifier) ?? MarketContext.fallbackCountryCode
    }

    var isFollowingDevice: Bool { manualCountryCode == nil }

    /// Records a manual choice; `nil` goes back to following the phone.
    func select(countryCode: String?) {
        let code = MarketContext.normalized(countryCode)
        guard code != manualCountryCode else { return }
        manualCountryCode = code
        if let code {
            UserDefaults.standard.set(code, forKey: MarketRuntime.overrideStorageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: MarketRuntime.overrideStorageKey)
        }
        let resolved = MarketContext.resolve(
            manualCountryCode: code,
            deviceRegionCode: Locale.current.region?.identifier
        )
        context = resolved
        MarketRuntime.set(resolved)
    }

    /// Flag emoji built from the ISO code's regional-indicator letters.
    static func flag(for countryCode: String) -> String {
        countryCode.unicodeScalars
            .compactMap { UnicodeScalar(127_397 + $0.value) }
            .map(String.init)
            .joined()
    }
}
