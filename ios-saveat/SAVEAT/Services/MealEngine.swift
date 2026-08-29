import Foundation

/// Matches meals against the real household stock, ranks them by anti-waste
/// value and turns them into shopping lists and budget plans.
nonisolated enum MealEngine {
    /// Pantry basics that never count as a purchase.
    nonisolated static let staples: [String] = [
        "sel", "poivre", "huile", "eau", "sucre", "vinaigre", "epice", "épice",
        "herbe", "persil", "thym", "laurier", "ail", "moutarde", "farine", "levure"
    ]

    nonisolated static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .replacingOccurrences(of: "œ", with: "oe")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private nonisolated static let stopWords: Set<String> = [
        "de", "du", "des", "la", "le", "les", "au", "aux", "et", "en", "a", "l", "d",
        "frais", "fraiche", "nature", "bio", "surgele", "surgeles", "rape", "rapee",
        "blanc", "blanche", "entier", "entiere", "demi", "cuit", "cuite", "petit", "petits"
    ]

    nonisolated static func tokens(_ text: String) -> [String] {
        normalize(text)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count >= 3 && !stopWords.contains($0) }
    }

    nonisolated static func isStaple(_ name: String) -> Bool {
        let key = normalize(name)
        return staples.contains { key.contains($0) }
    }

    /// Finds the stock item that satisfies an ingredient, if any.
    nonisolated static func stockItem(for ingredientName: String, in inventory: [FoodItem]) -> FoodItem? {
        let wanted = tokens(ingredientName)
        guard !wanted.isEmpty else { return nil }

        return inventory
            .filter { $0.quantity > 0 }
            .first { item in
                let have = tokens(item.name) + item.matchKeys.map(normalize)
                return wanted.contains { w in
                    have.contains { h in h == w || h.contains(w) || w.contains(h) }
                }
            }
    }

    /// Fills `inStock`, `matchedItemID`, `rescuedItemIDs` and urgency for a meal.
    nonisolated static func resolve(_ meal: Meal, inventory: [FoodItem]) -> Meal {
        var resolved = meal
        var rescued: [UUID] = []
        var urgency: FreshnessState = .fresh

        resolved.ingredients = meal.ingredients.map { ingredient in
            var line = ingredient
            if isStaple(ingredient.name) {
                line.isStaple = true
                line.inStock = false
                line.matchedItemID = nil
                line.estimatedPrice = 0
                return line
            }
            if let item = stockItem(for: ingredient.name, in: inventory) {
                line.inStock = true
                line.matchedItemID = item.id
                line.category = item.category
                if !rescued.contains(item.id) { rescued.append(item.id) }
                if item.freshness.order < urgency.order { urgency = item.freshness }
            } else {
                line.inStock = false
                line.matchedItemID = nil
                if line.estimatedPrice <= 0 { line.estimatedPrice = 1.8 }
            }
            return line
        }

        resolved.rescuedItemIDs = rescued
        resolved.topUrgency = urgency
        return resolved
    }

    /// Resolves, filters and ranks a batch of meals against the stock.
    nonisolated static func rank(
        _ meals: [Meal],
        inventory: [FoodItem],
        profile: UserProfile,
        zeroEuroOnly: Bool = false,
        maxMinutes: Int? = nil
    ) -> [Meal] {
        var resolved = meals
            .map { resolve($0, inventory: inventory) }
            .filter { isCompatible($0, with: profile) }

        if zeroEuroOnly {
            resolved = resolved.filter(\.isZeroEuro)
        }
        if let maxMinutes {
            resolved = resolved.filter { $0.totalMinutes <= maxMinutes }
        }
        // Drop meals that barely use the stock — they are shopping lists, not rescues.
        resolved = resolved.filter { !$0.availableIngredients.isEmpty }

        return resolved.sorted { $0.score > $1.score }
    }

    /// Filters out meals clashing with the household diet, allergens or dislikes.
    nonisolated static func isCompatible(_ meal: Meal, with profile: UserProfile) -> Bool {
        let text = meal.ingredients.map { normalize($0.name) } + [normalize(meal.name)]

        func mentions(_ keys: [String]) -> Bool {
            text.contains { line in keys.contains { line.contains(normalize($0)) } }
        }

        let meat = ["poulet", "jambon", "steak", "boeuf", "porc", "dinde", "lardon", "saucisse", "viande", "bacon"]
        let animal = meat + ["oeuf", "lait", "fromage", "yaourt", "beurre", "creme", "miel", "poisson", "thon"]

        switch profile.diet {
        case .vegetarian:
            if mentions(meat + ["poisson", "thon", "saumon"]) { return false }
        case .pescatarian:
            if mentions(meat) { return false }
        case .vegan:
            if mentions(animal) { return false }
        case .omnivore, .flexitarian, .halal:
            break
        }

        for allergen in profile.allergens {
            let keys: [String]
            switch allergen {
            case .gluten: keys = ["pain", "pates", "farine", "semoule", "biscotte", "chapelure"]
            case .lactose: keys = ["lait", "fromage", "yaourt", "beurre", "creme"]
            case .nuts: keys = ["noix", "amande", "noisette", "pistache"]
            case .eggs: keys = ["oeuf"]
            case .seafood: keys = ["crevette", "moule", "poisson", "thon", "saumon"]
            case .soy: keys = ["soja", "tofu"]
            }
            if mentions(keys) { return false }
        }

        for dislike in profile.dislikes where mentions([dislike]) {
            return false
        }

        return true
    }

    // MARK: - Curated fallback

    /// Suggestions built from the bundled recipe book — used offline and as a safety net.
    nonisolated static func curatedSuggestions(
        inventory: [FoodItem],
        profile: UserProfile,
        zeroEuroOnly: Bool = false,
        maxMinutes: Int? = nil,
        focusNames: [String] = [],
        servings: Int? = nil
    ) -> [Meal] {
        var meals = rank(
            MockData.curatedMeals,
            inventory: inventory,
            profile: profile,
            zeroEuroOnly: zeroEuroOnly,
            maxMinutes: maxMinutes
        )

        if !focusNames.isEmpty {
            let keys = focusNames.map(normalize)
            let focused = meals.filter { meal in
                meal.ingredients.contains { ingredient in
                    let name = normalize(ingredient.name)
                    return keys.contains { name.contains($0) || $0.contains(name) }
                }
            }
            if !focused.isEmpty { meals = focused }
        }

        if let servings, servings > 0 {
            meals = meals.map { scale($0, to: servings) }
        }

        return meals
    }

    /// Adapts quantities and cost when the household size changes.
    nonisolated static func scale(_ meal: Meal, to servings: Int) -> Meal {
        guard servings > 0, meal.servings > 0, servings != meal.servings else { return meal }
        let factor = Double(servings) / Double(meal.servings)
        var scaled = meal
        scaled.servings = servings
        scaled.ingredients = meal.ingredients.map { ingredient in
            var line = ingredient
            line.estimatedPrice = (ingredient.estimatedPrice * factor * 100).rounded() / 100
            return line
        }
        return scaled
    }

    // MARK: - Shopping & budget

    /// Builds a shopping list from meals, skipping everything already in stock.
    nonisolated static func shoppingList(for meals: [Meal]) -> [ShoppingItem] {
        var byName: [String: ShoppingItem] = [:]

        for meal in meals {
            for ingredient in meal.missingIngredients {
                let key = normalize(ingredient.name)
                if byName[key] == nil {
                    byName[key] = ShoppingItem(
                        name: ingredient.name,
                        quantityText: ingredient.quantityText,
                        category: ingredient.category,
                        estimatedPrice: ingredient.estimatedPrice,
                        reason: meal.name
                    )
                }
            }
        }

        return byName.values.sorted { lhs, rhs in
            if lhs.category == rhs.category { return lhs.name < rhs.name }
            return lhs.category.rawValue < rhs.category.rawValue
        }
    }

    /// Squeezes the existing stock first, then spends what is strictly needed.
    nonisolated static func budgetPlan(
        budget: Double,
        days: Int,
        people: Int,
        inventory: [FoodItem],
        profile: UserProfile
    ) -> BudgetPlan {
        let ranked = curatedSuggestions(inventory: inventory, profile: profile)
        guard !ranked.isEmpty else {
            return BudgetPlan(budget: budget, days: days, people: people, meals: [], shoppingList: [])
        }

        // Free meals first so the money lasts as long as possible.
        let ordered = ranked.sorted { lhs, rhs in
            if lhs.isZeroEuro != rhs.isZeroEuro { return lhs.isZeroEuro }
            return lhs.extraCost < rhs.extraCost
        }

        let slots = ["Déjeuner", "Dîner"]
        var planned: [PlannedMeal] = []
        var paidMeals: [Meal] = []
        var index = 0

        for day in 0..<max(days, 1) {
            for slot in slots {
                let meal = ordered[index % ordered.count]
                index += 1
                let perMeal = meal.extraCostPerServing * Double(max(people, 1))
                planned.append(PlannedMeal(
                    dayIndex: day,
                    slot: slot,
                    recipeName: meal.name,
                    usesOnlyStock: meal.isZeroEuro,
                    estimatedCost: perMeal
                ))
                if !meal.isZeroEuro, !paidMeals.contains(where: { $0.id == meal.id }) {
                    paidMeals.append(meal)
                }
            }
        }

        var list = shoppingList(for: paidMeals)
        while list.reduce(0, { $0 + $1.estimatedPrice }) > budget, !list.isEmpty {
            guard let priciest = list.max(by: { $0.estimatedPrice < $1.estimatedPrice }),
                  let idx = list.firstIndex(where: { $0.id == priciest.id }) else { break }
            list.remove(at: idx)
        }

        return BudgetPlan(budget: budget, days: days, people: people, meals: planned, shoppingList: list)
    }

    // MARK: - Cooking

    /// Proposes how much of each stock item a meal consumes; the user can edit it.
    nonisolated static func deductions(for meal: Meal, inventory: [FoodItem]) -> [StockDeduction] {
        meal.ingredients.compactMap { ingredient -> StockDeduction? in
            guard let id = ingredient.matchedItemID,
                  let item = inventory.first(where: { $0.id == id }) else { return nil }

            let used = suggestedUsage(for: ingredient, item: item)
            return StockDeduction(
                itemID: item.id,
                name: item.name,
                emoji: item.emoji,
                unit: item.unit,
                before: item.quantity,
                used: used
            )
        }
    }

    /// Reads "3 pièces", "½ paquet", "200 g" and turns it into stock units.
    nonisolated static func suggestedUsage(for ingredient: MealIngredient, item: FoodItem) -> Double {
        let text = normalize(ingredient.quantityText)

        // Countable units map directly onto the stock count.
        if item.unit.contains("pièce") || item.unit.contains("tranche") || item.unit.contains("pot")
            || item.unit.contains("œuf") || item.unit.contains("oeuf") {
            if let number = leadingNumber(in: text) {
                return min(max(number, 0.5), item.quantity)
            }
        }

        if text.contains("moitie") || text.contains("1/2") || text.contains("demi") {
            return min(0.5, item.quantity)
        }

        // Weights and volumes consume a share of one pack.
        if text.contains("g") || text.contains("cl") || text.contains("ml") {
            return min(item.quantity, item.quantity >= 2 ? 1 : 0.5)
        }

        if let number = leadingNumber(in: text) {
            return min(max(number, 0.5), item.quantity)
        }

        return min(1, item.quantity)
    }

    private nonisolated static func leadingNumber(in text: String) -> Double? {
        var digits = ""
        for character in text {
            if character.isNumber || character == "," || character == "." {
                digits.append(character == "," ? "." : character)
            } else if !digits.isEmpty {
                break
            }
        }
        return Double(digits)
    }
}
