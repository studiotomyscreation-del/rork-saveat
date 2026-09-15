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
    /// TEMPORARY — manual test access to the new SAVEAT Local map (`Map/`)
    /// before it gets a real tab in Navigation V2 (Phase 5). Remove this case
    /// and its Home entry point once that phase wires the map in properly.
    case mapTest
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
            case .mapTest:
                AntiWasteMapView()
            }
        }
    }
}

extension View {
    func saveatRoutes() -> some View { modifier(RouteDestinations()) }
}
