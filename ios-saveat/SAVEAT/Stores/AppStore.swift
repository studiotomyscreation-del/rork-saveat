import Foundation
import SwiftUI

/// Single source of truth for the household: profile, stock, cooking history and savings.
///
/// Persisted locally with `UserDefaults`; the shape is ready to be backed by a
/// cloud database and an authenticated user without touching the views.
@Observable
final class AppStore {
    private enum Keys {
        static let profile = "saveat.profile.v2"
        static let inventory = "saveat.inventory.v2"
        static let cooked = "saveat.cooked.v2"
        static let shopping = "saveat.shopping.v2"
        static let challenges = "saveat.challenges.v2"
        static let groceryRuns = "saveat.groceryRuns.v2"
        static let waste = "saveat.waste.v1"
    }

    var profile: UserProfile {
        didSet {
            persist(profile, key: Keys.profile)
            if profile.reminderSettings != oldValue.reminderSettings { scheduleReminders() }
        }
    }

    var inventory: [FoodItem] {
        didSet {
            persist(inventory, key: Keys.inventory)
            scheduleReminders()
        }
    }

    var shoppingList: [ShoppingItem] {
        didSet { persist(shoppingList, key: Keys.shopping) }
    }

    var challenges: [Challenge] {
        didSet { persist(challenges, key: Keys.challenges) }
    }

    /// Meals cooked through the app, used for the savings dashboard.
    private(set) var cookedLog: [CookedMeal] {
        didSet { persist(cookedLog, key: Keys.cooked) }
    }

    /// Completed grocery scanning sessions.
    private(set) var groceryRuns: [GroceryRun] {
        didSet { persist(groceryRuns, key: Keys.groceryRuns) }
    }

    /// Products that left the stock, either saved in time or thrown away.
    private(set) var wasteLog: [WasteEvent] {
        didSet { persist(wasteLog, key: Keys.waste) }
    }

    /// Toast-style confirmation shown after an action.
    var banner: BannerMessage?

    var lifetimeMeals: [CookedMeal] { cookedLog }

    init() {
        let defaults = UserDefaults.standard

        func load<T: Decodable>(_ key: String, fallback: T) -> T {
            guard let data = defaults.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(T.self, from: data) else {
                return fallback
            }
            return decoded
        }

        profile = load(Keys.profile, fallback: UserProfile())
        inventory = load(Keys.inventory, fallback: MockData.inventory)
        shoppingList = load(Keys.shopping, fallback: [])
        challenges = load(Keys.challenges, fallback: MockData.challenges)
        cookedLog = load(Keys.cooked, fallback: CookedMeal.seed)
        groceryRuns = load(Keys.groceryRuns, fallback: [])
        wasteLog = load(Keys.waste, fallback: [])
    }

