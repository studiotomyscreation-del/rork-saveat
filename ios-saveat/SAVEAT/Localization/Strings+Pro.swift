import Foundation

/// SAVEAT PRO — professional/merchant-facing copy.
///
/// Kept in its own file rather than growing `Strings.swift` further (already
/// 2,200+ lines before this feature) — same `S` namespace, same `Loc`
/// pattern, just a separate file so this can keep expanding as the Pro
/// screens get built without making the main file harder to navigate.
extension S {
    nonisolated enum Pro {
        // MARK: Establishment identification (§10 — never overclaim verification)

        static let statusEstablishmentIdentified = Loc(
            fr: "Établissement identifié",
            en: "Establishment identified"
        )
        static let statusEstablishmentClosed = Loc(
            fr: "Cet établissement apparaît comme fermé",
            en: "This establishment appears closed"
        )

        // MARK: Basket offer status (§35)

        static let offerStatusDraft = Loc(fr: "Brouillon", en: "Draft")
        static let offerStatusScheduled = Loc(fr: "Programmé", en: "Scheduled")
        static let offerStatusAvailable = Loc(fr: "Disponible", en: "Available")
        static let offerStatusSoldOut = Loc(fr: "Épuisé", en: "Sold out")
        static let offerStatusPickupClosed = Loc(fr: "Retrait terminé", en: "Pickup closed")
        static let offerStatusCompleted = Loc(fr: "Terminé", en: "Completed")
        static let offerStatusCancelled = Loc(fr: "Annulé", en: "Cancelled")

        // MARK: Reservation status (§26)

        static let reservationStatusPending = Loc(fr: "En attente", en: "Pending")
        static let reservationStatusConfirmed = Loc(fr: "Confirmée", en: "Confirmed")
        static let reservationStatusCollected = Loc(fr: "Retiré", en: "Collected")
        static let reservationStatusCancelled = Loc(fr: "Annulée", en: "Cancelled")
        static let reservationStatusExpired = Loc(fr: "Expirée", en: "Expired")
        static let reservationStatusNoShow = Loc(fr: "Non retiré", en: "No-show")

        // MARK: Basket type (§18-19)

        static let basketTypeSurprise = Loc(fr: "Panier surprise", en: "Surprise basket")
        static let basketTypeDetailed = Loc(fr: "Panier détaillé", en: "Detailed basket")

        // MARK: Dietary claims (§20 — only what the professional confirms themselves)

        static let dietaryVegetarian = Loc(fr: "Végétarien", en: "Vegetarian")
        static let dietaryVegan = Loc(fr: "Vegan", en: "Vegan")
        static let dietaryPorkFree = Loc(fr: "Sans porc", en: "Pork-free")
        static let dietaryGlutenFree = Loc(fr: "Sans gluten", en: "Gluten-free")
        static let dietaryLactoseFree = Loc(fr: "Sans lactose", en: "Lactose-free")
        static let dietaryHalal = Loc(fr: "Halal", en: "Halal")
        static let dietaryKosher = Loc(fr: "Casher", en: "Kosher")
    }
}
