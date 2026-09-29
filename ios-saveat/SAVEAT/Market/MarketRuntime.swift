import Foundation

/// Thread-safe holder for the market currently in use.
///
/// Same pattern as `LanguageRuntime`: lives outside SwiftUI so `nonisolated`
/// formatters (`Units`, `Money`, `Format`) can read it from any thread.
/// Resolved lazily on first read, so it is already correct before any
/// view or store exists.
nonisolated enum MarketRuntime {
    /// Written only when the user picks a country by hand. A brand-new key:
    /// nothing existing is read, rewritten or migrated.
    nonisolated static let overrideStorageKey = "saveat.market.override.v1"

    private static let lock = NSLock()
    nonisolated(unsafe) private static var value: MarketContext = MarketContext.resolve(
        manualCountryCode: UserDefaults.standard.string(forKey: overrideStorageKey),
        deviceRegionCode: Locale.current.region?.identifier
    )

    nonisolated static var current: MarketContext {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    nonisolated static func set(_ market: MarketContext) {
        lock.lock()
        value = market
        lock.unlock()
    }
}
