import Foundation

/// A persisted, editable week of meals — what the future "Ma semaine" screen
/// (Phase 7 of the Chef/semaine roadmap) reads and writes.
///
/// Distinct from `BudgetPlan`/`PlannedMeal` (Models/PlanningModels.swift),
/// which stay exactly as they are: a one-shot, day-index plan generated on
/// demand by `EndOfMonthView`. This one is date-based, keeps the real
/// `Meal` (not just its name) so a day can be reopened and re-cooked, and is
/// meant to be saved and edited meal by meal as the week goes on.
nonisolated struct WeeklyMealPlan: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var startDate: Date
    var numberOfDays: Int
    var servings: Int
    /// Cravings selected for this week ("Rapide", "Végétarien"...) — a
    /// filter hint for generation, never structured data.
    var preferences: [String]
    var days: [MealPlanDay]
    var createdAt: Date = .now
    var updatedAt: Date = .now

    /// The whole week's missing ingredients, aggregated and deduplicated
    /// across every day — reuses `MealEngine.shoppingList(for:)` (already
    /// extended in Phase 2 to sum compatible quantities) rather than a
    /// second aggregation pass. Meaningful only once each day's `recipe`
    /// has been resolved against real stock (`WeeklyPlanGenerator` always
    /// does this before storing a plan).
    nonisolated var shoppingList: [ShoppingItem] {
        MealEngine.shoppingList(for: days.compactMap(\.recipe))
    }
}

/// One meal slot inside a `WeeklyMealPlan`.
nonisolated struct MealPlanDay: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var date: Date
    /// "Déjeuner" / "Dîner" — same French-stored, translated-at-display
    /// convention already used by `PlannedMeal.slot`.
    var mealType: String
    var recipe: Meal?
    var servings: Int
}
