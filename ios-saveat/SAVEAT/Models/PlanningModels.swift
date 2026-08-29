import Foundation

/// One line of the smart shopping list.
nonisolated struct ShoppingItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    var quantityText: String
    var category: FoodCategory
    var estimatedPrice: Double
    var isChecked: Bool = false
    /// Recipe that made this item necessary, when applicable.
    var reason: String?
}

/// A planned meal inside the end-of-month plan.
nonisolated struct PlannedMeal: Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var dayIndex: Int
    var slot: String
    var recipeName: String
    var usesOnlyStock: Bool
    var estimatedCost: Double
}

/// Result of the end-of-month budget planner.
nonisolated struct BudgetPlan: Identifiable, Sendable {
    var id: UUID = UUID()
    var budget: Double
    var days: Int
    var people: Int
    var meals: [PlannedMeal]
    var shoppingList: [ShoppingItem]

    nonisolated var groceriesCost: Double {
        shoppingList.reduce(0) { $0 + $1.estimatedPrice }
    }

    nonisolated var remaining: Double { budget - groceriesCost }

    nonisolated var stockOnlyMeals: Int { meals.filter(\.usesOnlyStock).count }
}

/// A weekly anti-waste challenge.
nonisolated struct Challenge: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var emoji: String
    var progress: Int
    var target: Int

    nonisolated var isDone: Bool { progress >= target }
    nonisolated var fraction: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1)
    }
}

/// Placeholder model for the future neighbourhood food-sharing module.
nonisolated struct CommunityBasket: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var title: String
    var owner: String
    var contents: [String]
    var distanceMeters: Int
    var pickupWindow: String

    nonisolated var distanceText: String {
        distanceMeters >= 1000
            ? String(format: "%.1f km", Double(distanceMeters) / 1000)
            : "\(distanceMeters) m"
    }
}

/// Aggregated, explicitly estimated impact figures.
nonisolated struct ImpactSummary: Sendable {
    var savedItems: Int
    var mealsCooked: Int
    var moneySaved: Double
    var wasteAvoidedKg: Double
    var weeklyGoal: Int

    nonisolated var goalFraction: Double {
        guard weeklyGoal > 0 else { return 0 }
        return min(Double(savedItems) / Double(weeklyGoal), 1)
    }
}
