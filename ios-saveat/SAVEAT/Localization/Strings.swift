import Foundation

/// Every piece of user-facing copy in SAVEAT, in each supported language.
///
/// Screens never hold raw text: they read entries from here. English is written
/// for a US reader rather than translated word for word from the French.
nonisolated enum S {

    // MARK: - Common

    nonisolated enum Common {
        static let ok = Loc(fr: "OK", en: "OK")
        static let cancel = Loc(fr: "Annuler", en: "Cancel")
        static let close = Loc(fr: "Fermer", en: "Close")
        static let done = Loc(fr: "Terminé", en: "Done")
        static let save = Loc(fr: "Enregistrer", en: "Save")
        static let add = Loc(fr: "Ajouter", en: "Add")
        static let delete = Loc(fr: "Supprimer", en: "Delete")
        static let edit = Loc(fr: "Modifier", en: "Edit")
        static let back = Loc(fr: "Retour", en: "Back")
        static let next = Loc(fr: "Suivant", en: "Next")
        static let skip = Loc(fr: "Passer", en: "Skip")
        static let retry = Loc(fr: "Réessayer", en: "Try Again")
        static let seeAll = Loc(fr: "Tout voir", en: "See All")
        static let search = Loc(fr: "Rechercher", en: "Search")
        static let loading = Loc(fr: "Chargement…", en: "Loading…")
        static let error = Loc(fr: "Erreur", en: "Something went wrong")
        static let comingSoon = Loc(fr: "BIENTÔT", en: "COMING SOON")
        static let estimate = Loc(fr: "Estimation", en: "Estimate")
        static let today = Loc(fr: "Aujourd'hui", en: "Today")
        static let tomorrow = Loc(fr: "Demain", en: "Tomorrow")
        static let day = Loc(fr: "jour", en: "day")
        static let days = Loc(fr: "jours", en: "days")
        static let noDate = Loc(fr: "Sans date", en: "No date")
        static let expired = Loc(fr: "Dépassé", en: "Expired")
        static let inDays = Loc(fr: "dans %d jours", en: "in %d days")
        static let products = Loc(fr: "produits", en: "items")
        static let product = Loc(fr: "produit", en: "item")
    }

    // MARK: - Storage locations

    nonisolated enum Storage {
        static let fridge = Loc(fr: "Frigo", en: "Fridge")
        static let pantry = Loc(fr: "Placards", en: "Pantry")
        static let freezer = Loc(fr: "Congélateur", en: "Freezer")
    }

    // MARK: - Freshness

    nonisolated enum Freshness {
        static let fresh = Loc(fr: "OK", en: "OK")
        static let soon = Loc(fr: "À consommer bientôt", en: "Use soon")
        static let urgent = Loc(fr: "À utiliser en priorité", en: "Use first")
    }

    // MARK: - Food categories

    nonisolated enum Category {
        static let produce = Loc(fr: "Fruits & légumes", en: "Produce")
        static let dairy = Loc(fr: "Produits frais", en: "Dairy & Chilled")
        static let protein = Loc(fr: "Viandes / protéines", en: "Meat & Protein")
        static let grocery = Loc(fr: "Épicerie", en: "Pantry Staples")
        static let frozen = Loc(fr: "Surgelés", en: "Frozen")
    }

    // MARK: - Date kinds printed on packaging

    nonisolated enum DateType {
        static let useByBadge = Loc(fr: "DLC", en: "Use By")
        static let bestByBadge = Loc(fr: "DDM", en: "Best By")
        static let unknownBadge = Loc(fr: "Date", en: "Date")

        static let useByTitle = Loc(
            fr: "DLC — À consommer jusqu'au",
            en: "Use By — safety date"
        )
        static let bestByTitle = Loc(
            fr: "DDM — À consommer de préférence avant",
            en: "Best By — quality date"
        )
        static let unknownTitle = Loc(fr: "Non renseigné", en: "Not specified")

        static let useByPicker = Loc(fr: "DLC", en: "Use By")
        static let bestByPicker = Loc(fr: "DDM", en: "Best By")
        static let unknownPicker = Loc(fr: "Non renseigné", en: "Not specified")

        static let useByHelp = Loc(
            fr: "À consommer jusqu'au — date de sécurité.",
            en: "Use By — this is a food safety date."
        )
        static let bestByHelp = Loc(
            fr: "À consommer de préférence avant — date de qualité.",
            en: "Best By — this is a quality date, not a safety date."
        )
        static let unknownHelp = Loc(
            fr: "Regarde l'emballage pour connaître le type de date.",
            en: "Check the package to see which kind of date it prints."
        )

        static let useByPassed = Loc(
            fr: "Date limite de consommation dépassée. SAVEAT ne recommande pas la consommation après une DLC dépassée. Vérifie les indications figurant sur l'emballage et les recommandations officielles.",
            en: "The Use By date has passed. SAVEAT does not recommend eating food after its Use By date. Check the package and official food safety guidance."
        )
        static let bestByPassed = Loc(
            fr: "Date de durabilité minimale dépassée. Cela ne signifie pas automatiquement que le produit est impropre à la consommation. Vérifie son emballage, ses conditions de conservation et son état avant toute utilisation.",
            en: "The Best By date has passed. That does not automatically mean the food has gone bad. Check the package, how it was stored and its condition before using it."
        )
        static let unknownPassed = Loc(
            fr: "La date est atteinte. Le type de date n'est pas renseigné : vérifie l'emballage pour savoir s'il s'agit d'une DLC (date limite de consommation) ou d'une DDM (date de durabilité minimale).",
            en: "This date has been reached. The date type is not specified — check the package to see whether it prints a Use By (safety) or a Best By (quality) date."
        )
    }

    // MARK: - Consumption status

    nonisolated enum Status {
        static let keepTitle = Loc(fr: "À conserver", en: "Fresh")
        static let planTitle = Loc(fr: "À prévoir", en: "Use This Week")
        static let rescueTitle = Loc(fr: "À sauver", en: "Use Soon")
        static let reachedTitle = Loc(fr: "Date atteinte / dépassée", en: "Expired")

        static let keepShort = Loc(fr: "À conserver", en: "Fresh")
        static let planShort = Loc(fr: "À prévoir", en: "This week")
        static let rescueShort = Loc(fr: "À sauver", en: "Use soon")
        static let reachedShort = Loc(fr: "Date atteinte", en: "Expired")

        static let keepDetail = Loc(fr: "Rien d'urgent.", en: "Nothing urgent here.")
        static let planDetail = Loc(
            fr: "La date approche — pense à l'intégrer à tes prochains repas.",
            en: "The date is coming up — work it into your next few meals."
        )
        static let rescueDetail = Loc(
            fr: "À consommer rapidement pour éviter de le gaspiller.",
            en: "Use this soon so it doesn't go to waste."
        )
        static let reachedDetail = Loc(
            fr: "La date est atteinte ou dépassée.",
            en: "This date has been reached or passed."
        )
    }

    // MARK: - Household goals

    nonisolated enum Goal {
        static let save = Loc(fr: "Économiser", en: "Save money")
        static let reduceWaste = Loc(fr: "Moins gaspiller", en: "Waste less")
        static let eatBalanced = Loc(fr: "Manger équilibré", en: "Eat balanced")
        static let eatLight = Loc(fr: "Manger plus léger", en: "Eat lighter")
        static let moreProtein = Loc(fr: "Plus de protéines", en: "More protein")
    }

    // MARK: - Diets

    nonisolated enum Diet {
        static let omnivore = Loc(fr: "Je mange de tout", en: "I eat everything")
        static let flexitarian = Loc(fr: "Flexitarien", en: "Flexitarian")
        static let vegetarian = Loc(fr: "Végétarien", en: "Vegetarian")
        static let vegan = Loc(fr: "Végétalien", en: "Vegan")
        static let pescatarian = Loc(fr: "Pescétarien", en: "Pescatarian")
        static let halal = Loc(fr: "Halal", en: "Halal")
    }

    // MARK: - Allergens

    nonisolated enum Allergens {
        static let gluten = Loc(fr: "Gluten", en: "Gluten")
        static let lactose = Loc(fr: "Lactose", en: "Dairy")
        static let nuts = Loc(fr: "Fruits à coque", en: "Tree nuts")
        static let eggs = Loc(fr: "Œufs", en: "Eggs")
        static let seafood = Loc(fr: "Fruits de mer", en: "Shellfish")
        static let soy = Loc(fr: "Soja", en: "Soy")
    }

    // MARK: - Disliked foods

    nonisolated enum Dislikes {
        static let mushrooms = Loc(fr: "Champignons", en: "Mushrooms")
        static let fish = Loc(fr: "Poisson", en: "Fish")
        static let spinach = Loc(fr: "Épinards", en: "Spinach")
        static let olives = Loc(fr: "Olives", en: "Olives")
        static let blueCheese = Loc(fr: "Fromage bleu", en: "Blue cheese")
        static let zucchini = Loc(fr: "Courgettes", en: "Zucchini")
        static let cauliflower = Loc(fr: "Chou-fleur", en: "Cauliflower")
        static let liver = Loc(fr: "Foie", en: "Liver")
        static let eggplant = Loc(fr: "Aubergines", en: "Eggplant")
        static let chili = Loc(fr: "Piment", en: "Chili pepper")
    }

    // MARK: - Household

    nonisolated enum Household {
        static let adult = Loc(fr: "adulte", en: "adult")
        static let adults = Loc(fr: "adultes", en: "adults")
        static let child = Loc(fr: "enfant", en: "child")
        static let children = Loc(fr: "enfants", en: "children")
    }

    // MARK: - Confirmation banners

    nonisolated enum Banner {
        static let saved = Loc(fr: "%@ sauvé 💚", en: "%@ used in time 💚")
        static let discarded = Loc(fr: "%@ retiré de ton stock", en: "%@ removed from your food")
        static let itemAdded = Loc(fr: "%d produit ajouté à ton stock", en: "%d item added to your food")
        static let itemsAdded = Loc(fr: "%d produits ajoutés à ton stock", en: "%d items added to your food")
        static let zeroCostCooked = Loc(
            fr: "Repas à %@ validé — stock mis à jour ✨",
            en: "%@ meal logged — your food is up to date ✨"
        )
        static let stockUpdated = Loc(
            fr: "Stock mis à jour — %d produit sauvé",
            en: "Updated — %d item used in time"
        )
        static let stockUpdatedPlural = Loc(
            fr: "Stock mis à jour — %d produits sauvés",
            en: "Updated — %d items used in time"
        )
        static let addedToList = Loc(fr: "Ajouté à ta liste de courses 🛒", en: "Added to your shopping list 🛒")
        static let alreadyInList = Loc(fr: "Déjà dans ta liste", en: "Already on your list")
    }

    // MARK: - SAVEAT Local announcement

    nonisolated enum Local {
        static let body = Loc(
            fr: "SAVEAT prépare une nouvelle façon d'acheter local. Dans les prochains mois, tu pourras découvrir directement autour de toi des agriculteurs, maraîchers et producteurs locaux, leurs produits et leurs offres grâce à une carte dédiée.",
            en: "SAVEAT is working on a new way to buy local. In the coming months you'll be able to find farmers, growers and local producers near you, along with what they sell, on a dedicated map."
        )
        static let goal = Loc(
            fr: "Notre objectif : favoriser le lien direct entre producteurs et consommateurs, raccourcir les circuits et faciliter l'accès à des produits locaux à des prix accessibles.",
            en: "Our goal: connect growers and shoppers directly, shorten the supply chain and make local food easier to afford."
        )
        static let tagline = Loc(
            fr: "Du producteur à ton assiette.",
            en: "From the farm to your plate."
        )
    }

    // MARK: - Why scan

    nonisolated enum WhyScan {
        static let title = Loc(
            fr: "SCANNE. SAVEAT S'EN SOUVIENT.",
            en: "SCAN IT. SAVEAT REMEMBERS IT."
        )
        static let body = Loc(
            fr: "Une fois tes produits enregistrés, SAVEAT garde un œil sur ton stock. L'application t'aide à repérer ce que tu as déjà, surveille les dates et te rappelle ce qu'il faut consommer en priorité pour éviter de jeter ce que tu as acheté.",
            en: "Once your groceries are logged, SAVEAT keeps track of them. It shows you what you already have, watches the dates and reminds you what to eat first, so the food you paid for doesn't end up in the trash."
        )
        static let tagline = Loc(
            fr: "Consomme ce que tu as avant d'acheter davantage.",
            en: "Eat what you have before buying more."
        )
    }

    // MARK: - Use Soon actions

    nonisolated enum Rescue {
        static let markSaved = Loc(fr: "Sauvé", en: "Used it")
        static let markDiscarded = Loc(fr: "Jeté", en: "Tossed it")
        static let navTitle = Loc(fr: "À sauver", en: "Use Soon")
        static let emptyTitle = Loc(
            fr: "Rien à sauver aujourd'hui",
            en: "Nothing to rescue today"
        )
        static let emptyMessage = Loc(
            fr: "Ton stock est sous contrôle. Continue à scanner tes courses pour garder l'avance.",
            en: "Your food is under control. Keep scanning your groceries to stay ahead."
        )
        static let count = Loc(fr: "%d produit à sauver", en: "%d item to use soon")
        static let countPlural = Loc(fr: "%d produits à sauver", en: "%d items to use soon")
        static let intro = Loc(
            fr: "Je peux préparer ton repas avec ces aliments avant qu'ils ne soient gaspillés.",
            en: "I can build your next meal around these before they go to waste."
        )
        static let potentialSavings = Loc(
            fr: "≈ %@ de nourriture à sauver — estimation",
            en: "About %@ of food worth saving — estimate"
        )
        static let priorityOrder = Loc(fr: "Dans l'ordre de priorité", en: "In priority order")
        static let reachedSection = Loc(
            fr: "Date atteinte ou dépassée",
            en: "Date reached or passed"
        )
        static let mealsSection = Loc(fr: "Repas qui les utilisent", en: "Meals that use them")
        static let disclaimer = Loc(
            fr: "Les priorités reposent sur les dates que tu as saisies ou lues sur l'emballage. SAVEAT ne peut pas juger si un aliment est encore consommable.",
            en: "Priorities come from the dates you entered or read off the package. SAVEAT can't judge whether food is still safe to eat."
        )
    }

    // MARK: - Subscription status

    nonisolated enum Subscription {
        static let planMonthly = Loc(fr: "Premium mensuel", en: "Monthly Pro")
        static let planYearly = Loc(fr: "Premium annuel", en: "Annual Pro")
        static let planLifetime = Loc(fr: "Premium à vie", en: "Lifetime Pro")
        static let planGeneric = Loc(fr: "Premium", en: "Pro")

        static let freeHeadline = Loc(fr: "Offre gratuite", en: "Free plan")
        static let trialHeadline = Loc(fr: "Essai gratuit en cours", en: "Free trial running")
        static let cancelledHeadline = Loc(fr: "%@ — non renouvelé", en: "%@ — not renewing")
        static let billingHeadline = Loc(fr: "Problème de paiement", en: "Payment problem")
        static let lifetimeHeadline = Loc(fr: "Premium à vie", en: "Lifetime Pro")
        static let expiredHeadline = Loc(fr: "Abonnement expiré", en: "Subscription expired")

        static let freeDetail = Loc(
            fr: "Débloque l'IA illimitée, le mode 0 € et les stats d'économies.",
            en: "Unlock unlimited AI, $0 meals and your savings tracker."
        )
        static let trialDetail = Loc(
            fr: "Ton essai se termine le %@.",
            en: "Your trial ends on %@."
        )
        static let trialDetailNoDate = Loc(fr: "Ton essai est actif.", en: "Your trial is active.")
        static let activeDetail = Loc(
            fr: "Renouvellement automatique le %@.",
            en: "Renews automatically on %@."
        )
        static let activeDetailNoDate = Loc(fr: "Abonnement actif.", en: "Subscription active.")
        static let cancelledDetail = Loc(
            fr: "Tu gardes Premium jusqu'au %@.",
            en: "You keep Pro through %@."
        )
        static let cancelledDetailNoDate = Loc(
            fr: "Premium actif jusqu'à la fin de la période.",
            en: "Pro stays active until the period ends."
        )
        static let billingDetail = Loc(
            fr: "Mets à jour ton moyen de paiement pour garder Premium.",
            en: "Update your payment method to keep Pro."
        )
        static let lifetimeDetail = Loc(
            fr: "Accès Premium définitif. Merci ! 💚",
            en: "Pro access for good. Thank you! 💚"
        )
        static let expiredDetail = Loc(
            fr: "Terminé le %@. Réactive quand tu veux.",
            en: "Ended on %@. Come back whenever you like."
        )
        static let expiredDetailNoDate = Loc(
            fr: "Réactive quand tu veux.",
            en: "Come back whenever you like."
        )

        static let featureScans = Loc(fr: "Scans illimités", en: "Unlimited scanning")
        static let featureAI = Loc(fr: "IA cuisine illimitée", en: "Unlimited AI recipes")
        static let featureZeroCost = Loc(fr: "Mode 0 €", en: "$0 Meals")
        static let featureBudget = Loc(fr: "Mode fin de mois", en: "Tight-budget planner")
        static let featureStats = Loc(
            fr: "Statistiques d'économies",
            en: "Savings statistics"
        )

        static let purchasesUnavailable = Loc(
            fr: "Les achats ne sont pas disponibles sur cette version.",
            en: "Purchases aren't available in this build."
        )
        static let offeringsUnavailable = Loc(
            fr: "Impossible de charger les abonnements pour le moment. Vérifie ta connexion et réessaie.",
            en: "Couldn't load the plans right now. Check your connection and try again."
        )
        static let offeringsNotReady = Loc(
            fr: "Les abonnements ne sont pas encore disponibles sur ce compte. Réessaie dans quelques instants.",
            en: "Plans aren't available on this account yet. Try again in a moment."
        )
        static let perMonth = Loc(fr: "≈ %@/mois", en: "≈ %@/month")
    }

    // MARK: - Paywall

    nonisolated enum Paywall {
        static let badge = Loc(fr: "SAVEAT PREMIUM", en: "SAVEAT PRO")
        static let title = Loc(
            fr: "Fais économiser encore plus à ton frigo.",
            en: "Get even more out of your fridge."
        )
        static let subtitle = Loc(
            fr: "Scanne sans limite, cuisine avec l'IA et suis tes économies mois après mois.",
            en: "Scan without limits, cook with AI and track what you save, month after month."
        )

        static let upsellScans = Loc(
            fr: "Tu as atteint tes scans gratuits du jour. Passe en illimité pour finir tes courses.",
            en: "You've used today's free scans. Go unlimited to finish putting your groceries away."
        )
        static let upsellAI = Loc(
            fr: "Tu as utilisé tes suggestions IA du jour. Débloque l'IA cuisine illimitée.",
            en: "You've used today's AI suggestions. Unlock unlimited AI recipes."
        )
        static let upsellZeroCost = Loc(
            fr: "Le mode 0 € trouve des repas complets sans rien acheter.",
            en: "$0 Meals finds full dinners without buying a thing."
        )
        static let upsellEndOfMonth = Loc(
            fr: "Le mode fin de mois étire ton budget jusqu'au dernier jour.",
            en: "The budget planner stretches your grocery money to the last day."
        )
        static let upsellStats = Loc(
            fr: "Suis précisément l'argent que tu ne jettes plus.",
            en: "Track exactly how much money you stop throwing away."
        )

        static let perkScansTitle = Loc(fr: "Scans illimités", en: "Unlimited scanning")
        static let perkScansBody = Loc(
            fr: "Scanne toutes tes courses d'un coup, sans compteur.",
            en: "Scan a whole grocery run at once, with no counter."
        )
        static let perkAITitle = Loc(fr: "IA cuisine illimitée", en: "Unlimited AI recipes")
        static let perkAIBody = Loc(
            fr: "Des recettes générées à partir de ton stock réel.",
            en: "Recipes built from the food you actually have."
        )
        static let perkZeroTitle = Loc(fr: "Mode 0 €", en: "$0 Meals")
        static let perkZeroBody = Loc(
            fr: "Des repas complets sans dépenser un centime.",
            en: "Complete meals without spending a cent."
        )
        static let perkBudgetTitle = Loc(fr: "Mode fin de mois", en: "Tight-budget planner")
        static let perkBudgetBody = Loc(
            fr: "Un plan repas qui tient jusqu'au dernier jour.",
            en: "A meal plan that lasts until payday."
        )
        static let perkStatsTitle = Loc(fr: "Stats d'économies", en: "Savings tracker")
        static let perkStatsBody = Loc(
            fr: "Estimation de ce que tu ne jettes plus.",
            en: "An estimate of what you no longer throw out."
        )
        static let perkAlertsTitle = Loc(
            fr: "Alertes produits à sauver",
            en: "Expiration reminders"
        )
        static let perkAlertsBody = Loc(
            fr: "Prévenu avant que ça se perde.",
            en: "A heads-up before food goes bad."
        )

        static let annual = Loc(fr: "Annuel", en: "Annual")
        static let monthly = Loc(fr: "Mensuel", en: "Monthly")
        static let lifetime = Loc(fr: "À vie", en: "Lifetime")
        static let weekly = Loc(fr: "Hebdomadaire", en: "Weekly")
        static let bestValue = Loc(fr: "⭐ Meilleure offre", en: "⭐ Best value")
        static let trialThen = Loc(fr: "%@ offert puis %@", en: "%@ free, then %@")
        static let trialThenPlural = Loc(fr: "%@ offerts puis %@", en: "%@ free, then %@")
        static let billedYearly = Loc(
            fr: "%@ • facturé une fois par an",
            en: "%@ • billed once a year"
        )
        static let lifetimeNote = Loc(
            fr: "Paiement unique, accès définitif",
            en: "One payment, yours for good"
        )
        static let monthlyNote = Loc(
            fr: "Sans engagement, résiliable à tout moment",
            en: "No commitment, cancel anytime"
        )

        static let days = Loc(fr: "jours", en: "days")
        static let day = Loc(fr: "jour", en: "day")
        static let weeks = Loc(fr: "semaines", en: "weeks")
        static let week = Loc(fr: "semaine", en: "week")
        static let months = Loc(fr: "mois", en: "months")
        static let years = Loc(fr: "ans", en: "years")
        static let year = Loc(fr: "an", en: "year")

        static let unavailableTitle = Loc(
            fr: "Offres indisponibles",
            en: "Plans unavailable"
        )
        static let subscribeCTA = Loc(
            fr: "Passer à SAVEAT Premium",
            en: "Get SAVEAT PRO"
        )
        static let trialCTA = Loc(
            fr: "Commencer l'essai gratuit",
            en: "Start free trial"
        )
        static let continueFree = Loc(
            fr: "Continuer gratuitement",
            en: "Continue for free"
        )
        static let restore = Loc(
            fr: "Restaurer mes achats",
            en: "Restore Purchases"
        )
        static let renewalTerms = Loc(
            fr: "Paiement via ton compte Apple. L'abonnement se renouvelle automatiquement sauf résiliation au moins 24 h avant la fin de la période. Tu peux gérer ou résilier à tout moment dans les réglages de l'App Store.",
            en: "Billed through your Apple account. Your subscription renews automatically unless you cancel at least 24 hours before the period ends. You can manage or cancel anytime in your App Store settings."
        )
        static let estimatesNote = Loc(
            fr: "Toutes les économies affichées dans SAVEAT sont des estimations.",
            en: "Every savings figure in SAVEAT is an estimate."
        )
        static let oops = Loc(fr: "Oups", en: "Something went wrong")
        static let pendingPurchase = Loc(
            fr: "Achat en attente",
            en: "Purchase pending"
        )
    }

    // MARK: - Tab bar

    nonisolated enum Tabs {
        static let home = Loc(fr: "Accueil", en: "Home")
        static let stock = Loc(fr: "Stock", en: "My Food")
        static let meals = Loc(fr: "Repas", en: "Recipes")
        static let scanner = Loc(fr: "Scanner", en: "Scan")
        static let profile = Loc(fr: "Profil", en: "Profile")
    }

    // MARK: - Onboarding

    nonisolated enum Onboarding {
        static let back = Loc(fr: "Retour", en: "Back")
        static let start = Loc(fr: "C'est parti", en: "Get Started")
        static let cont = Loc(fr: "Continuer", en: "Continue")
        static let editLater = Loc(
            fr: "Tu pourras tout modifier plus tard dans ton profil.",
            en: "You can change any of this later in your profile."
        )

        static let householdTitle = Loc(
            fr: "Vous êtes combien à la maison ?",
            en: "How many people are you cooking for?"
        )
        static let householdSubtitle = Loc(
            fr: "On adapte les quantités et les portions à ton foyer.",
            en: "We'll size every recipe and portion to your household."
        )
        static let seats = Loc(fr: "%d couvert par repas", en: "%d plate per meal")
        static let seatsPlural = Loc(fr: "%d couverts par repas", en: "%d plates per meal")

        static let goalTitle = Loc(
            fr: "Ton objectif principal ?",
            en: "What matters most to you?"
        )
        static let goalSubtitle = Loc(
            fr: "SAVEAT met en avant ce qui compte le plus pour toi.",
            en: "SAVEAT puts what you care about front and center."
        )

        static let dietTitle = Loc(fr: "Comment manges-tu ?", en: "How do you eat?")
        static let dietSubtitle = Loc(
            fr: "On écarte automatiquement les recettes qui ne te conviennent pas.",
            en: "We'll leave out recipes that don't work for you."
        )

        static let dislikesTitle = Loc(
            fr: "Ce que tu ne manges pas",
            en: "Anything you'd rather skip?"
        )
        static let dislikesSubtitle = Loc(
            fr: "Touche simplement les aliments à éviter. Aucun texte à saisir.",
            en: "Just tap the foods to avoid — no typing needed."
        )

        static let budgetTitle = Loc(
            fr: "Ton budget courses par semaine ?",
            en: "What's your weekly grocery budget?"
        )
        static let budgetSubtitle = Loc(
            fr: "Une estimation suffit — elle nous sert à calculer tes économies.",
            en: "A rough number is fine — we use it to estimate your savings."
        )
        static let perWeekFor = Loc(
            fr: "par semaine pour %d personne",
            en: "per week for %d person"
        )
        static let perWeekForPlural = Loc(
            fr: "par semaine pour %d personnes",
            en: "per week for %d people"
        )
    }

    // MARK: - Challenges

    nonisolated enum Challenges {
        static let navTitle = Loc(fr: "Défi Zéro Gaspi", en: "Zero Waste Challenge")
        static let cardTitle = Loc(fr: "Challenge Zéro Gaspi", en: "Zero Waste Challenge")
        static let streakDays = Loc(fr: "%d j", en: "%dd")
        static let savedThisWeek = Loc(
            fr: "produit sauvé cette semaine",
            en: "item rescued this week"
        )
        static let savedThisWeekPlural = Loc(
            fr: "produits sauvés cette semaine",
            en: "items rescued this week"
        )
        static let remaining = Loc(
            fr: "Encore %d produit pour atteindre ton objectif.",
            en: "%d more item to hit your goal."
        )
        static let remainingPlural = Loc(
            fr: "Encore %d produits pour atteindre ton objectif.",
            en: "%d more items to hit your goal."
        )
        static let goalReached = Loc(
            fr: "Objectif de la semaine atteint. Beau travail 🌿",
            en: "This week's goal is done. Nice work 🌿"
        )
        static let streakLine = Loc(
            fr: "🔥 %d jour consécutif sans rien jeter.",
            en: "🔥 %d day straight without throwing anything out."
        )
        static let streakLinePlural = Loc(
            fr: "🔥 %d jours consécutifs sans rien jeter.",
            en: "🔥 %d days straight without throwing anything out."
        )
        static let thisMonth = Loc(fr: "ce mois-ci", en: "this month")
        static let allTime = Loc(fr: "depuis le début", en: "all time")
        static let sevenDays = Loc(
            fr: "Défi Zéro Gaspi — 7 jours",
            en: "Zero Waste Challenge — 7 days"
        )
        static let missionsDone = Loc(
            fr: "%d/%d missions accomplies",
            en: "%d of %d challenges done"
        )
        static let achievementCard = Loc(fr: "Ta carte de réussite", en: "Your win card")
        static let shareText = Loc(
            fr: "Cette semaine j'ai économisé %@ et sauvé %d produits avec SAVEAT.",
            en: "This week I saved %@ and rescued %d items with SAVEAT."
        )
        static let cardText = Loc(
            fr: "Cette semaine j'ai économisé %@ et sauvé %d produits.",
            en: "This week I saved %@ and rescued %d items."
        )
        static let share = Loc(fr: "Partager", en: "Share")
    }

    // MARK: - Reminders

    nonisolated enum Reminders {
        static let navTitle = Loc(fr: "Rappels anti-gaspi", en: "Expiration Reminders")
        static let introTitle = Loc(
            fr: "Je te préviens avant, pas trop tard.",
            en: "A heads-up in time, not after the fact."
        )
        static let introBody = Loc(
            fr: "Quand plusieurs produits arrivent à leur date le même jour, tu reçois un seul rappel groupé.",
            en: "When several items come due on the same day, you get one combined reminder."
        )
        static let enable = Loc(fr: "Activer les rappels", en: "Turn on reminders")
        static let statusOff = Loc(
            fr: "Aucun rappel ne sera envoyé.",
            en: "No reminders will be sent."
        )
        static let statusGranted = Loc(
            fr: "SAVEAT peut t'envoyer des rappels.",
            en: "SAVEAT can send you reminders."
        )
        static let statusDenied = Loc(
            fr: "Notifications refusées dans les réglages iOS.",
            en: "Notifications are turned off in iOS Settings."
        )
        static let statusUnknown = Loc(
            fr: "SAVEAT te demandera l'autorisation.",
            en: "SAVEAT will ask for permission."
        )
        static let whenSection = Loc(
            fr: "Quand veux-tu être prévenu ?",
            en: "When should I tell you?"
        )
        static let fiveDays = Loc(fr: "5 jours avant", en: "5 days before")
        static let twoDays = Loc(fr: "2 jours avant", en: "2 days before")
        static let oneDay = Loc(fr: "1 jour avant", en: "1 day before")
        static let sameDay = Loc(fr: "Le jour même", en: "On the day")
        static let planTag = Loc(fr: "🟡 À prévoir", en: "🟡 Use this week")
        static let rescueTag = Loc(fr: "🟠 À sauver", en: "🟠 Use soon")
        static let checkTag = Loc(fr: "🔴 À vérifier", en: "🔴 Check it")
        static let deniedTitle = Loc(
            fr: "Notifications désactivées",
            en: "Notifications are off"
        )
        static let deniedBody = Loc(
            fr: "SAVEAT continue de fonctionner normalement : tes produits à sauver restent visibles sur l'accueil. Pour recevoir les rappels, autorise les notifications dans les réglages de ton iPhone.",
            en: "SAVEAT works exactly the same otherwise — the food you need to use stays right on your home screen. To get reminders, allow notifications in your iPhone settings."
        )
        static let openSettings = Loc(fr: "Ouvrir les réglages", en: "Open Settings")
        static let explanation = Loc(
            fr: "Les rappels reposent uniquement sur les dates que tu as saisies. SAVEAT n'invente jamais de date et ne se prononce jamais sur la comestibilité d'un aliment.",
            en: "Reminders come only from the dates you entered. SAVEAT never makes a date up and never rules on whether food is safe to eat."
        )

        // Notification copy — one message a day at most, worded for the most
        // urgent item of that day. Never claims food is safe or unsafe to eat.
        static let action = Loc(
            fr: "Voir mes produits à sauver",
            en: "See what to use"
        )

        static let checkTitleOne = Loc(fr: "À vérifier 🔴", en: "Check it today 🔴")
        static let rescueTitleOne = Loc(fr: "À sauver 🟠", en: "Use soon 🟠")
        static let planTitleOne = Loc(fr: "À prévoir 🟡", en: "Plan ahead 🟡")

        static let bodyTodayOne = Loc(
            fr: "%@ arrive aujourd'hui à sa date. Vérifie son type de date et les indications présentes sur son emballage.",
            en: "%@ reaches its date today. Check which kind of date it prints and what the package says."
        )
        static let bodyTomorrowOne = Loc(
            fr: "%@ arrive demain à sa date. Pense à le consommer.",
            en: "%@ reaches its date tomorrow. Try to use it."
        )
        static let bodySoonOne = Loc(
            fr: "%@ est à consommer rapidement. SAVEAT peut te proposer un repas avec ce que tu as déjà.",
            en: "%@ should be used soon. SAVEAT can build a meal from what you already have."
        )
        static let bodyPlanOne = Loc(
            fr: "%@ approche de sa date. Pense à l'intégrer à tes prochains repas.",
            en: "%@ is getting close to its date. Work it into your next few meals."
        )

        static let checkTitleMany = Loc(
            fr: "%d produits arrivent aujourd'hui à leur date 🔴",
            en: "%d items reach their date today 🔴"
        )
        static let rescueTitleTomorrow = Loc(
            fr: "%d produits à sauver demain 🟠",
            en: "%d items to use by tomorrow 🟠"
        )
        static let rescueTitleMany = Loc(
            fr: "%d produits à sauver 🟠",
            en: "%d items to use soon 🟠"
        )
        static let planTitleMany = Loc(
            fr: "%d produits à prévoir 🟡",
            en: "%d items to plan for 🟡"
        )

        static let bodyTodayMany = Loc(
            fr: "%@ arrivent à leur date. Vérifie leur type de date et les indications présentes sur leur emballage.",
            en: "%@ reach their date. Check which kind of date they print and what the packages say."
        )
        static let bodyTomorrowMany = Loc(
            fr: "%@ arrivent demain à leur date. Pense à les consommer.",
            en: "%@ reach their date tomorrow. Try to use them."
        )
        static let bodySoonMany = Loc(
            fr: "%@ sont à consommer rapidement. SAVEAT peut te proposer un repas avec ce que tu as déjà.",
            en: "%@ should be used soon. SAVEAT can build a meal from what you already have."
        )
        static let bodyPlanMany = Loc(
            fr: "%@ approchent de leur date. Pense à les intégrer à tes prochains repas.",
            en: "%@ are getting close to their date. Work them into your next few meals."
        )

        static let listJoiner = Loc(fr: " et ", en: " and ")
        static let listMore = Loc(fr: " et %d autre", en: " and %d more")
        static let listMorePlural = Loc(fr: " et %d autres", en: " and %d more")
    }

    // MARK: - Profile

    nonisolated enum Profile {
        static let household = Loc(fr: "Mon foyer", en: "My Household")
        static let premiumBadge = Loc(fr: "SAVEAT PREMIUM", en: "SAVEAT PRO")
        static let upsellTitle = Loc(
            fr: "Fais économiser encore plus à ton frigo.",
            en: "Get even more out of your fridge."
        )
        static let upsellFeatures = Loc(
            fr: "Scans illimités • IA cuisine illimitée • mode 0 € • fin de mois",
            en: "Unlimited scanning • unlimited AI recipes • $0 meals • budget planner"
        )
        static let seeOffers = Loc(fr: "Voir les offres", en: "See plans")
        static let manageSubscription = Loc(
            fr: "Gérer mon abonnement",
            en: "Manage my subscription"
        )
        static let sinceJoining = Loc(fr: "Depuis mon inscription", en: "Since you joined")
        static let savedSummary = Loc(
            fr: "économisés • %d produits sauvés — estimations",
            en: "saved • %d items rescued — estimates"
        )
        static let challenges = Loc(fr: "Défis Zéro Gaspi", en: "Zero Waste Challenges")
        static let challengesSubtitle = Loc(
            fr: "%d missions accomplies",
            en: "%d challenges completed"
        )
        static let shoppingSubtitle = Loc(
            fr: "%d articles à acheter",
            en: "%d items to buy"
        )
        static let reminders = Loc(fr: "Rappels anti-gaspi", en: "Expiration Reminders")
        static let remindersOff = Loc(fr: "Désactivés", en: "Turned off")
        static let remindersOn = Loc(
            fr: "Prévenu avant chaque date",
            en: "Heads-up before every date"
        )
        static let preferences = Loc(fr: "Préférences du foyer", en: "Household Preferences")
        static let preferencesSubtitle = Loc(
            fr: "Régime, allergies, budget",
            en: "Diet, allergies, budget"
        )
        static let information = Loc(fr: "Informations", en: "Information")
        static let terms = Loc(fr: "Conditions d'utilisation", en: "Terms of Use")
        static let privacy = Loc(fr: "Politique de confidentialité", en: "Privacy Policy")
        static let support = Loc(fr: "Support", en: "Support")
        static let version = Loc(fr: "Version", en: "Version")
        static let tagline = Loc(
            fr: "Scanne tes courses. Cuisine ton stock. Jette moins.",
            en: "Scan your groceries. Cook what you have. Waste less."
        )
    }

    // MARK: - Settings

    nonisolated enum Settings {
        static let navTitle = Loc(fr: "Préférences", en: "Preferences")
        static let adults = Loc(fr: "Adultes", en: "Adults")
        static let children = Loc(fr: "Enfants", en: "Children")
        static let goal = Loc(fr: "Objectif", en: "Goal")
        static let diet = Loc(fr: "Régime", en: "Diet")
        static let language = Loc(fr: "Langue", en: "Language")
        static let languageNote = Loc(
            fr: "Change uniquement la langue de l'application. Ton stock, tes dates et ton abonnement restent intacts.",
            en: "Changes the app's language only. Your food, your dates and your subscription stay exactly as they are."
        )
        static let weeklyBudget = Loc(
            fr: "Budget courses hebdomadaire",
            en: "Weekly grocery budget"
        )
        static let allergies = Loc(fr: "Allergies", en: "Allergies")
        static let dislikes = Loc(fr: "Je ne mange pas", en: "I don't eat")
        static let replayOnboarding = Loc(
            fr: "Refaire l'introduction",
            en: "Replay the intro"
        )
    }

    // MARK: - Product lookup

    nonisolated enum Lookup {
        static let notFound = Loc(
            fr: "Produit introuvable dans la base.",
            en: "We couldn't find that item in the database."
        )
        static let network = Loc(
            fr: "Connexion impossible pour l'instant.",
            en: "Can't reach the database right now."
        )
        static let fallbackName = Loc(fr: "Produit %@", en: "Item %@")
    }

    // MARK: - Grocery scanning

    nonisolated enum Scan {
        static let title = Loc(fr: "Scanner mes courses", en: "Scan Groceries")
        static let manualEntryTitle = Loc(fr: "Saisir un code-barres", en: "Enter a barcode")
        static let manualEntryPlaceholder = Loc(fr: "Ex. 3017620422003", en: "e.g. 041196910184")
        static let searchAction = Loc(fr: "Rechercher", en: "Look up")
        static let cameraDeniedTitle = Loc(fr: "Accès caméra refusé", en: "Camera access denied")
        static let cameraDeniedMessage = Loc(
            fr: "Autorise la caméra dans Réglages pour scanner tes codes-barres, ou saisis-les à la main.",
            en: "Allow camera access in Settings to scan barcodes, or type them in by hand."
        )
        static let noCameraTitle = Loc(fr: "Aucune caméra détectée", en: "No camera found")
        static let noCameraMessage = Loc(
            fr: "Tu peux saisir un code-barres ou utiliser les produits de démonstration ci-dessous.",
            en: "You can type a barcode or try the sample items below."
        )
        static let cameraFailedTitle = Loc(fr: "Caméra indisponible", en: "Camera unavailable")
        static let cameraFailedMessage = Loc(
            fr: "Réessaie plus tard, ou ajoute tes produits manuellement.",
            en: "Try again later, or add your items by hand."
        )
        static let searching = Loc(fr: "Recherche du produit %@…", en: "Looking up item %@…")
        static let aimHint = Loc(
            fr: "Vise un code-barres, il s'ajoute tout seul",
            en: "Point at a barcode — it adds itself"
        )
        static let itemsAdded = Loc(fr: "produit ajouté", en: "item added")
        static let itemsAddedPlural = Loc(fr: "produits ajoutés", en: "items added")
        static let runTotal = Loc(
            fr: "Courses enregistrées : %@ — estimation",
            en: "Groceries logged: %@ — estimate"
        )
        static let noDate = Loc(fr: "• sans date", en: "• no date")
        static let demoHint = Loc(
            fr: "Pas de code-barres sous la main ? Essaie :",
            en: "No barcode handy? Try one of these:"
        )
        static let duplicateTitle = Loc(fr: "Tu en as déjà", en: "You already have this")
        static let duplicateBody = Loc(
            fr: "Tu as déjà %@ dans %@.",
            en: "You already have %@ in the %@."
        )
        static let dontAdd = Loc(fr: "Ne pas ajouter", en: "Don't add")
        static let addAnyway = Loc(fr: "Ajouter quand même", en: "Add anyway")
        static let finish = Loc(fr: "Terminer mes courses", en: "Finish scanning")
        static let autoAddNote = Loc(
            fr: "Chaque produit rejoint automatiquement ton stock.",
            en: "Every item goes straight into your food list."
        )

        // Review step
        static let reviewTitle = Loc(fr: "Mes courses", en: "My Groceries")
        static let resumeScan = Loc(fr: "Reprendre le scan", en: "Back to scanning")
        static let nothingScannedTitle = Loc(fr: "Rien de scanné", en: "Nothing scanned")
        static let nothingScannedMessage = Loc(
            fr: "Reviens au scanner pour enregistrer tes courses.",
            en: "Head back to the scanner to log your groceries."
        )
        static let reviewDateNote = Loc(
            fr: "Les dates viennent de l'emballage. SAVEAT ne détermine jamais si un aliment est encore consommable.",
            en: "Dates come from the package. SAVEAT never decides whether food is still safe to eat."
        )
        static let itemsCount = Loc(fr: "%d produits", en: "%d items")
        static let runLogged = Loc(fr: "Courses enregistrées : %@", en: "Groceries logged: %@")
        static let withoutDate = Loc(fr: "sans date", en: "no date")
        static let addDate = Loc(fr: "Ajouter la date", en: "Add the date")
        static let addToStock = Loc(fr: "Ajouter à mon stock", en: "Add to my food")
        static let addToStockNote = Loc(
            fr: "Ton stock sera à jour et l'IA pourra cuisiner avec.",
            en: "Your food list updates, and the AI can cook with it."
        )

        // Scanned line editor
        static let editorTitle = Loc(fr: "Détail du produit", en: "Item details")
        static let seeNutrition = Loc(
            fr: "Voir l'analyse nutritionnelle",
            en: "See the nutrition breakdown"
        )
        static let photographDate = Loc(
            fr: "Photographier la date",
            en: "Photograph the date"
        )
        static let captureTitle = Loc(fr: "Photographier la date", en: "Photograph the date")
        static let captureHint = Loc(
            fr: "Cadre la date imprimée sur l'emballage",
            en: "Line up the date printed on the package"
        )
        static let captureFailed = Loc(
            fr: "Date non reconnue — réessaie ou saisis-la à la main",
            en: "Couldn't read the date — try again or type it in"
        )
        static let captureDeniedDetail = Loc(
            fr: "Autorise la caméra dans Réglages, ou saisis la date à la main.",
            en: "Allow camera access in Settings, or type the date in by hand."
        )
        static let captureNoDeviceDetail = Loc(
            fr: "Saisis la date manuellement dans la fiche du produit.",
            en: "Enter the date by hand on the item screen."
        )
        static let captureFailedDetail = Loc(
            fr: "Réessaie plus tard ou saisis la date à la main.",
            en: "Try again later, or type the date in by hand."
        )
        static let takePhoto = Loc(fr: "Prendre la photo", en: "Take the photo")
        static let dateDetected = Loc(fr: "Date détectée", en: "Date found")
        static let checkDate = Loc(
            fr: "Vérifie qu'elle correspond bien à l'emballage.",
            en: "Double-check it matches the package."
        )
        static let confirm = Loc(fr: "Confirmer", en: "Confirm")
        static let retakePhoto = Loc(fr: "Reprendre la photo", en: "Retake photo")
        static let editorDateNote = Loc(
            fr: "La date est lue sur l'emballage puis confirmée par toi. SAVEAT ne juge jamais la fraîcheur à partir d'une photo et n'invente jamais de date.",
            en: "The date is read off the package and confirmed by you. SAVEAT never judges freshness from a photo and never makes a date up."
        )
    }

    // MARK: - Tight budget planner

    nonisolated enum EndOfMonth {
        static let navTitle = Loc(fr: "Fin de mois", en: "Tight Budget")
        static let introTitle = Loc(
            fr: "Il te reste peu, on fait durer.",
            en: "Not much left? Let's stretch it."
        )
        static let introBody = Loc(
            fr: "SAVEAT part de ton stock actuel avant de dépenser le moindre euro.",
            en: "SAVEAT starts from the food you already have before spending a cent."
        )
        static let calculate = Loc(fr: "Calculer mon plan", en: "Build my plan")
        static let recalculate = Loc(fr: "Recalculer", en: "Rebuild plan")
        static let iHaveLeft = Loc(fr: "Il me reste", en: "I have left")
        static let until = Loc(fr: "Jusqu'au", en: "Until")
        static let forPeople = Loc(fr: "Pour", en: "For")
        static let daysToCover = Loc(
            fr: "%d jour • %d repas à couvrir",
            en: "%d day • %d meals to cover"
        )
        static let daysToCoverPlural = Loc(
            fr: "%d jours • %d repas à couvrir",
            en: "%d days • %d meals to cover"
        )
        static let goodNews = Loc(fr: "Bonne nouvelle", en: "Good news")
        static let alreadyCook = Loc(
            fr: "Avec ton stock actuel, tu peux déjà préparer",
            en: "With what you already have, you can make"
        )
        static let mealsWord = Loc(fr: "repas", en: "meals")
        static let groceriesNeeded = Loc(
            fr: "Courses nécessaires estimées",
            en: "Estimated groceries needed"
        )
        static let budgetLeft = Loc(fr: "Budget restant", en: "Budget left")
        static let overBudget = Loc(
            fr: "Le plan dépasse ton budget : j'ai déjà retiré les articles les plus chers. Ajuste les repas ou la période.",
            en: "This plan runs over budget — I already dropped the priciest items. Try adjusting the meals or the dates."
        )
        static let essentials = Loc(fr: "Le strict nécessaire", en: "Just the essentials")
        static let mealPlan = Loc(fr: "Ton plan de repas", en: "Your meal plan")
        static let dayPrefix = Loc(fr: "J%d", en: "D%d")
        static let lunchShort = Loc(fr: "midi", en: "lunch")
        static let dinnerShort = Loc(fr: "soir", en: "dinner")
        static let lunch = Loc(fr: "Déjeuner", en: "Lunch")
        static let dinner = Loc(fr: "Dîner", en: "Dinner")
        static let stockOnly = Loc(
            fr: "%@ — uniquement ton stock",
            en: "%@ — all from your own food"
        )
        static let extraCost = Loc(fr: "~%@ de complément", en: "~%@ to top up")
        static let disclaimer = Loc(
            fr: "Tous les montants sont des estimations basées sur des prix moyens français. Ils t'aident à décider, ils ne remplacent pas tes tickets de caisse.",
            en: "All amounts are estimates based on average grocery prices. They're here to help you decide — they don't replace your receipts."
        )
    }

    // MARK: - Smart shopping

    nonisolated enum Shopping {
        static let navTitle = Loc(fr: "Courses intelligentes", en: "Smart Shopping")
        static let stockTab = Loc(fr: "Ce qu'il me reste", en: "What I have")
        static let missingTab = Loc(fr: "Ce qu'il me manque", en: "What I need")
        static let emptyTitle = Loc(fr: "Ta liste est vide", en: "Your list is empty")
        static let emptyMessage = Loc(
            fr: "Bonne nouvelle : tu as déjà de quoi cuisiner. Ajoute le manquant depuis un repas.",
            en: "Good news: you already have enough to cook. Add what's missing from a recipe."
        )
        static let clearChecked = Loc(
            fr: "Retirer les articles cochés",
            en: "Remove checked items"
        )
        static let priceNote = Loc(
            fr: "Prix estimés à partir de moyennes françaises. Ta liste ne contient jamais ce que tu as déjà chez toi.",
            en: "Prices are estimates based on average grocery prices. Your list never includes what you already have."
        )
        static let itemsCount = Loc(fr: "%d produits", en: "%d items")
        static let estimatedValue = Loc(fr: "valeur estimée %@", en: "estimated value %@")
        static let locationCount = Loc(fr: "%@ — %d", en: "%@ — %d")
        static let duplicateWarning = Loc(
            fr: "Au magasin, si tu scannes un produit déjà présent ici, SAVEAT te prévient : « Tu as déjà ce produit chez toi. »",
            en: "At the store, scanning something you already own gets you a heads-up: \"You already have this at home.\""
        )
        static let estimatedTotal = Loc(fr: "Total estimé", en: "Estimated total")
        static let weeklyBudget = Loc(fr: "Budget hebdo", en: "Weekly budget")
        static let reasonPrefix = Loc(fr: "pour %@", en: "for %@")
        static let suggestionSection = Loc(
            fr: "Complète peu, cuisine plus",
            en: "Buy a little, cook a lot"
        )
    }

    // MARK: - Meal assistant

    nonisolated enum Assistant {
        static let title = Loc(fr: "Qu'est-ce qu'on mange ?", en: "What's for dinner?")
        static let subtitle = Loc(
            fr: "Je cuisine avec tes %d produits",
            en: "Cooking with the %d items you have"
        )
        static let servingsLabel = Loc(fr: "Personnes", en: "Servings")
        static let zeroCostPrompt = Loc(
            fr: "Uniquement avec ce que j'ai, sans rien acheter",
            en: "Only what I already have, without buying anything"
        )
        static let servingsPrompt = Loc(fr: "Pour %d personnes", en: "For %d servings")
        static let quotaLeft = Loc(
            fr: "%d suggestion IA restante aujourd'hui",
            en: "%d AI suggestion left today"
        )
        static let quotaLeftPlural = Loc(
            fr: "%d suggestions IA restantes aujourd'hui",
            en: "%d AI suggestions left today"
        )
        static let premium = Loc(fr: "Premium", en: "Go Pro")
        static let quotaSpent = Loc(
            fr: "Tes %d suggestions IA du jour sont utilisées. Les idées ci-dessous restent basées sur ton stock.",
            en: "You've used your %d AI suggestions for today. The ideas below still come from your own food."
        )
        static let rescueCount = Loc(fr: "%d produits à sauver", en: "%d items to use soon")
        static let rescuePrompt = Loc(
            fr: "Utilise en priorité ce qui va se perdre",
            en: "Use up what's about to go bad first"
        )
        static let rescueLine = Loc(
            fr: "Je peux préparer ton dîner avec ces aliments avant qu'ils ne soient gaspillés.",
            en: "I can build tonight's dinner around these before they go to waste."
        )
        static let thinking = Loc(fr: "Je regarde ton stock…", en: "Checking what you have…")
        static let mealsFound = Loc(fr: "%d repas trouvés", en: "%d meals found")
        static let offlineMode = Loc(fr: "mode hors ligne", en: "offline mode")
        static let quickAskSection = Loc(fr: "Dis-moi ce que tu veux", en: "Tell me what you're after")
        static let composerPlaceholder = Loc(fr: "Écris ta demande…", en: "Type your request…")
        static let send = Loc(fr: "Envoyer", en: "Send")
        static let userLabel = Loc(fr: "Utilisateur", en: "User")
        static let emptyAnswer = Loc(
            fr: "Ton stock est un peu court pour cette demande. Scanne tes courses et je te proposerai des repas.",
            en: "There isn't quite enough on hand for that. Scan your groceries and I'll come back with meals."
        )
        static let zeroCostAnswer = Loc(
            fr: "J'ai trouvé %d repas à %@ avec ton stock. Aucun achat nécessaire.",
            en: "Found %d %@ meals from what you have. Nothing to buy."
        )
        static let defaultAnswer = Loc(
            fr: "J'ai trouvé %d repas avec ce que tu as.",
            en: "Found %d meals from what you already have."
        )

        static let quickAsks: [Loc] = [
            Loc(fr: "Quelque chose de rapide ce soir", en: "Something quick tonight"),
            Loc(fr: "Maximum 15 minutes", en: "15 minutes max"),
            Loc(fr: "Sans viande", en: "No meat"),
            Loc(fr: "Riche en protéines", en: "High protein"),
            Loc(fr: "Moins de 500 kcal", en: "Under 500 calories"),
            Loc(fr: "Repas économique", en: "Budget friendly"),
            Loc(fr: "Pour les enfants", en: "Kid friendly"),
            Loc(fr: "Quelque chose de réconfortant", en: "Something comforting"),
            Loc(fr: "Repas léger", en: "Something light"),
            Loc(fr: "Sans lactose", en: "Dairy free")
        ]
    }

    // MARK: - $0 meals

    nonisolated enum ZeroCost {
        static let navTitle = Loc(fr: "Repas à 0 €", en: "$0 Meals")
        static let heroTitle = Loc(fr: "Repas à 0 €", en: "$0 Meals")
        static let heroSubtitle = Loc(
            fr: "On cuisine uniquement avec ce que tu as déjà.",
            en: "We cook with what you already have — nothing else."
        )
        static let noPurchase = Loc(fr: "Aucun achat nécessaire.", en: "Nothing to buy.")
        static let emptyTitle = Loc(
            fr: "Pas encore de repas complet",
            en: "No complete meal yet"
        )
        static let emptyMessage = Loc(
            fr: "Il manque quelques bases dans ton stock. Scanne tes courses et je trouverai des repas sans dépenser un euro.",
            en: "A few basics are missing. Scan your groceries and I'll find meals that cost you nothing."
        )
        static let loading = Loc(
            fr: "Je cherche des repas gratuits dans ton stock…",
            en: "Looking for free meals in your kitchen…"
        )
        static let prompt = Loc(
            fr: "Propose uniquement des repas réalisables sans acheter quoi que ce soit.",
            en: "Only suggest meals I can make without buying anything."
        )
        static let promise = Loc(
            fr: "En mode Repas à 0 €, SAVEAT ne te proposera jamais d'acheter quoi que ce soit. Les basiques du placard (sel, poivre, huile) sont considérés comme déjà présents.",
            en: "In $0 Meals, SAVEAT will never ask you to buy anything. Pantry basics (salt, pepper, oil) are assumed to be on hand."
        )
    }

    // MARK: - Impact & savings

    nonisolated enum Impact {
        static let ofYourGoal = Loc(fr: "de ton objectif", en: "of your goal")
        static let weeklyGoal = Loc(fr: "Objectif hebdomadaire", en: "Weekly goal")
        static let percent = Loc(fr: "%d pour cent", en: "%d percent")

        static let navTitle = Loc(fr: "Mes économies", en: "My Savings")
        static let thisWeek = Loc(fr: "Cette semaine", en: "This week")
        static let savedItems = Loc(fr: "produits sauvés", en: "items rescued")
        static let mealsCooked = Loc(fr: "repas préparés", en: "meals cooked")
        static let moneySaved = Loc(fr: "économisés", en: "saved")
        static let wasteAvoided = Loc(
            fr: "≈ %@ de gaspillage évité (estimation)",
            en: "About %@ of food waste avoided (estimate)"
        )
        static let sinceJoining = Loc(fr: "Depuis mon inscription", en: "Since you joined")
        static let lifetimeNote = Loc(
            fr: "économisés — estimation basée sur la valeur des aliments sauvés",
            en: "saved — estimated from the value of the food you used in time"
        )
        static let itemsPill = Loc(fr: "%d produits sauvés", en: "%d items rescued")
        static let mealsPill = Loc(fr: "%d repas", en: "%d meals")
        static let shareCard = Loc(fr: "Ma carte à partager", en: "My share card")
        static let shareTagline = Loc(
            fr: "Mange ce que tu as. Achète ce qu'il te manque.",
            en: "Eat what you have. Buy only what's missing."
        )
        static let shareAction = Loc(
            fr: "Partager mon résultat",
            en: "Share my results"
        )
        static let historySection = Loc(
            fr: "Derniers repas cuisinés",
            en: "Recently cooked"
        )
        static let disclaimer = Loc(
            fr: "Toutes les valeurs sont des estimations calculées à partir des prix moyens et du poids moyen des produits que tu sauves.",
            en: "All figures are estimates, based on average prices and average weights for the items you use in time."
        )
    }

    // MARK: - Product & score

    nonisolated enum Product {
        static let saveatScore = Loc(fr: "Score SAVEAT", en: "SAVEAT Score")
        static let scoreValue = Loc(fr: "%d sur 100, %@", en: "%d out of 100, %@")
        static let unnamed = Loc(fr: "Produit sans nom", en: "Unnamed item")
        static let navTitle = Loc(fr: "Fiche produit", en: "Item Details")
        static let demoSheet = Loc(fr: "Fiche de démonstration", en: "Sample item")
        static let openDatabase = Loc(fr: "Base de données ouverte", en: "Open food database")
        static let partialData = Loc(
            fr: "Données partielles pour ce produit — le score reste indicatif.",
            en: "Only partial data for this item — treat the score as a rough guide."
        )
        static let nutriScorePill = Loc(fr: "Nutri-Score %@", en: "Nutri-Score %@")
        static let additivePill = Loc(fr: "%d additif", en: "%d additive")
        static let additivesPill = Loc(fr: "%d additifs", en: "%d additives")
        static let analysisSection = Loc(
            fr: "Analyse nutritionnelle",
            en: "Nutrition breakdown"
        )
        static let positives = Loc(fr: "Points positifs", en: "What's good")
        static let watchOuts = Loc(fr: "Points à surveiller", en: "What to watch")
        static let additivesSection = Loc(fr: "Additifs", en: "Additives")
        static let officialNutriScore = Loc(
            fr: "Nutri-Score officiel %@",
            en: "European Nutri-Score %@"
        )
        static let nutriScoreAccessibility = Loc(
            fr: "Nutri-Score officiel",
            en: "European Nutri-Score"
        )
        static let nutriScoreLabel = Loc(fr: "Nutri-Score", en: "Nutri-Score")
        static let appreciation = Loc(fr: "Appréciation", en: "Overall read")
        static let whyThisScore = Loc(
            fr: "Pourquoi cette note ?",
            en: "Why this score?"
        )
        static let valuesPer100g = Loc(
            fr: "Valeurs pour 100 g",
            en: "Values per 100 g (about 3.5 oz)"
        )
        static let energy = Loc(fr: "Énergie", en: "Calories")
        static let carbsSugars = Loc(fr: "Glucides — sucres", en: "Sugars")
        static let fat = Loc(fr: "Matières grasses", en: "Total fat")
        static let ofWhichSaturated = Loc(fr: "dont saturées", en: "of which saturated")
        static let allergensSection = Loc(
            fr: "Allergènes déclarés",
            en: "Declared allergens"
        )
        static let ingredientsSection = Loc(fr: "Ingrédients", en: "Ingredients")
        static let disclaimer = Loc(
            fr: "Informations issues de bases de données publiques et de l'étiquetage. Le score SAVEAT est une aide à la lecture, pas un avis médical. Réfère-toi toujours à l'emballage.",
            en: "Information comes from public food databases and package labeling. The SAVEAT score is a reading aid, not medical advice. Always go by the package itself."
        )

        // Score labels
        static let excellent = Loc(fr: "Excellent choix", en: "Excellent choice")
        static let good = Loc(fr: "Bon produit", en: "Good pick")
        static let fine = Loc(fr: "Correct", en: "Okay")
        static let limit = Loc(fr: "À limiter", en: "Go easy on it")
        static let rarely = Loc(fr: "À consommer rarement", en: "Once in a while")

        // Criteria titles
        static let nutrition = Loc(fr: "Nutrition", en: "Nutrition")
        static let sugars = Loc(fr: "Sucres", en: "Sugars")
        static let salt = Loc(fr: "Sel", en: "Sodium")
        static let saturatedFat = Loc(fr: "Graisses saturées", en: "Saturated fat")
        static let proteins = Loc(fr: "Protéines", en: "Protein")
        static let fiber = Loc(fr: "Fibres", en: "Fiber")
        static let processing = Loc(fr: "Transformation", en: "Processing")
        static let additives = Loc(fr: "Additifs identifiés", en: "Additives listed")

        // Verdicts
        static let veryGood = Loc(fr: "Très bonne", en: "Very good")
        static let goodVerdict = Loc(fr: "Bonne", en: "Good")
        static let average = Loc(fr: "Moyenne", en: "Average")
        static let weak = Loc(fr: "Faible", en: "Poor")
        static let veryWeak = Loc(fr: "Très faible", en: "Very poor")
        static let low = Loc(fr: "Faibles", en: "Low")
        static let moderate = Loc(fr: "Modérés", en: "Moderate")
        static let high = Loc(fr: "Élevés", en: "High")
        static let veryHigh = Loc(fr: "Très élevés", en: "Very high")
        static let lowSingular = Loc(fr: "Faible", en: "Low")
        static let moderateSingular = Loc(fr: "Modéré", en: "Moderate")
        static let highSingular = Loc(fr: "Élevé", en: "High")
        static let veryHighSingular = Loc(fr: "Très élevé", en: "Very high")
        static let interesting = Loc(fr: "Intéressantes", en: "Worth noting")
        static let goodSource = Loc(fr: "Bonne source", en: "Good source")
        static let rawFood = Loc(fr: "Aliment brut", en: "Whole food")
        static let lightlyProcessed = Loc(fr: "Peu transformé", en: "Lightly processed")
        static let processed = Loc(fr: "Transformé", en: "Processed")
        static let ultraProcessed = Loc(fr: "Ultra-transformé", en: "Ultra-processed")

        // Criterion details
        /// English deliberately avoids the Nutri-Score name: it is a European
        /// label with no standing in the US, so naming it would mislead.
        static let nutriScorePublished = Loc(
            fr: "Nutri-Score %@ publié pour ce produit.",
            en: "Based on the nutrition profile published for this item."
        )
        static let per100g = Loc(fr: "%@ pour 100 g.", en: "%@ per 100 g (about 3.5 oz).")
        static let novaDetail = Loc(
            fr: "Classification NOVA du degré de transformation.",
            en: "NOVA classification of how processed this food is."
        )
        static let novaTitle = Loc(fr: "NOVA %d — %@", en: "NOVA %d — %@")
        static let noAdditives = Loc(
            fr: "Aucun additif listé dans la base de données.",
            en: "No additives listed in the food database."
        )

        // Methodology
        static let methodology: [Loc] = [
            Loc(
                fr: "On part de 50 points, puis on ajoute ou retire des points selon les données publiques du produit.",
                en: "We start at 50 points, then add or subtract based on the item's published data."
            ),
            Loc(
                fr: "Le Nutri-Score officiel pèse le plus lourd quand il est publié.",
                en: "The published nutrition profile carries the most weight when it exists."
            ),
            Loc(
                fr: "Le groupe NOVA mesure le degré de transformation, pas la qualité gustative.",
                en: "The NOVA group measures how processed a food is, not how good it tastes."
            ),
            Loc(
                fr: "Chaque additif listé retire 3 points, dans la limite de 15.",
                en: "Each listed additive costs 3 points, up to 15."
            ),
            Loc(
                fr: "Sucres, sel et graisses saturées sont comparés aux repères pour 100 g.",
                en: "Sugars, sodium and saturated fat are compared against per-100 g benchmarks."
            ),
            Loc(
                fr: "SAVEAT n'est pas un avis médical et ne remplace pas l'étiquette du produit.",
                en: "SAVEAT is not medical advice and doesn't replace the label on the package."
            )
        ]
    }

    // MARK: - Nutrition analysis

    nonisolated enum Nutrition {
        static let unavailable = Loc(
            fr: "Information non disponible",
            en: "Information not available"
        )

        // Verdicts
        static let veryGood = Loc(fr: "Très bon", en: "Very good")
        static let good = Loc(fr: "Bon", en: "Good")
        static let average = Loc(fr: "Moyen", en: "Average")
        static let limit = Loc(fr: "À limiter", en: "Go easy on it")
        static let poor = Loc(
            fr: "Faible qualité nutritionnelle",
            en: "Low nutritional quality"
        )

        // Basis captions
        /// English never names Nutri-Score: it is a European label with no
        /// official standing in the US, and showing the letter could mislead.
        static let basisOfficial = Loc(
            fr: "D'après le Nutri-Score officiel %@ publié pour ce produit.",
            en: "Based on the official nutrition profile published for this item."
        )
        static let basisEstimated = Loc(
            fr: "Aucun Nutri-Score publié. Estimation SAVEAT à partir des %d valeurs nutritionnelles disponibles.",
            en: "No published profile. SAVEAT's own read of the %d nutrition values available."
        )
        static let basisEstimatedSingular = Loc(
            fr: "Aucun Nutri-Score publié. Estimation SAVEAT à partir de la %d valeur nutritionnelle disponible.",
            en: "No published profile. SAVEAT's own read of the %d nutrition value available."
        )
        static let basisUnavailable = Loc(
            fr: "Les données nutritionnelles de ce produit ne sont pas publiées.",
            en: "This item's nutrition data isn't published."
        )

        // Additives
        static let noAdditivesListed = Loc(
            fr: "Aucun additif listé pour ce produit.",
            en: "No additives listed for this item."
        )
        static let additiveListed = Loc(
            fr: "%d additif listé dans la base de données.",
            en: "%d additive listed in the food database."
        )
        static let additivesListed = Loc(
            fr: "%d additifs listés dans la base de données.",
            en: "%d additives listed in the food database."
        )
        static let manyAdditives = Loc(fr: "Nombreux additifs", en: "Lots of additives")
        static let additivesCount = Loc(fr: "%d additifs listés", en: "%d additives listed")

        // Per-100 g wording. US readers get the ounce equivalent spelled out
        // rather than a fabricated per-serving figure.
        static let per100g = Loc(fr: "%@ pour 100 g", en: "%@ per 100 g (about 3.5 oz)")
        static let kcalPer100g = Loc(
            fr: "%d kcal pour 100 g",
            en: "%d calories per 100 g (about 3.5 oz)"
        )
        static let servingNote = Loc(
            fr: "Valeurs publiées pour 100 g par la base de données produit.",
            en: "Values are published per 100 g by the food database, not per serving as on a US Nutrition Facts label."
        )

        // Points
        static let lowSugar = Loc(fr: "Peu de sucres", en: "Low in sugar")
        static let highSugar = Loc(fr: "Sucres élevés", en: "High in sugar")
        static let veryHighSugar = Loc(fr: "Sucres très élevés", en: "Very high in sugar")
        static let lowSalt = Loc(fr: "Peu de sel", en: "Low in sodium")
        static let highSalt = Loc(fr: "Sel élevé", en: "High in sodium")
        static let veryHighSalt = Loc(fr: "Sel très élevé", en: "Very high in sodium")
        static let lowSaturated = Loc(
            fr: "Peu de graisses saturées",
            en: "Low in saturated fat"
        )
        static let highSaturated = Loc(
            fr: "Graisses saturées élevées",
            en: "High in saturated fat"
        )
        static let veryHighSaturated = Loc(
            fr: "Graisses saturées très élevées",
            en: "Very high in saturated fat"
        )
        static let lowCalorie = Loc(fr: "Peu calorique", en: "Low calorie")
        static let calorieDense = Loc(
            fr: "Densité calorique élevée",
            en: "Calorie dense"
        )
        static let veryCalorie = Loc(fr: "Très calorique", en: "Very high in calories")
        static let richFiber = Loc(fr: "Riche en fibres", en: "High in fiber")
        static let sourceFiber = Loc(fr: "Source de fibres", en: "Good source of fiber")
        static let goodProtein = Loc(
            fr: "Teneur intéressante en protéines",
            en: "Solid protein content"
        )
        static let novaWhole = Loc(
            fr: "Aliment brut ou peu transformé",
            en: "Whole or barely processed food"
        )
        static let novaCulinary = Loc(
            fr: "Ingrédient culinaire peu transformé",
            en: "Lightly processed cooking ingredient"
        )
        static let novaUltra = Loc(
            fr: "Produit ultra-transformé",
            en: "Ultra-processed food"
        )
        static let novaGroup = Loc(fr: "Groupe NOVA %d", en: "NOVA group %d")

        // Missing facts
        static let missingSugars = Loc(fr: "sucres", en: "sugars")
        static let missingSalt = Loc(fr: "sel", en: "sodium")
        static let missingSaturated = Loc(fr: "graisses saturées", en: "saturated fat")
        static let missingCalories = Loc(fr: "calories", en: "calories")
        static let missingFiber = Loc(fr: "fibres", en: "fiber")
        static let missingProteins = Loc(fr: "protéines", en: "protein")

        // Explanation sentences
        static let notEnoughData = Loc(
            fr: "Ce produit ne publie pas assez de données nutritionnelles pour être analysé. SAVEAT préfère ne rien afficher plutôt que d'estimer une qualité qu'il ne peut pas vérifier.",
            en: "This item doesn't publish enough nutrition data to analyze. SAVEAT would rather show nothing than guess at a quality it can't verify."
        )
        static let officialSentence = Loc(
            fr: "Nutri-Score %@ officiel : %@ sur le plan nutritionnel.",
            en: "Published European Nutri-Score %@: %@ nutritionally."
        )
        static let estimatedSentence = Loc(
            fr: "Sans Nutri-Score publié, les valeurs disponibles situent ce produit à un niveau %@.",
            en: "With no published score, the available values put this item at a %@ level."
        )
        static let inItsFavor = Loc(fr: "Ce qui joue en sa faveur : %@.", en: "In its favor: %@.")
        static let watchOut = Loc(fr: "À surveiller : %@.", en: "Worth watching: %@.")
        static let nothingNotable = Loc(
            fr: "Rien de particulier à signaler dans les valeurs publiées.",
            en: "Nothing unusual in the published values."
        )
        static let notPublished = Loc(
            fr: "Non publié pour ce produit : %@.",
            en: "Not published for this item: %@."
        )
        static let closingGood = Loc(
            fr: "Une bonne base à garder au frais et à cuisiner avant sa date.",
            en: "A solid staple — keep it cold and cook it before its date."
        )
        static let closingAverage = Loc(
            fr: "Correct au quotidien, surtout accompagné de produits frais de ton stock.",
            en: "Fine for everyday cooking, especially alongside fresh food you already have."
        )
        static let closingLimit = Loc(
            fr: "À garder pour les petits plaisirs, en petite quantité — et à finir avant de le jeter.",
            en: "Save it for a treat, in small amounts — and finish it rather than tossing it."
        )
        static let andJoiner = Loc(fr: " et ", en: " and ")
    }

    // MARK: - Inventory

    nonisolated enum Inventory {
        static let openedBullet = Loc(fr: "• entamé", en: "• opened")
        static let title = Loc(fr: "Mon stock", en: "My Food")
        static let searchPrompt = Loc(fr: "Chercher un produit", en: "Search your food")
        static let subtitle = Loc(
            fr: "%d produits • valeur estimée %@",
            en: "%d items • estimated value %@"
        )
        static let scanAccessibility = Loc(fr: "Scanner mes courses", en: "Scan groceries")
        static let rescueCount = Loc(fr: "%d produit à sauver", en: "%d item to use soon")
        static let rescueCountPlural = Loc(fr: "%d produits à sauver", en: "%d items to use soon")
        static let findMeal = Loc(fr: "Trouver un repas", en: "Find a recipe")
        static let addManually = Loc(
            fr: "Ajouter un produit manuellement",
            en: "Add an item manually"
        )
        static let emptyTitle = Loc(fr: "%@ : rien pour l'instant", en: "%@: nothing here yet")
        static let noResults = Loc(fr: "Aucun résultat", en: "No results")
        static let emptyMessage = Loc(
            fr: "Scanne tes courses en rentrant : chaque code-barres remplit ton stock automatiquement.",
            en: "Scan your groceries when you get home — every barcode fills this in for you."
        )
        static let noResultsMessage = Loc(
            fr: "Essaie un autre nom de produit.",
            en: "Try a different item name."
        )
    }

    // MARK: - Item detail

    nonisolated enum FoodDetail {
        static let removeConfirmTitle = Loc(
            fr: "Retirer ce produit de ton stock ?",
            en: "Remove this item from your food?"
        )
        static let remove = Loc(fr: "Retirer", en: "Remove")
        static let discardConfirmTitle = Loc(fr: "Jeter ce produit ?", en: "Throw this item away?")
        static let discardConfirmMessage = Loc(
            fr: "Il sera retiré de ton stock et ne comptera pas comme produit sauvé.",
            en: "It will leave your food list and won't count as an item you used in time."
        )
        static let savedNote = Loc(
            fr: "« Sauvé » met ton stock à jour et arrête les rappels de ce produit.",
            en: "\"Used it\" updates your food list and stops the reminders for this item."
        )
        static let scoreRow = Loc(fr: "Score SAVEAT — %@", en: "SAVEAT Score — %@")
        static let scoreSubtitle = Loc(
            fr: "Nutrition, additifs, transformation",
            en: "Nutrition, additives, processing"
        )
        static let remainingQuantity = Loc(fr: "Quantité restante", en: "Quantity left")
        static let opened = Loc(fr: "Produit entamé", en: "Already opened")
        static let dateNote = Loc(
            fr: "Les dates proviennent de l'emballage ou de toi. SAVEAT ne peut pas déterminer si un aliment est encore bon à partir d'une photo.",
            en: "Dates come from the package or from you. SAVEAT can't tell from a photo whether food is still good."
        )
        static let cookWithThis = Loc(fr: "Cuisiner avec ce produit", en: "Cook with this")
        static let removeFromStock = Loc(fr: "Retirer de mon stock", en: "Remove from my food")
    }

    // MARK: - Add an item by hand

    nonisolated enum AddFood {
        static let navTitle = Loc(fr: "Nouveau produit", en: "New Item")
        static let productSection = Loc(fr: "Produit", en: "Item")
        static let namePlaceholder = Loc(fr: "Nom du produit", en: "Item name")
        static let quantity = Loc(fr: "Quantité", en: "Quantity")
        static let unit = Loc(fr: "Unité", en: "Unit")
        static let unitPlaceholder = Loc(fr: "pièce", en: "count")
        static let storage = Loc(fr: "Rangement", en: "Stored in")
        static let aisle = Loc(fr: "Rayon", en: "Category")
        static let dateSection = Loc(fr: "Date de consommation", en: "Date on the package")
        static let hasDate = Loc(fr: "Date renseignée", en: "Date entered")
        static let dateType = Loc(fr: "Type de date", en: "Kind of date")
        static let dateNote = Loc(
            fr: "La date vient de l'emballage ou de toi. SAVEAT ne devine jamais la fraîcheur d'un aliment.",
            en: "The date comes from the package or from you. SAVEAT never guesses how fresh something is."
        )
        static let addToStock = Loc(fr: "Ajouter à mon stock", en: "Add to my food")
    }

    // MARK: - Meals & recipes

    nonisolated enum Meals {
        static let servings = Loc(fr: "%d personne", en: "%d serving")
        static let servingsPlural = Loc(fr: "%d personnes", en: "%d servings")
        static let haveEverything = Loc(
            fr: "Tu as tout ce qu'il faut",
            en: "You have everything"
        )
        static let availability = Loc(
            fr: "%d/%d ingrédients chez toi",
            en: "%d of %d ingredients on hand"
        )
        static let rescueHighlight = Loc(
            fr: "Ce repas te permet d'utiliser %d produit à sauver.",
            en: "This meal uses up %d item you need to eat soon."
        )
        static let rescueHighlightPlural = Loc(
            fr: "Ce repas te permet d'utiliser %d produits à sauver.",
            en: "This meal uses up %d items you need to eat soon."
        )
        static let planHighlight = Loc(
            fr: "Ce repas utilise %d produit dont la date approche.",
            en: "This meal uses %d item whose date is coming up."
        )
        static let planHighlightPlural = Loc(
            fr: "Ce repas utilise %d produits dont la date approche.",
            en: "This meal uses %d items whose dates are coming up."
        )
        static let toSpend = Loc(fr: "à dépenser", en: "to spend")
        static let estimated = Loc(fr: "estimé", en: "estimated")

        static let prepLabel = Loc(fr: "préparation", en: "prep")
        static let cookLabel = Loc(fr: "cuisson", en: "cook")
        static let difficultyLabel = Loc(fr: "difficulté", en: "difficulty")
        static let servingsLabel = Loc(fr: "personne", en: "serving")
        static let servingsLabelPlural = Loc(fr: "personnes", en: "servings")
        static let noPurchase = Loc(fr: "Aucun achat nécessaire.", en: "Nothing to buy.")
        static let extraCostNote = Loc(
            fr: "Coût supplémentaire estimé pour compléter.",
            en: "Estimated extra cost to fill the gaps."
        )
        static let ingredients = Loc(fr: "Ingrédients", en: "Ingredients")
        static let staple = Loc(fr: "basique du placard", en: "pantry staple")
        static let inStock = Loc(fr: "dans ton stock", en: "you have this")
        static let toBuy = Loc(fr: "à acheter", en: "need to buy")
        static let missingCount = Loc(
            fr: "Il te manque %d ingrédient",
            en: "You're missing %d ingredient"
        )
        static let missingCountPlural = Loc(
            fr: "Il te manque %d ingrédients",
            en: "You're missing %d ingredients"
        )
        static let addToList = Loc(
            fr: "Ajouter à ma liste de courses",
            en: "Add to my shopping list"
        )
        static let stepsSection = Loc(fr: "Préparation", en: "Directions")
        static let nutritionSection = Loc(fr: "Repères nutritionnels", en: "Nutrition at a glance")
        static let kcalPerServing = Loc(fr: "kcal / personne", en: "calories / serving")
        static let proteins = Loc(fr: "protéines", en: "protein")
        static let costPerServing = Loc(fr: "coût / personne", en: "cost / serving")
        static let nutritionNote = Loc(
            fr: "Valeurs approximatives, calculées à partir de moyennes.",
            en: "Approximate values, based on averages."
        )
        static let cook = Loc(fr: "Cuisiner", en: "Cook this")

        static let cookNavTitle = Loc(fr: "Repas terminé ?", en: "Meal done?")
        static let notYet = Loc(fr: "Pas encore", en: "Not yet")
        static let nothingToDeduct = Loc(fr: "Rien à déduire", en: "Nothing to deduct")
        static let nothingToDeductMessage = Loc(
            fr: "Ce repas n'utilise aucun produit identifié dans ton stock.",
            en: "This meal doesn't use anything we could match to your food."
        )
        static let adjustNote = Loc(
            fr: "Ajuste librement les quantités : ton stock doit refléter ce que tu as vraiment consommé.",
            en: "Adjust the amounts freely — your food list should match what you actually used."
        )
        static let cookIntro = Loc(
            fr: "Je mets ton stock à jour avec ce que tu as utilisé.",
            en: "I'll update your food with whatever you used."
        )
        static let before = Loc(fr: "Avant : %@ %@", en: "Before: %@ %@")
        static let after = Loc(fr: "Nouveau stock : %@ %@", en: "Now: %@ %@")
        static let itemsUpdated = Loc(fr: "%d produit mis à jour", en: "%d item updated")
        static let itemsUpdatedPlural = Loc(fr: "%d produits mis à jour", en: "%d items updated")
        static let zeroCostSummary = Loc(
            fr: "Repas à %@ — aucun achat",
            en: "%@ meal — nothing bought"
        )
        static let extraSummary = Loc(fr: "Complément estimé : %@", en: "Estimated extra: %@")
        static let confirmCook = Loc(
            fr: "Oui, mettre mon stock à jour",
            en: "Yes, update my food"
        )
        static let savingsNote = Loc(
            fr: "Tes économies sont mises à jour automatiquement.",
            en: "Your savings update automatically."
        )
    }

    // MARK: - Home

    nonisolated enum Home {
        static let greeting = Loc(fr: "Bonjour 👋", en: "Hi there 👋")
        static let headline = Loc(
            fr: "Qu'est-ce qu'on mange\naujourd'hui ?",
            en: "What are we cooking\ntoday?"
        )
        static let heroTitle = Loc(fr: "Trouver mon repas", en: "Find my meal")
        static let heroSubtitle = Loc(
            fr: "Avec ce que tu as déjà chez toi",
            en: "Cook with what you already have"
        )
        static let heroStock = Loc(
            fr: "%d produits connus • l'IA cuisine avec ton stock réel",
            en: "%d items tracked • AI cooks with what you actually have"
        )

        static let rescueSection = Loc(fr: "À sauver", en: "Use Soon")
        static let rescueCount = Loc(fr: "%d produit à sauver", en: "%d item to use soon")
        static let rescueCountPlural = Loc(fr: "%d produits à sauver", en: "%d items to use soon")
        static let reachedCount = Loc(
            fr: "%d produit à la date atteinte",
            en: "%d item past its date"
        )
        static let reachedCountPlural = Loc(
            fr: "%d produits à la date atteinte",
            en: "%d items past their date"
        )
        static let rescueCTA = Loc(
            fr: "Trouver un repas avec mes produits à sauver",
            en: "Find a recipe for what I need to use"
        )
        static let rescuePrompt = Loc(
            fr: "Propose un repas qui utilise en priorité mes produits à sauver.",
            en: "Suggest a meal that uses up the food I need to eat first."
        )

        static let scanTitle = Loc(fr: "Scanner mes courses", en: "Scan Groceries")
        static let scanSubtitle = Loc(
            fr: "Enregistre rapidement tes achats",
            en: "Log what you just bought in seconds"
        )
        static let zeroEuroTitle = Loc(fr: "Repas à 0 €", en: "$0 Meals")
        static let zeroEuroSubtitle = Loc(
            fr: "Cuisine uniquement avec ton stock",
            en: "Cook without buying anything"
        )
        static let rescueTitle = Loc(fr: "À sauver", en: "Use Soon")
        static let endOfMonthTitle = Loc(fr: "Fin de mois", en: "Tight Budget")
        static let endOfMonthSubtitle = Loc(
            fr: "Optimise ton budget alimentaire",
            en: "Stretch your grocery budget"
        )

        static let nothingUrgent = Loc(
            fr: "Rien d'urgent, tout va bien",
            en: "Nothing urgent — you're all set"
        )
        static let planSubtitle = Loc(fr: "%d produit à prévoir", en: "%d item to plan for")
        static let planSubtitlePlural = Loc(fr: "%d produits à prévoir", en: "%d items to plan for")
        static let rescueSubtitle = Loc(
            fr: "%d produit à consommer rapidement",
            en: "%d item to use soon"
        )
        static let rescueSubtitlePlural = Loc(
            fr: "%d produits à consommer rapidement",
            en: "%d items to use soon"
        )

        static let stockSection = Loc(fr: "Mon stock", en: "My Food")
        static let weekSection = Loc(fr: "Cette semaine", en: "This Week")
        static let details = Loc(fr: "Détails", en: "Details")
        static let savedMoney = Loc(fr: "économisés", en: "saved")
        static let savedItemsLabel = Loc(fr: "produits sauvés", en: "items rescued")
        static let mealsCookedLabel = Loc(fr: "repas préparés", en: "meals cooked")
        static let estimateNote = Loc(
            fr: "Estimations calculées à partir des prix moyens des produits que tu sauves.",
            en: "Estimates based on average prices for the items you use in time."
        )
        static let promiseTitle = Loc(
            fr: "Scanne tes courses. SAVEAT se souvient de ce que tu as.",
            en: "Scan your groceries. SAVEAT remembers what you have."
        )
        static let promiseBody = Loc(
            fr: "Mange ce que tu as. Achète seulement ce qu'il te manque. Jette le moins possible.",
            en: "Eat what you have. Buy only what's missing. Waste as little as possible."
        )
    }
}
