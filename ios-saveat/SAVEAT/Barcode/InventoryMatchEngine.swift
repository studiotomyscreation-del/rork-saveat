import Foundation

/// What the household already has of a scanned product — certain matches only.
///
/// Built from the real stock: quantities as recorded, locations as recorded,
/// dates only when the user entered one. Nothing is inferred.
nonisolated struct InventoryMatch: Hashable, Sendable {

    /// One stock line carrying the same GTIN.
    nonisolated struct Occurrence: Hashable, Sendable {
        let item: FoodItem
        nonisolated var location: StorageLocation { item.location }
        nonisolated var quantity: Double { item.quantity }
        /// True only when a date is recorded and falls within the Use Soon window.
        nonisolated var isUseSoon: Bool { InventoryMatchEngine.isUseSoon(item) }
    }

    /// Quantity held in one storage location.
    nonisolated struct LocationTotal: Hashable, Sendable {
        let location: StorageLocation
        let quantity: Double
    }

    enum Kind: Hashable, Sendable {
        /// Same canonical GTIN (or the very same scanned digits).
        case exact
    }

    let gtin: NormalizedGTIN
    let kind: Kind
    /// Every matching stock line, in stock order — never only the first.
    let occurrences: [Occurrence]

    nonisolated var totalQuantity: Double {
        occurrences.reduce(0) { $0 + $1.quantity }
    }

    /// Per-location totals, fridge → pantry → freezer.
    nonisolated var byLocation: [LocationTotal] {
        StorageLocation.allCases.compactMap { location in
            let quantity = occurrences
                .filter { $0.location == location }
                .reduce(0) { $0 + $1.quantity }
            return quantity > 0 ? LocationTotal(location: location, quantity: quantity) : nil
        }
    }

    /// Quantity whose recorded date is close (Use Soon window). 0 when no date is known.
    nonisolated var useSoonQuantity: Double {
        occurrences.filter(\.isUseSoon).reduce(0) { $0 + $1.quantity }
    }
}

/// Local, deterministic stock lookup by barcode identity.
///
/// No network, no AI, no external API: a pure function of the scanned
/// `NormalizedGTIN` and the stock already in memory. Stored barcodes are
/// normalised at read time and never rewritten.
///
/// Phase 3 scope: exact / canonically-equivalent GTINs only. No name, brand,
/// category or AI similarity, and no variable-measure (prefix 2 / 02) merging.
nonisolated enum InventoryMatchEngine {

    /// Stock lines holding the same product, or nil when there are none — in
    /// which case the scan flow carries on exactly as before.
    nonisolated static func exactMatch(for gtin: NormalizedGTIN, in inventory: [FoodItem]) -> InventoryMatch? {
        guard !gtin.lookupCode.isEmpty else { return nil }
        let occurrences = inventory
            .filter { item in
                guard item.quantity > 0, let stored = item.gtin else { return false }
                return stored.matches(gtin)
            }
            .map { InventoryMatch.Occurrence(item: $0) }
        guard !occurrences.isEmpty else { return nil }
        return InventoryMatch(gtin: gtin, kind: .exact, occurrences: occurrences)
    }

    /// Convenience for a product coming back from a lookup.
    nonisolated static func exactMatch(for product: ScannedProduct, in inventory: [FoodItem]) -> InventoryMatch? {
        exactMatch(for: product.gtin, in: inventory)
    }

    /// A recorded date within the existing Use Soon thresholds (`ExpiryRules`),
    /// not yet passed. Items without a date are never flagged.
    nonisolated static func isUseSoon(_ item: FoodItem) -> Bool {
        guard item.bestBefore != nil else { return false }
        switch item.status {
        case .plan, .rescue: return true
        case .keep, .reached: return false
        }
    }
}