    /// Re-plans every anti-waste reminder from the current stock and preferences.
    func scheduleReminders() {
        NotificationService.shared.refresh(inventory: inventory, settings: profile.reminderSettings)
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Derived stock

    func items(in location: StorageLocation) -> [FoodItem] {
        inventory
            .filter { $0.location == location }
            .sorted { lhs, rhs in
                if lhs.freshness.order != rhs.freshness.order {
                    return lhs.freshness.order < rhs.freshness.order
                }
                return (lhs.daysLeft ?? 9_999) < (rhs.daysLeft ?? 9_999)
            }
    }

    func count(in location: StorageLocation) -> Int {
        inventory.filter { $0.location == location }.count
    }

    var totalProducts: Int { inventory.count }

    /// 🟠 Products that must be eaten quickly.
    var rescueItems: [FoodItem] {
        inventory.filter { $0.quantity > 0 && $0.status == .rescue }
    }

    /// 🟡 Products whose date is approaching.
    var planItems: [FoodItem] {
        inventory.filter { $0.quantity > 0 && $0.status == .plan }
    }

    /// 🔴 Products whose date is reached or passed.
    var reachedItems: [FoodItem] {
        inventory
            .filter { $0.quantity > 0 && $0.status == .reached }
            .sorted { ($0.daysLeft ?? 0) < ($1.daysLeft ?? 0) }
    }

    var urgentItems: [FoodItem] { rescueItems }

    var soonItems: [FoodItem] { planItems }

    /// The "À sauver" queue: 🟠 first, then 🟡, soonest date first.
    ///
    /// Products whose date is already reached live in `reachedItems` instead, so
    /// they are never presented as something to cook right away.
    var rescueQueue: [FoodItem] {
        inventory
            .filter { $0.quantity > 0 && ($0.status == .rescue || $0.status == .plan) }
            .sorted { lhs, rhs in
                if lhs.status.order != rhs.status.order {
                    return lhs.status.order < rhs.status.order
                }
                return (lhs.daysLeft ?? 9_999) < (rhs.daysLeft ?? 9_999)
            }
    }

    var potentialSavings: Double {
        rescueQueue.reduce(0) { $0 + $1.estimatedValue }
    }

    var stockValue: Double {
        inventory.reduce(0) { $0 + $1.estimatedValue * max($1.quantity, 1) }
    }

    // MARK: - Duplicate detection

    /// Finds an item already at home that matches a product about to be added.
    func existingItem(for product: ScannedProduct) -> FoodItem? {
        if let byBarcode = inventory.first(where: { $0.barcode == product.barcode }) {
            return byBarcode
        }
        return MealEngine.stockItem(for: product.displayTitle, in: inventory)
    }

    func existingItem(named name: String) -> FoodItem? {
        MealEngine.stockItem(for: name, in: inventory)
    }

    // MARK: - Mutations

    func add(_ items: [FoodItem]) {
        for item in items { addOne(item) }
        bumpChallenge(matching: "Sauver 5 produits", by: 0)
    }

    private func addOne(_ item: FoodItem) {
        let index = inventory.firstIndex { existing in
            if let code = item.barcode, existing.barcode == code { return true }
            return MealEngine.normalize(existing.name) == MealEngine.normalize(item.name)
                && existing.location == item.location
        }

        if let index {
            inventory[index].quantity += item.quantity
            if let newDate = item.bestBefore {
                let existing = inventory[index].bestBefore
                inventory[index].bestBefore = min(newDate, existing ?? newDate)
            }
            if inventory[index].product == nil { inventory[index].product = item.product }
        } else {
            inventory.append(item)
        }
    }

    func update(_ item: FoodItem) {
        guard let index = inventory.firstIndex(where: { $0.id == item.id }) else { return }
        inventory[index] = item
    }

    func remove(_ item: FoodItem) {
        inventory.removeAll { $0.id == item.id }
    }

    func setBestBefore(_ date: Date?, for itemID: UUID) {
        guard let index = inventory.firstIndex(where: { $0.id == itemID }) else { return }
        inventory[index].bestBefore = date
    }

    // MARK: - Saved / thrown away

    /// Marks a product as consumed before it was lost.
    ///
    /// Removes the used quantity, drops the item once it reaches zero and records
    /// the save. Future reminders are re-planned automatically by `inventory`.
    func markSaved(_ item: FoodItem, quantity: Double? = nil) {
        guard let index = inventory.firstIndex(where: { $0.id == item.id }) else { return }

        let used = quantity ?? inventory[index].quantity
        let remaining = max(inventory[index].quantity - used, 0)

        if remaining <= 0.001 {
            inventory.remove(at: index)
        } else {
            inventory[index].quantity = (remaining * 100).rounded() / 100
            inventory[index].isOpened = true
        }

        wasteLog.append(WasteEvent(itemName: item.name, emoji: item.emoji, outcome: .saved))
        bumpChallenge(matching: "Sauver 5 produits", by: 1)

        banner = BannerMessage(text: S.Banner.saved.f(item.displayName), tone: .success)
    }

    /// Records a product that had to be thrown away.
    ///
    /// Never counted as a save, and never framed as a failure to the user.
    func markDiscarded(_ item: FoodItem) {
        inventory.removeAll { $0.id == item.id }
        wasteLog.append(WasteEvent(itemName: item.name, emoji: item.emoji, outcome: .discarded))
        banner = BannerMessage(text: S.Banner.discarded.f(item.displayName), tone: .info)
    }

    private func wasteEvents(_ outcome: WasteOutcome, since date: Date) -> Int {
        wasteLog.filter { $0.outcome == outcome && $0.date >= date }.count
    }

    /// Products saved since the start of the current week.
    var savedThisWeek: Int {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: .now)?.start
            ?? calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        return wasteEvents(.saved, since: start)
    }

