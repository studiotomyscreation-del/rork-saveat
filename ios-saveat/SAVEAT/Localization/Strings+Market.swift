import Foundation

/// Copy for the country (market) setting.
extension S {
    nonisolated enum Market {
        static let title = Loc(fr: "Pays", en: "Country")
        static let automatic = Loc(fr: "Automatique (%@)", en: "Automatic (%@)")
        static let note = Loc(
            fr: "Définit la devise, les unités, les distances et l'affichage nutritionnel. Indépendant de la langue. Ton stock, tes préférences et ton abonnement restent intacts.",
            en: "Sets currency, units, distances and nutrition labels. Independent from the language. Your food, your preferences and your subscription stay exactly as they are."
        )
    }
}
