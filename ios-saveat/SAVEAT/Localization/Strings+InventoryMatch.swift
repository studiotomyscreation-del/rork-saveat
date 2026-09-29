import Foundation

/// Copy for « Déjà chez vous » after a scan.
extension S {
    nonisolated enum InventoryMatch {
        static let title = Loc(fr: "Vous en avez déjà à la maison", en: "You already have this at home")
        static let inFridge = Loc(fr: "%@ dans votre frigo", en: "%@ in your fridge")
        static let inPantry = Loc(fr: "%@ dans votre placard", en: "%@ in your pantry")
        static let inFreezer = Loc(fr: "%@ dans votre congélateur", en: "%@ in your freezer")
        static let total = Loc(fr: "Total : %@ à la maison", en: "Total: %@ at home")
        static let useSoonOne = Loc(fr: "%@ est à utiliser bientôt", en: "%@ should be used soon")
        static let useSoonMany = Loc(fr: "%@ sont à utiliser bientôt", en: "%@ of them should be used soon")
    }
}

extension InventoryMatch {
    /// « 2 dans votre placard », « 1 dans votre frigo »…, then a total when the
    /// product sits in more than one place.
    nonisolated var locationLines: [String] {
        let totals = byLocation
        var lines = totals.map { total -> String in
            let amount = Format.quantity(total.quantity)
            switch total.location {
            case .fridge: return S.InventoryMatch.inFridge.f(amount)
            case .pantry: return S.InventoryMatch.inPantry.f(amount)
            case .freezer: return S.InventoryMatch.inFreezer.f(amount)
            }
        }
        if totals.count > 1 {
            lines.append(S.InventoryMatch.total.f(Format.quantity(totalQuantity)))
        }
        return lines
    }

    /// « 1 est à utiliser bientôt », only when a recorded date is close.
    nonisolated var useSoonLine: String? {
        let quantity = useSoonQuantity
        guard quantity > 0 else { return nil }
        let copy = quantity > 1 ? S.InventoryMatch.useSoonMany : S.InventoryMatch.useSoonOne
        return copy.f(Format.quantity(quantity))
    }
}
