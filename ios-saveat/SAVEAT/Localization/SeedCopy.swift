import Foundation

/// Display names for the food SAVEAT ships with.
///
/// Stored names stay in French: they are the key the meal engine matches stock
/// against, and existing users already have them saved. Translation happens at
/// display time only, so switching language never rewrites anyone's data.
/// Anything unknown — a scanned US product, an assistant answer — is returned
/// untouched, because it already arrives in the reader's language.
nonisolated enum FoodNames {
    private static let table: [String: Loc] = [
        "Yaourts nature": Loc(fr: "Yaourts nature", en: "Plain yogurt"),
        "Jambon blanc": Loc(fr: "Jambon blanc", en: "Deli ham"),
        "Courgettes": Loc(fr: "Courgettes", en: "Zucchini"),
        "Lait demi-écrémé": Loc(fr: "Lait demi-écrémé", en: "2% milk"),
        "Œufs frais": Loc(fr: "Œufs frais", en: "Fresh eggs"),
        "Œufs": Loc(fr: "Œufs", en: "Eggs"),
        "Emmental râpé": Loc(fr: "Emmental râpé", en: "Shredded cheese"),
        "Tomates": Loc(fr: "Tomates", en: "Tomatoes"),
        "Poulet rôti": Loc(fr: "Poulet rôti", en: "Rotisserie chicken"),
        "Coquillettes": Loc(fr: "Coquillettes", en: "Elbow pasta"),
        "Riz long grain": Loc(fr: "Riz long grain", en: "Long grain rice"),
        "Thon au naturel": Loc(fr: "Thon au naturel", en: "Canned tuna"),
        "Sauce tomate basilic": Loc(fr: "Sauce tomate basilic", en: "Tomato basil sauce"),
        "Sauce tomate": Loc(fr: "Sauce tomate", en: "Tomato sauce"),
        "Pain de campagne": Loc(fr: "Pain de campagne", en: "Country bread"),
        "Oignons": Loc(fr: "Oignons", en: "Onions"),
        "Oignon": Loc(fr: "Oignon", en: "Onion"),
        "Lentilles vertes": Loc(fr: "Lentilles vertes", en: "Green lentils"),
        "Poêlée de légumes": Loc(fr: "Poêlée de légumes", en: "Frozen veggie mix"),
        "Petits pois surgelés": Loc(fr: "Petits pois surgelés", en: "Frozen peas"),
        "Steaks hachés": Loc(fr: "Steaks hachés", en: "Ground beef patties"),
        "Lait": Loc(fr: "Lait", en: "Milk"),
        "Huile d'olive": Loc(fr: "Huile d'olive", en: "Olive oil"),
        "Sel": Loc(fr: "Sel", en: "Salt"),
        "Poivre": Loc(fr: "Poivre", en: "Pepper"),
        "Sucre": Loc(fr: "Sucre", en: "Sugar"),
        "Vinaigre": Loc(fr: "Vinaigre", en: "Vinegar"),
        "Beurre": Loc(fr: "Beurre", en: "Butter"),
        "Farine": Loc(fr: "Farine", en: "Flour"),
        "Eau": Loc(fr: "Eau", en: "Water")
    ]

    nonisolated static func display(_ name: String) -> String {
        table[name]?.s ?? name
    }
}

/// Stock units, pluralised in the reader's language.
nonisolated enum FoodUnits {
    private static let table: [String: (singular: Loc, plural: Loc)] = [
        "pot": (Loc(fr: "pot", en: "cup"), Loc(fr: "pots", en: "cups")),
        "paquet": (Loc(fr: "paquet", en: "pack"), Loc(fr: "paquets", en: "packs")),
        "pièce": (Loc(fr: "pièce", en: "count"), Loc(fr: "pièces", en: "count")),
        "bouteille": (Loc(fr: "bouteille", en: "bottle"), Loc(fr: "bouteilles", en: "bottles")),
        "sachet": (Loc(fr: "sachet", en: "bag"), Loc(fr: "sachets", en: "bags")),
        "boîte": (Loc(fr: "boîte", en: "can"), Loc(fr: "boîtes", en: "cans")),
        "reste": (Loc(fr: "reste", en: "portion"), Loc(fr: "restes", en: "portions")),
        "demi": (Loc(fr: "demi", en: "half"), Loc(fr: "demis", en: "halves")),
        "tranche": (Loc(fr: "tranche", en: "slice"), Loc(fr: "tranches", en: "slices")),
        "pièces": (Loc(fr: "pièce", en: "count"), Loc(fr: "pièces", en: "count"))
    ]

    /// Unit label agreeing with the quantity, e.g. "2 packs" / "2 paquets".
    nonisolated static func display(_ unit: String, quantity: Double) -> String {
        let isPlural = quantity > 1
        if let entry = table[unit.lowercased()] {
            return isPlural ? entry.plural.s : entry.singular.s
        }
        guard LanguageRuntime.current == .fr else { return unit }
        return isPlural && !unit.hasSuffix("s") ? unit + "s" : unit
    }
}