    /// Products saved since the start of the current month.
    var savedThisMonth: Int {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .month, for: .now)?.start
            ?? calendar.date(byAdding: .day, value: -30, to: .now) ?? .now
        return wasteEvents(.saved, since: start)
    }

    var savedAllTime: Int {
        wasteLog.filter { $0.outcome == .saved }.count
    }

    /// Weekly saving goal, scaled to the household size.
    var weeklySaveGoal: Int { max(profile.householdSize * 3, 5) }

    /// Consecutive days without throwing anything away, capped by the account age.
    var zeroWasteStreakDays: Int {
        let calendar = Calendar.current
        let discardDays = Set(
            wasteLog
                .filter { $0.outcome == .discarded }
                .map { calendar.startOfDay(for: $0.date) }
        )

        var streak = 0
        var day = calendar.startOfDay(for: .now)
        while streak < 365, !discardDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        let joined = calendar.startOfDay(for: profile.joinedAt)
        let age = (calendar.dateComponents([.day], from: joined, to: calendar.startOfDay(for: .now)).day ?? 0) + 1
        return min(streak, max(age, 1))
    }

    // MARK: - Grocery runs

    /// Stores a finished shopping trip and pushes every product into the stock.
    func finishGroceryRun(_ items: [FoodItem]) {
        guard !items.isEmpty else { return }
        add(items)

        let value = items.reduce(0.0) { $0 + $1.estimatedValue * max($1.quantity, 1) }
        groceryRuns.append(GroceryRun(date: .now, productCount: items.count, estimatedValue: value))

        // Anything bought is no longer missing.
        let boughtKeys = items.map { MealEngine.normalize($0.name) }
        shoppingList.removeAll { item in
            boughtKeys.contains { MealEngine.normalize(item.name).contains($0) || $0.contains(MealEngine.normalize(item.name)) }
        }

        banner = BannerMessage(
            text: items.count > 1
                ? S.Banner.itemsAdded.f(items.count)
                : S.Banner.itemAdded.f(items.count),
            tone: .success
        )
    }

    // MARK: - Cooking

    /// Applies the (user-adjusted) stock deductions and records the savings estimate.
    func cook(_ meal: Meal, deductions: [StockDeduction]) {
        var rescuedValue: Double = 0
        var rescuedCount = 0
        var rescued: [WasteEvent] = []

        for deduction in deductions where deduction.used > 0 {
            guard let index = inventory.firstIndex(where: { $0.id == deduction.itemID }) else { continue }
            let item = inventory[index]
            let remaining = max(item.quantity - deduction.used, 0)

            if item.status == .rescue || item.status == .plan || item.isOpened {
                rescuedCount += 1
                let share = item.quantity > 0 ? min(deduction.used / item.quantity, 1) : 1
                rescuedValue += item.estimatedValue * share
                rescued.append(WasteEvent(itemName: item.name, emoji: item.emoji, outcome: .saved))
            }

            if remaining <= 0.001 {
                inventory.remove(at: index)
            } else {
                inventory[index].quantity = (remaining * 100).rounded() / 100
                inventory[index].isOpened = true
            }
        }

        wasteLog.append(contentsOf: rescued)

        let saved = max(rescuedValue - meal.extraCost, 0)
        cookedLog.append(CookedMeal(
            recipeName: meal.name,
            date: .now,
            savedItems: rescuedCount,
            moneySaved: saved,
            wasZeroEuro: meal.isZeroEuro
        ))

        bumpChallenge(matching: "Cuisiner 3 repas avec ton stock", by: 1)
        bumpChallenge(matching: "Sauver 5 produits", by: rescuedCount)
        if meal.isZeroEuro {
            bumpChallenge(matching: "Réussir un repas à 0 €", by: 1)
        }

        banner = BannerMessage(
            text: meal.isZeroEuro
                ? S.Banner.zeroCostCooked.f(Units.zeroCostLabel)
                : (rescuedCount > 1
                    ? S.Banner.stockUpdatedPlural.f(rescuedCount)
                    : S.Banner.stockUpdated.f(rescuedCount)),
            tone: .success
        )
    }

    // MARK: - Meals

    func suggestions(zeroEuroOnly: Bool = false, focusItems: [FoodItem] = []) -> [Meal] {
        MealEngine.curatedSuggestions(
            inventory: inventory,
            profile: profile,
            zeroEuroOnly: zeroEuroOnly,
            focusNames: focusItems.map(\.name),
            servings: profile.householdSize
        )
    }

    func resolve(_ meal: Meal) -> Meal {
        MealEngine.resolve(meal, inventory: inventory)
    }

    // MARK: - Shopping list

    func addToShoppingList(_ items: [ShoppingItem]) {
        var added = 0
        for item in items where !shoppingList.contains(where: {
            MealEngine.normalize($0.name) == MealEngine.normalize(item.name)
        }) {
            shoppingList.append(item)
            added += 1
        }
        banner = BannerMessage(
            text: added > 0 ? S.Banner.addedToList.s : S.Banner.alreadyInList.s,
            tone: .info
        )
    }

    func toggleShoppingItem(_ item: ShoppingItem) {
        guard let index = shoppingList.firstIndex(where: { $0.id == item.id }) else { return }
        shoppingList[index].isChecked.toggle()
    }

    func clearCheckedShoppingItems() {
        shoppingList.removeAll { $0.isChecked }
    }

    private func bumpChallenge(matching title: String, by amount: Int) {
        guard amount > 0, let index = challenges.firstIndex(where: { $0.title == title }) else { return }
        challenges[index].progress = min(challenges[index].progress + amount, challenges[index].target)
    }

    // MARK: - Impact (all values explicitly presented as estimates)

    var weeklyImpact: ImpactSummary {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recent = cookedLog.filter { $0.date >= weekAgo }
        let savedItems = recent.reduce(0) { $0 + $1.savedItems }
        return ImpactSummary(
            savedItems: savedItems,
            mealsCooked: recent.count,
            moneySaved: recent.reduce(0) { $0 + $1.moneySaved },
            wasteAvoidedKg: Double(savedItems) * 0.28,
            weeklyGoal: max(profile.householdSize * 6, 10)
        )
    }

    var lifetimeImpact: ImpactSummary {
        let savedItems = cookedLog.reduce(0) { $0 + $1.savedItems }
        return ImpactSummary(
            savedItems: savedItems,
            mealsCooked: cookedLog.count,
            moneySaved: cookedLog.reduce(0) { $0 + $1.moneySaved },
            wasteAvoidedKg: Double(savedItems) * 0.28,
            weeklyGoal: 0
        )
    }

    func resetOnboarding() {
        profile.hasCompletedOnboarding = false
    }
}

