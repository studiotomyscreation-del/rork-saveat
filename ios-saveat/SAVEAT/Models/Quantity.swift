import Foundation

/// A structured amount + unit, parsed on demand from the free-text
/// quantities SAVEAT has always stored ("200 g", "3 pièces", "1,5 kg") —
/// see the Phase 1 "Chef + semaine" audit's finding that no such type
/// existed. Additive only: `MealIngredient.quantityText` and
/// `ShoppingItem.quantityText` keep their `String` storage untouched
/// (existing call sites depend on it); this sits on top, used only where
/// real aggregation is needed (shopping list, stock subtraction).
nonisolated struct Quantity: Codable, Hashable, Sendable {
    var amount: Double
    var unit: Unit

    nonisolated enum Unit: String, Codable, Sendable, CaseIterable {
        case piece
        case gram
        case kilogram
        case milliliter
        case liter

        /// The unit every amount of this family is normalized to before
        /// summing — grams for weight, millilitres for volume, the piece
        /// itself for count. Families never mix: a piece count can't be
        /// added to a weight.
        nonisolated var baseUnit: Unit {
            switch self {
            case .piece: .piece
            case .gram, .kilogram: .gram
            case .milliliter, .liter: .milliliter
            }
        }

        nonisolated var conversionToBase: Double {
            switch self {
            case .piece, .gram, .milliliter: 1
            case .kilogram: 1_000
            case .liter: 1_000
            }
        }
    }

    init(amount: Double, unit: Unit) {
        self.amount = amount
        self.unit = unit
    }

    /// This amount expressed in its family's base unit (grams, millilitres or pieces).
    nonisolated var baseAmount: Double { amount * unit.conversionToBase }

    /// Sums two quantities when they're the same family (both weight, both
    /// volume, both count) — `nil` for incompatible families, so callers can
    /// fall back to keeping both lines separate instead of producing a wrong
    /// number (e.g. "3 pièces" + "200 g" of the same ingredient never merges).
    nonisolated func combined(with other: Quantity) -> Quantity? {
        guard unit.baseUnit == other.unit.baseUnit else { return nil }
        return Quantity(amount: baseAmount + other.baseAmount, unit: unit.baseUnit)
    }

    /// Reader-facing text, e.g. "700 g" or "6" for a piece count — reuses the
    /// same locale-aware formatters as the rest of the app (`Units.weight`
    /// for grams/kilograms, `Units.volume` for millilitres/litres) rather
    /// than a new one-off formatter.
    nonisolated var displayText: String {
        switch unit.baseUnit {
        case .gram: Units.weight(grams: baseAmount)
        case .milliliter: Units.volume(millilitres: baseAmount)
        case .piece: Format.quantity(amount)
        case .kilogram, .liter: Format.quantity(amount) // unreachable: baseUnit never returns these
        }
    }

    /// Best-effort parse of SAVEAT's existing free-text quantities. Reuses
    /// `MealEngine.leadingNumber`'s number-parsing heuristic rather than
    /// re-implementing it, then matches the *exact* unit word right after
    /// the number — not a raw substring check, so "1 gousse" never
    /// false-matches "g" the way a naive `.contains("g")` would. Returns
    /// `nil` for anything unrecognized ("1 pincée", "au goût") — those stay
    /// free text, never guessed.
    init?(parsing text: String) {
        let normalized = MealEngine.normalize(text)
        guard let number = MealEngine.leadingNumber(in: normalized) else { return nil }

        let afterNumber = normalized.drop { $0.isNumber || $0 == "." || $0 == "," || $0 == " " || $0 == "/" }
        let unitToken = String(afterNumber.prefix { $0.isLetter })

        switch unitToken {
        case "kg", "kilo", "kilos": self.init(amount: number, unit: .kilogram)
        case "g", "gr", "gramme", "grammes": self.init(amount: number, unit: .gram)
        case "ml": self.init(amount: number, unit: .milliliter)
        case "cl": self.init(amount: number * 10, unit: .milliliter)
        case "l", "litre", "litres": self.init(amount: number, unit: .liter)
        case "piece", "pieces", "tranche", "tranches", "unite", "unites", "portion", "portions":
            self.init(amount: number, unit: .piece)
        default: return nil
        }
    }
}

extension MealIngredient {
    /// `nil` when `quantityText` isn't a recognizable number+unit (e.g. "au
    /// goût") — those ingredients are left out of shopping-list aggregation
    /// rather than guessed.
    nonisolated var parsedQuantity: Quantity? { Quantity(parsing: quantityText) }
}

extension ShoppingItem {
    nonisolated var parsedQuantity: Quantity? { Quantity(parsing: quantityText) }
}
