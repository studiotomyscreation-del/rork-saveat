import Foundation

/// The list of markets SAVEAT lets a household pick by hand in Settings —
/// kept separate from `MarketStore` (which only ever *reads* this list, it
/// never owns it) so a future source (remote config, a launch-phase flag,
/// a per-country feature gate) can replace `supportedCountryCodes` without
/// touching `MarketStore` or any of its callers.
///
/// The four launch markets first, then the countries SAVEAT already has
/// languages or data sources for. Adding a market here is a deliberate
/// product decision, never done by inference from code alone.
nonisolated enum MarketCatalog {
    static let supportedCountryCodes: [String] = ["FR", "US", "CA", "GB", "BE", "CH", "ES", "IT", "DE", "BR"]
}