/// Recipe amounts, converted per ingredient rather than blindly.
///
/// Grams of flour and grams of water do not become the same number of cups, so
/// SAVEAT only reaches for cups on liquids and falls back to ounces elsewhere.
/// Counts, spoons and pinches are simply reworded.
nonisolated enum RecipeQuantity {
    private static let phrases: [String: Loc] = [
        "1 pincée": Loc(fr: "1 pincée", en: "1 pinch"),
        "1 c. à s.": Loc(fr: "1 c. à s.", en: "1 tbsp"),
        "2 c. à s.": Loc(fr: "2 c. à s.", en: "2 tbsp"),
        "1 c. à c.": Loc(fr: "1 c. à c.", en: "1 tsp"),
        "1 pot": Loc(fr: "1 pot", en: "1 jar"),
        "1 boîte": Loc(fr: "1 boîte", en: "1 can"),
        "1 sachet": Loc(fr: "1 sachet", en: "1 bag")
    ]

    /// Rewrites a curated quantity such as "150 g" or "2 tranches" for the reader.
    nonisolated static func display(_ raw: String) -> String {
        guard LanguageRuntime.current != .fr else { return raw }
        if let phrase = phrases[raw] { return phrase.s }

        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let scanner = Scanner(string: trimmed.replacingOccurrences(of: ",", with: "."))
        scanner.charactersToBeSkipped = .whitespaces
        guard let amount = scanner.scanDouble() else { return raw }
        let unit = String(trimmed.replacingOccurrences(of: ",", with: ".")[scanner.currentIndex...])
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        switch unit {
        case "g", "gr": return Units.weight(grams: amount)
        case "kg": return Units.weight(grams: amount * 1_000)
        case "cl": return Units.volume(millilitres: amount * 10)
        case "ml": return Units.volume(millilitres: amount)
        case "l": return Units.volume(millilitres: amount * 1_000)
        case "tranche", "tranches":
            return "\(Int(amount)) " + (amount > 1 ? "slices" : "slice")
        case "pièce", "pièces":
            return "\(Int(amount))"
        case "pot", "pots":
            return "\(Int(amount)) " + (amount > 1 ? "jars" : "jar")
        case "boîte", "boîtes":
            return "\(Int(amount)) " + (amount > 1 ? "cans" : "can")
        case "sachet", "sachets":
            return "\(Int(amount)) " + (amount > 1 ? "bags" : "bag")
        default:
            return raw
        }
    }
}

