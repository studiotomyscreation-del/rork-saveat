import Foundation

/// Turns one `MealAIService` call into a full `WeeklyMealPlan` — the "Chef
/// prepares your week" capability (§14-16 of the Chef/semaine roadmap).
///
/// Deliberately a single AI request for the whole week, never one per day:
/// `MealAIService.Request.mealCount` asks for exactly `numberOfDays` meals
/// in one structured JSON answer, and the household's real stock/diet/
/// allergens already reach the model through `MealAIService`'s existing
/// prompt — nothing here re-implements that (§28: minimize model calls).
nonisolated struct WeeklyPlanGenerator: Sendable {
    nonisolated static let shared = WeeklyPlanGenerator()

    /// A single dinner slot per day for now, matching the onboarding's
    /// "one dish per day" preview. A second ("Déjeuner") slot can be added
    /// once the real "Ma semaine" screen (Phase 7) needs it.
    private static let mealType = "Dîner"

    nonisolated func generateWeek(
        startDate: Date,
        numberOfDays: Int,
        servings: Int,
        preferences: [String],
        inventory: [FoodItem],
        profile: UserProfile
    ) async -> WeeklyMealPlan {
        let request = MealAIService.Request(
            userText: userText(for: preferences),
            servings: servings,
            mealCount: numberOfDays
        )
        let answer = await MealAIService.shared.meals(inventory: inventory, profile: profile, request: request)

        // Honest about what actually came back: never pads with invented or
        // repeated meals to force exactly `numberOfDays` days when fewer
        // meals were generated (e.g. a very short stock and a strict diet).
        let meals = Array(answer.meals.prefix(numberOfDays))
        let calendar = Calendar.current

        // Resolve each day against the stock in order, depleting a working
        // copy as we go — otherwise two days both "reusing" the same 3 eggs
        // would each be marked as fully covered by stock, and the shopping
        // list built from that would wrongly skip eggs entirely.
        var workingInventory = inventory
        var days: [MealPlanDay] = []
        for (index, meal) in meals.enumerated() {
            let resolved = MealEngine.resolve(meal, inventory: workingInventory)
            days.append(MealPlanDay(
                date: calendar.date(byAdding: .day, value: index, to: startDate) ?? startDate,
                mealType: Self.mealType,
                recipe: resolved,
                servings: servings
            ))
            for deduction in MealEngine.deductions(for: resolved, inventory: workingInventory) {
                guard let itemIndex = workingInventory.firstIndex(where: { $0.id == deduction.itemID }) else { continue }
                workingInventory[itemIndex].quantity = deduction.after
            }
        }

        return WeeklyMealPlan(
            startDate: startDate,
            numberOfDays: numberOfDays,
            servings: servings,
            preferences: preferences,
            days: days
        )
    }

    /// Turns the "envies" chips into the free-text ask `MealAIService`
    /// already expects, plus an explicit instruction to plan the week as a
    /// whole rather than independent meals (§16: reuse leftovers across
    /// consecutive days when it makes sense).
    private nonisolated func userText(for preferences: [String]) -> String {
        var parts: [String] = [Prompt.weekAsk.s]
        if !preferences.isEmpty {
            parts.append(Prompt.weekPreferences.f(preferences.joined(separator: ", ")))
        }
        parts.append(Prompt.weekLeftovers.s)
        return parts.joined(separator: " ")
    }

    private nonisolated enum Prompt {
        static let weekAsk = Loc(
            fr: "Compose le menu de la semaine, un repas par jour.",
            en: "Plan the week's menu, one meal per day."
        )
        static let weekPreferences = Loc(fr: "Envies pour cette semaine : %@.", en: "Cravings for this week: %@.")
        static let weekLeftovers = Loc(
            fr: "Quand c'est pertinent, réutilise intelligemment les restes d'un jour pour un repas du lendemain plutôt que de proposer des repas totalement indépendants.",
            en: "When it makes sense, intentionally reuse a day's leftovers in the next day's meal instead of proposing fully independent meals."
        )
    }
}