/// A meal cooked through the app.
nonisolated struct CookedMeal: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var recipeName: String
    var date: Date
    var savedItems: Int
    var moneySaved: Double
    var wasZeroEuro: Bool

    /// Seed history so the savings dashboard is never empty on first launch.
    nonisolated static var seed: [CookedMeal] {
        func day(_ value: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: value, to: .now) ?? .now
        }
        return [
            CookedMeal(recipeName: "Soupe de légumes du frigo", date: day(-1), savedItems: 3, moneySaved: 4.20, wasZeroEuro: true),
            CookedMeal(recipeName: "Omelette jambon & fromage", date: day(-2), savedItems: 2, moneySaved: 3.10, wasZeroEuro: true),
            CookedMeal(recipeName: "Riz sauté jambon & courgettes", date: day(-3), savedItems: 2, moneySaved: 5.60, wasZeroEuro: false),
            CookedMeal(recipeName: "Pain perdu du placard", date: day(-4), savedItems: 2, moneySaved: 2.40, wasZeroEuro: true),
            CookedMeal(recipeName: "Gratin de courgettes", date: day(-5), savedItems: 3, moneySaved: 6.30, wasZeroEuro: false),
            CookedMeal(recipeName: "Pâtes sauce tomate & thon", date: day(-6), savedItems: 2, moneySaved: 3.00, wasZeroEuro: true),
            CookedMeal(recipeName: "Salade de lentilles", date: day(-12), savedItems: 4, moneySaved: 7.80, wasZeroEuro: true),
            CookedMeal(recipeName: "Quiche du frigo", date: day(-19), savedItems: 5, moneySaved: 9.40, wasZeroEuro: false),
            CookedMeal(recipeName: "Curry de légumes", date: day(-26), savedItems: 4, moneySaved: 6.10, wasZeroEuro: true),
            CookedMeal(recipeName: "Gratin de pâtes", date: day(-33), savedItems: 3, moneySaved: 5.20, wasZeroEuro: false)
        ]
    }
}

