import SwiftUI

/// Every pushed destination in the app, type-safe for NavigationStack.
nonisolated enum Route: Hashable, Sendable {
    case meal(Meal)
    case food(FoodItem)
    case product(ScannedProduct)
    case rescue
    case zeroEuro
    case endOfMonth
    case shopping
    case challenges
    case impact
    case settings
    case reminders
}

/// Shared destination table so every tab resolves routes identically.
struct RouteDestinations: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: Route.self) { route in
            switch route {
            case .meal(let meal):
                MealDetailView(meal: meal)
            case .food(let item):
                FoodDetailView(item: item)
            case .product(let product):
                ProductDetailView(product: product)
            case .rescue:
                RescueView()
            case .zeroEuro:
                ZeroEuroView()
            case .endOfMonth:
                EndOfMonthView()
            case .shopping:
                ShoppingListView()
            case .challenges:
                ChallengesView()
            case .impact:
                ImpactView()
            case .settings:
                SettingsView()
            case .reminders:
                RemindersView()
            }
        }
    }
}

extension View {
    func saveatRoutes() -> some View { modifier(RouteDestinations()) }
}
