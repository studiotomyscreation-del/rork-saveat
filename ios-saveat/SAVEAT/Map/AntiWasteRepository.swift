import Foundation

/// Anything that can list SAVEAT Local places. The map talks only to this
/// protocol, never to a concrete data source — swapping the provider (Open
/// Data, a partner API, the future SAVEAT backend, Supabase, Firebase…)
/// never touches `AntiWasteMapView` or its view model (§18).
protocol AntiWastePlacesProviding: Sendable {
    func places() async -> [AntiWastePlace]
}

/// Single access point the Map module talks to.
///
/// Today its only provider is `MockAntiWastePlacesService`. Connecting a real
/// source later is a one-line change here — nothing else in `Map/` moves.
nonisolated struct AntiWasteRepository: Sendable {
    private let provider: AntiWastePlacesProviding

    init(provider: AntiWastePlacesProviding) {
        self.provider = provider
    }

    static let shared = AntiWasteRepository(provider: MockAntiWastePlacesService())

    func places() async -> [AntiWastePlace] {
        await provider.places()
    }
}