/// Wording for the meals, challenges and cooking history SAVEAT ships with.
///
/// Same principle as `FoodNames`: the French text is the stored key, English is
/// resolved when it is drawn. Assistant-generated recipes already come back in
/// the reader's language and pass straight through.
nonisolated enum SeedCopy {
    private static let table: [String: Loc] = [
        // Meal names
        "Riz sauté jambon, œufs & courgettes": Loc(
            fr: "Riz sauté jambon, œufs & courgettes",
            en: "Ham, Egg & Zucchini Fried Rice"
        ),
        "Gratin de courgettes au fromage": Loc(
            fr: "Gratin de courgettes au fromage",
            en: "Cheesy Zucchini Bake"
        ),
        "Omelette jambon & fromage": Loc(
            fr: "Omelette jambon & fromage",
            en: "Ham & Cheese Omelet"
        ),
        "Pâtes à la sauce tomate & thon": Loc(
            fr: "Pâtes à la sauce tomate & thon",
            en: "Tuna & Tomato Pasta"
        ),
        "Soupe de légumes du frigo": Loc(
            fr: "Soupe de légumes du frigo",
            en: "Clean-Out-The-Fridge Vegetable Soup"
        ),
        "Pain perdu du placard": Loc(
            fr: "Pain perdu du placard",
            en: "Pantry French Toast"
        ),
        "Poêlée de légumes & œufs au plat": Loc(
            fr: "Poêlée de légumes & œufs au plat",
            en: "Veggie Skillet with Fried Eggs"
        ),
        "Salade de lentilles au thon": Loc(
            fr: "Salade de lentilles au thon",
            en: "Lentil & Tuna Salad"
        ),
        "Riz sauté jambon & courgettes": Loc(
            fr: "Riz sauté jambon & courgettes",
            en: "Ham & Zucchini Fried Rice"
        ),
        "Salade de lentilles": Loc(fr: "Salade de lentilles", en: "Lentil Salad"),
        "Quiche du frigo": Loc(fr: "Quiche du frigo", en: "Fridge Quiche"),
        "Curry de légumes": Loc(fr: "Curry de légumes", en: "Vegetable Curry"),
        "Gratin de pâtes": Loc(fr: "Gratin de pâtes", en: "Baked Pasta"),
        "Gratin de courgettes": Loc(fr: "Gratin de courgettes", en: "Zucchini Bake"),

        // Summaries
        "Le grand classique anti-gaspi : tout part dans la même poêle.": Loc(
            fr: "Le grand classique anti-gaspi : tout part dans la même poêle.",
            en: "The classic use-it-up dinner — everything goes in one skillet."
        ),
        "Un plat familial qui vide le bac à légumes.": Loc(
            fr: "Un plat familial qui vide le bac à légumes.",
            en: "A family bake that empties the crisper drawer."
        ),
        "Dix minutes chrono, uniquement avec le frigo.": Loc(
            fr: "Dix minutes chrono, uniquement avec le frigo.",
            en: "Ten minutes flat, straight from the fridge."
        ),
        "Le dîner du placard quand le frigo est vide.": Loc(
            fr: "Le dîner du placard quand le frigo est vide.",
            en: "The pantry dinner for when the fridge is empty."
        ),
        "Tout ce qui traîne finit dedans, et c'est très bon.": Loc(
            fr: "Tout ce qui traîne finit dedans, et c'est très bon.",
            en: "Whatever is left over goes in — and it's genuinely good."
        ),
        "Le dessert qui sauve le pain de la poubelle.": Loc(
            fr: "Le dessert qui sauve le pain de la poubelle.",
            en: "The dessert that rescues day-old bread."
        ),
        "Direct du congélateur, prêt en un quart d'heure.": Loc(
            fr: "Direct du congélateur, prêt en un quart d'heure.",
            en: "Straight from the freezer, done in fifteen minutes."
        ),
        "Riche en protéines, se prépare la veille.": Loc(
            fr: "Riche en protéines, se prépare la veille.",
            en: "High in protein, and better made the night before."
        ),

        // Steps
        "Fais revenir l'oignon émincé dans un filet d'huile.": Loc(
            fr: "Fais revenir l'oignon émincé dans un filet d'huile.",
            en: "Sauté the sliced onion in a little oil."
        ),
        "Ajoute les courgettes en dés, laisse dorer 6 minutes.": Loc(
            fr: "Ajoute les courgettes en dés, laisse dorer 6 minutes.",
            en: "Add the diced zucchini and brown for 6 minutes."
        ),
        "Ajoute le riz cuit et le jambon coupé, fais sauter à feu vif.": Loc(
            fr: "Ajoute le riz cuit et le jambon coupé, fais sauter à feu vif.",
            en: "Add the cooked rice and chopped ham, then stir-fry over high heat."
        ),
        "Pousse le riz sur le côté, brouille les œufs puis mélange le tout.": Loc(
            fr: "Pousse le riz sur le côté, brouille les œufs puis mélange le tout.",
            en: "Push the rice aside, scramble the eggs, then mix everything together."
        ),
        "Coupe les courgettes en fines rondelles, dispose-les dans un plat.": Loc(
            fr: "Coupe les courgettes en fines rondelles, dispose-les dans un plat.",
            en: "Slice the zucchini thin and layer it in a baking dish."
        ),
        "Bats les œufs avec le lait, verse sur les courgettes.": Loc(
            fr: "Bats les œufs avec le lait, verse sur les courgettes.",
            en: "Beat the eggs with the milk and pour over the zucchini."
        ),
        "Couvre de fromage et enfourne 25 minutes.": Loc(
            fr: "Couvre de fromage et enfourne 25 minutes.",
            en: "Top with cheese and bake for 25 minutes."
        ),
        "Bats les œufs avec une pincée de sel et de poivre.": Loc(
            fr: "Bats les œufs avec une pincée de sel et de poivre.",
            en: "Beat the eggs with a pinch of salt and pepper."
        ),
        "Verse dans une poêle chaude légèrement huilée.": Loc(
            fr: "Verse dans une poêle chaude légèrement huilée.",
            en: "Pour into a hot, lightly oiled skillet."
        ),
        "Ajoute le jambon et le fromage, replie l'omelette.": Loc(
            fr: "Ajoute le jambon et le fromage, replie l'omelette.",
            en: "Add the ham and cheese, then fold the omelet over."
        ),
        "Fais cuire les pâtes dans l'eau salée.": Loc(
            fr: "Fais cuire les pâtes dans l'eau salée.",
            en: "Cook the pasta in salted water."
        ),
        "Fais revenir l'oignon, ajoute la sauce tomate et le thon égoutté.": Loc(
            fr: "Fais revenir l'oignon, ajoute la sauce tomate et le thon égoutté.",
            en: "Sauté the onion, then add the tomato sauce and drained tuna."
        ),
        "Laisse mijoter 6 minutes, mélange avec les pâtes.": Loc(
            fr: "Laisse mijoter 6 minutes, mélange avec les pâtes.",
            en: "Simmer for 6 minutes, then toss with the pasta."
        ),
        "Fais suer l'oignon, ajoute les légumes coupés grossièrement.": Loc(
            fr: "Fais suer l'oignon, ajoute les légumes coupés grossièrement.",
            en: "Sweat the onion, then add the roughly chopped vegetables."
        ),
        "Couvre d'eau, laisse mijoter 20 minutes.": Loc(
            fr: "Couvre d'eau, laisse mijoter 20 minutes.",
            en: "Cover with water and simmer for 20 minutes."
        ),
        "Mixe et sers avec le pain grillé.": Loc(
            fr: "Mixe et sers avec le pain grillé.",
            en: "Blend and serve with toasted bread."
        ),
        "Bats les œufs avec le lait et le sucre.": Loc(
            fr: "Bats les œufs avec le lait et le sucre.",
            en: "Beat the eggs with the milk and sugar."
        ),
        "Trempe les tranches de pain rassis.": Loc(
            fr: "Trempe les tranches de pain rassis.",
            en: "Soak the stale bread slices."
        ),
        "Fais dorer à la poêle 2 minutes de chaque côté.": Loc(
            fr: "Fais dorer à la poêle 2 minutes de chaque côté.",
            en: "Pan-fry for 2 minutes per side until golden."
        ),
        "Fais sauter les légumes encore surgelés 10 minutes à feu vif.": Loc(
            fr: "Fais sauter les légumes encore surgelés 10 minutes à feu vif.",
            en: "Stir-fry the vegetables from frozen for 10 minutes over high heat."
        ),
        "Casse les œufs par-dessus, couvre 3 minutes.": Loc(
            fr: "Casse les œufs par-dessus, couvre 3 minutes.",
            en: "Crack the eggs on top, cover and cook for 3 minutes."
        ),
        "Parsème de fromage et sers aussitôt.": Loc(
            fr: "Parsème de fromage et sers aussitôt.",
            en: "Scatter over the cheese and serve right away."
        ),
        "Cuis les lentilles 20 minutes dans l'eau non salée.": Loc(
            fr: "Cuis les lentilles 20 minutes dans l'eau non salée.",
            en: "Cook the lentils for 20 minutes in unsalted water."
        ),
        "Égoutte et laisse tiédir.": Loc(
            fr: "Égoutte et laisse tiédir.",
            en: "Drain and let cool slightly."
        ),
        "Mélange avec le thon, les tomates en dés et l'oignon émincé.": Loc(
            fr: "Mélange avec le thon, les tomates en dés et l'oignon émincé.",
            en: "Toss with the tuna, diced tomatoes and sliced onion."
        ),

        // Anti-waste notes
        "Utilise ton jambon ouvert et tes courgettes.": Loc(
            fr: "Utilise ton jambon ouvert et tes courgettes.",
            en: "Uses up your opened ham and your zucchini."
        ),
        "Parfait pour les courgettes à utiliser en priorité.": Loc(
            fr: "Parfait pour les courgettes à utiliser en priorité.",
            en: "Perfect for the zucchini you need to use first."
        ),
        "Ton jambon ouvert part en premier.": Loc(
            fr: "Ton jambon ouvert part en premier.",
            en: "Your opened ham goes first."
        ),
        "Zéro achat : tout vient de tes placards.": Loc(
            fr: "Zéro achat : tout vient de tes placards.",
            en: "Nothing to buy — it all comes from your pantry."
        ),
        "Idéale pour le pain rassis.": Loc(
            fr: "Idéale pour le pain rassis.",
            en: "Ideal for stale bread."
        ),
        "Ton pain entamé devient un dessert.": Loc(
            fr: "Ton pain entamé devient un dessert.",
            en: "Turns your opened loaf into dessert."
        ),
        "Vide ton congélateur sans rien acheter.": Loc(
            fr: "Vide ton congélateur sans rien acheter.",
            en: "Clears out the freezer without a store run."
        ),
        "Se garde 3 jours au frigo.": Loc(
            fr: "Se garde 3 jours au frigo.",
            en: "Keeps for 3 days in the fridge."
        ),

        // Tags & difficulty
        "Facile": Loc(fr: "Facile", en: "Easy"),
        "Moyen": Loc(fr: "Moyen", en: "Medium"),
        "Express": Loc(fr: "Express", en: "Quick"),
        "Anti-gaspi": Loc(fr: "Anti-gaspi", en: "Zero waste"),
        "Végétarien": Loc(fr: "Végétarien", en: "Vegetarian"),
        "Four": Loc(fr: "Four", en: "Oven"),
        "Repas à 0 €": Loc(fr: "Repas à 0 €", en: "$0 meal"),
        "Économique": Loc(fr: "Économique", en: "Budget"),
        "Placard": Loc(fr: "Placard", en: "Pantry"),
        "Léger": Loc(fr: "Léger", en: "Light"),
        "Sucré": Loc(fr: "Sucré", en: "Sweet"),
        "Protéines": Loc(fr: "Protéines", en: "High protein"),
        "Batch cooking": Loc(fr: "Batch cooking", en: "Meal prep"),

        // Challenges
        "Cuisiner 3 repas avec ton stock": Loc(
            fr: "Cuisiner 3 repas avec ton stock",
            en: "Cook 3 meals from what you have"
        ),
        "Défi Zéro Gaspi — 7 jours": Loc(
            fr: "Défi Zéro Gaspi — 7 jours",
            en: "Zero Waste Challenge — 7 days"
        ),
        "Réussir un repas à 0 €": Loc(
            fr: "Réussir un repas à 0 €",
            en: "Make a $0 meal"
        ),
        "Aucun achat nécessaire": Loc(
            fr: "Aucun achat nécessaire",
            en: "Nothing to buy"
        ),
        "Sauver 5 produits": Loc(
            fr: "Sauver 5 produits",
            en: "Rescue 5 items"
        ),
        "Avant leur date limite": Loc(
            fr: "Avant leur date limite",
            en: "Before their date runs out"
        ),
        "Une semaine sans doublon": Loc(
            fr: "Une semaine sans doublon",
            en: "A week with no duplicates"
        ),
        "Ne racheter que ce qu'il manque": Loc(
            fr: "Ne racheter que ce qu'il manque",
            en: "Only buy what's actually missing"
        )
    ]

    nonisolated static func display(_ text: String) -> String {
        table[text]?.s ?? text
    }

    nonisolated static func display(_ texts: [String]) -> [String] {
        texts.map(display)
    }
}
