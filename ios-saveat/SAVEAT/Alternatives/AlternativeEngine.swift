import Foundation

/// One place a candidate alternative can come from — mirrors
/// `AntiWastePlacesProviding` in `Map/`, scaled down to Phase 1's two
/// real, already-available local sources. No network source exists yet;
/// adding one later only means a new conformer here, exactly like adding
/// a new Map provider.
nonisolated protocol AlternativeSource {
    /// Every product this source currently knows about, unfiltered.
    func candidates() -> [ScannedProduct]
}

/// Every product currently in the household's stock — real, because the
/// household genuinely bought and scanned it.
nonisolated struct InventoryAlternativeSource: AlternativeSource {
    let inventory: [FoodItem]

    nonisolated func candidates() -> [ScannedProduct] {
        inventory.compactMap(\.product)
    }
}

/// Every real product ever scanned successfully, whether or not it was
/// kept in stock (see `AppStore.scanHistory`). Demo-catalogue results
/// never reach this list — filtered out at the source, in
/// `AppStore.logScan(_:)`.
nonisolated struct ScanHistoryAlternativeSource: AlternativeSource {
    let scanHistory: [ScannedProduct]

    nonisolated func candidates() -> [ScannedProduct] {
        scanHistory
    }
}

/// Ranks real, already-known products as alternatives to a scanned one —
/// same multi-source-aggregator shape as `AntiWasteRepository`, scaled to
/// Phase 1's two local sources, with its own dedup instead of
/// `PlaceDeduplicator` (different matching rules: same `FoodCategory` and
/// some name-token overlap, not proximity).
///
/// Never invents a product: every result traces back to something the
/// household actually scanned (kept in stock or not). Never invents a
/// price: `knownPrice(for:)` only ever compares prices this file can
/// prove are real — today that never happens, since every
/// `ScannedProduct.estimatedPrice` in the app is a heuristic default or
/// category guess, never something the household actually paid or a
/// source published. The criterion stays wired for the day a real price
/// source exists, rather than silently trusting `estimatedPrice` as if
/// it were one.
nonisolated enum AlternativeEngine {
    /// A candidate that passed the category/name gate, with its own
    /// transparent `SaveatScore` already computed.
    nonisolated struct Alternative: Identifiable, Hashable, Sendable {
        var product: ScannedProduct
        var score: SaveatScore

        nonisolated var id: String { product.barcode }

        nonisolated static func == (lhs: Alternative, rhs: Alternative) -> Bool {
            lhs.product == rhs.product
        }

        nonisolated func hash(into hasher: inout Hasher) {
            hasher.combine(product)
        }
    }

    /// Every alternative to `product`, best `SaveatScore` first. Never
    /// includes `product` itself, never a duplicate barcode, never a
    /// product outside its `FoodCategory`, and never a product whose name
    /// shares no token with `product`'s own — so a scanned yogurt never
    /// suggests a frozen pizza just because both happen to be "grocery".
    nonisolated static func alternatives(
        to product: ScannedProduct,
        sources: [AlternativeSource]
    ) -> [Alternative] {
        let ownTokens = Set(MealEngine.tokens(product.name))
        let ownCategory = product.suggestedCategory

        var seenBarcodes: Set<String> = [product.barcode]
        var results: [Alternative] = []

        for candidate in sources.flatMap({ $0.candidates() }) {
            guard !seenBarcodes.contains(candidate.barcode) else { continue }
            guard candidate.suggestedCategory == ownCategory else { continue }
            let candidateTokens = Set(MealEngine.tokens(candidate.name))
            guard !ownTokens.isEmpty, !candidateTokens.isDisjoint(with: ownTokens) else { continue }

            seenBarcodes.insert(candidate.barcode)
            results.append(Alternative(product: candidate, score: SaveatScore.evaluate(candidate)))
        }

        return results.sorted { lhs, rhs in
            if lhs.score.value != rhs.score.value { return lhs.score.value > rhs.score.value }
            switch (knownPrice(for: lhs.product), knownPrice(for: rhs.product)) {
            case let (.some(left), .some(right)): return left < right
            default: return false
            }
        }
    }

    /// A price genuinely known for this product — as opposed to
    /// `ScannedProduct.estimatedPrice`, which is always a heuristic
    /// default or category guess, never something the household paid or
    /// a source published. Always `nil` today; this is the single place a
    /// future real price source would plug in, rather than silently
    /// trusting `estimatedPrice` as if it were one.
    private nonisolated static func knownPrice(for product: ScannedProduct) -> Double? {
        nil
    }
}