/// One finished grocery scanning session.
nonisolated struct GroceryRun: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var date: Date
    var productCount: Int
    var estimatedValue: Double
}

nonisolated struct BannerMessage: Identifiable, Equatable, Sendable {
    nonisolated enum Tone: Sendable { case success, info, warning }

    var id: UUID = UUID()
    var text: String
    var tone: Tone
}

/// Shared money / number formatting, following the reader's language.
///
/// These are SAVEAT's own estimates. Subscription prices never come through
/// here — they always come from the App Store for the user's own country.
nonisolated enum Format {
    /// An estimated value, in the reader's currency: euros for French and
    /// Spanish readers, dollars for US ones, reais, yuan and rupees elsewhere.
    nonisolated static func euro(_ value: Double, decimals: Int = 2) -> String {
        let language = LanguageRuntime.current
        let formatter = NumberFormatter()
        formatter.locale = language.locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        let number = formatter.string(from: NSNumber(value: value)) ?? "0"
        switch language {
        case .fr, .es: return "\(number)\u{00a0}€"
        case .en: return "$\(number)"
        case .enGB: return "£\(number)"
        case .ptBR: return "R$\u{00a0}\(number)"
        case .zhCN: return "¥\(number)"
        case .hi: return "₹\(number)"
        }
    }

    /// Food weight avoided, in kilos for metric readers and pounds for the US.
    nonisolated static func kg(_ value: Double) -> String {
        guard LanguageRuntime.current.usesMetric else {
            return String(format: "%.1f lb", value * 2.20462)
        }
        let text = String(format: "%.1f kg", value)
        return LanguageRuntime.current.usesCommaDecimal
            ? text.replacingOccurrences(of: ".", with: ",")
            : text
    }

    nonisolated static func grams(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "\(Int(rounded)) g"
        }
        let text = String(format: "%.1f g", rounded)
        return LanguageRuntime.current.usesCommaDecimal
            ? text.replacingOccurrences(of: ".", with: ",")
            : text
    }

    /// Stock quantities: whole numbers stay whole, halves read as ½.
    nonisolated static func quantity(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded() { return "\(Int(rounded))" }
        if abs(rounded - 0.5) < 0.01 { return "½" }
        if abs(rounded - 0.25) < 0.01 { return "¼" }
        if abs(rounded - 0.75) < 0.01 { return "¾" }
        let whole = floor(rounded)
        let fraction = rounded - whole
        if abs(fraction - 0.5) < 0.01 { return "\(Int(whole)) ½" }
        let text = String(format: "%.1f", rounded)
        return LanguageRuntime.current.usesCommaDecimal
            ? text.replacingOccurrences(of: ".", with: ",")
            : text
    }
}
