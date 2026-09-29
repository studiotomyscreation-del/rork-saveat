import Foundation

extension ScannedProduct {
    /// Barcode identity, normalised at read time. `barcode` itself is never rewritten.
    nonisolated var gtin: NormalizedGTIN { NormalizedGTIN(parsing: barcode) }
}

extension FoodItem {
    /// Barcode identity of a stock item, normalised at read time — works the same
    /// for items saved long before normalisation existed. Nil without a barcode.
    nonisolated var gtin: NormalizedGTIN? { barcode.map { NormalizedGTIN(parsing: $0) } }
}
