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

        // MARK: Entry point (§5)

        static let entryPointTitle = Loc(fr: "Vous êtes commerçant ?", en: "Are you a food business?")
        static let entryPointSubtitle = Loc(
            fr: "Gratuit, sans commission — on veut juste stopper le gaspillage.",
            en: "Free, no commission — our only goal is to stop food waste."
        )
        static let becomePartnerCTA = Loc(fr: "Devenir partenaire SAVEAT", en: "Become a SAVEAT partner")

        // MARK: Business identifier screen (§8)

        static let signUpTitle = Loc(fr: "Identifiez votre établissement", en: "Identify your business")
        static let signUpSubtitle = Loc(
            fr: "Entrez votre SIRET, SAVEAT s'occupe du reste.",
            en: "Enter your SIRET number — SAVEAT takes care of the rest."
        )
        static let signUpFreeNotice = Loc(
            fr: "Gratuit et sans engagement, à tout moment.",
            en: "Free and commitment-free, cancel anytime."
        )
        /// Displayed below `signUpFreeNotice` — the sign-up moment is where
        /// this reassurance matters most: no margin taken on what a
        /// professional sells or gives away, because the point of SAVEAT PRO
        /// is stopping food waste, not monetizing it.
        static let signUpNoCommissionNotice = Loc(
            fr: "Aucune commission sur vos paniers : notre seul objectif est de stopper le gaspillage alimentaire.",
            en: "No commission on your baskets: our only goal is to stop food waste."
        )
        static let siretFieldLabel = Loc(fr: "SIRET ou SIREN", en: "SIRET or SIREN")
        static let siretFieldPlaceholder = Loc(fr: "14 ou 9 chiffres", en: "14 or 9 digits")
        static let findEstablishmentCTA = Loc(fr: "Trouver mon établissement", en: "Find my business")
        static let searchingEstablishment = Loc(
            fr: "Recherche de votre établissement…",
            en: "Looking up your business…"
        )
        static let thisIsMyEstablishment = Loc(fr: "C'est mon établissement", en: "This is my business")
        static let notMyEstablishment = Loc(fr: "Ce n'est pas mon établissement", en: "This isn't my business")
        static let establishmentNotFound = Loc(
            fr: "Aucun établissement trouvé pour ce numéro.",
            en: "No business found for this number."
        )
        static let invalidIdentifierFormat = Loc(
            fr: "Entrez un SIRET (14 chiffres) ou un SIREN (9 chiffres) valide.",
            en: "Enter a valid SIRET (14 digits) or SIREN (9 digits)."
        )
        static let lookupServiceUnavailable = Loc(
            fr: "Service indisponible pour le moment. Réessayez.",
            en: "Service unavailable right now. Try again."
        )
        static let otherEstablishmentsNotice = Loc(
            fr: "Cette entreprise a d'autres établissements — si ce n'est pas le bon, entrez directement son propre SIRET.",
            en: "This business has other locations — if this isn't the right one, enter its own SIRET directly."
        )

        // MARK: SIREN with several establishments (§9)

        static let multipleEstablishmentsTitle = Loc(
            fr: "Votre entreprise possède plusieurs établissements",
            en: "Your business has several locations"
        )
        static let chooseThisEstablishment = Loc(fr: "Choisir cet établissement", en: "Choose this location")

        // MARK: Responsible person (§13)

        static let responsibleInfoTitle = Loc(fr: "Coordonnées du responsable", en: "Contact details")
        static let firstNameLabel = Loc(fr: "Prénom", en: "First name")
        static let lastNameLabel = Loc(fr: "Nom", en: "Last name")
        static let emailLabel = Loc(fr: "E-mail", en: "Email")
        static let phoneLabel = Loc(fr: "Téléphone", en: "Phone")
        static let createProAccountCTA = Loc(
            fr: "Créer mon compte SAVEAT PRO",
            en: "Create my SAVEAT PRO account"
        )
        /// Shown under the create-account button — SAVEAT has no backend yet,
        /// so this is honest about what "creating an account" means today:
        /// saved on this device only, same honesty pattern as
        /// `S.Intro.accountComingSoonNotice` for the particulier account.
        static let proAccountComingSoonNotice = Loc(
            fr: "Ton profil pro est enregistré sur cet appareil. La synchronisation et le tableau de bord complet arriveront dans une prochaine mise à jour.",
            en: "Your pro profile is saved on this device. Sync and the full dashboard are coming in a future update."
        )

        // MARK: Professional profile (§ once signed up)

        static let proProfileTitle = Loc(fr: "Mon espace pro", en: "My pro space")
        static let establishmentSectionTitle = Loc(fr: "Établissement", en: "Business")
        static let responsibleSectionTitle = Loc(fr: "Responsable", en: "Contact")
        static let dashboardComingSoonNotice = Loc(
            fr: "Le tableau de bord (paniers, réservations, statistiques) arrive dans une prochaine mise à jour.",
            en: "The dashboard (baskets, reservations, statistics) is coming in a future update."
        )
        static let leaveProSpaceCTA = Loc(fr: "Quitter l'espace pro", en: "Leave the pro space")
        static let leaveProSpaceConfirmTitle = Loc(
            fr: "Quitter l'espace pro ?",
            en: "Leave the pro space?"
        )
        static let leaveProSpaceConfirmMessage = Loc(
            fr: "Ton profil pro sera supprimé de cet appareil. Tu pourras t'inscrire à nouveau à tout moment.",
            en: "Your pro profile will be removed from this device. You can sign up again at any time."
        )
    }
}
