import Foundation

nonisolated enum HouseholdGoal: String, Codable, CaseIterable, Identifiable, Sendable {
    case save
    case reduceWaste
    case eatBalanced
    case eatLight
    case moreProtein

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .save: S.Goal.save.s
        case .reduceWaste: S.Goal.reduceWaste.s
        case .eatBalanced: S.Goal.eatBalanced.s
        case .eatLight: S.Goal.eatLight.s
        case .moreProtein: S.Goal.moreProtein.s
        }
    }

    nonisolated var emoji: String {
        switch self {
        case .save: "💰"
        case .reduceWaste: "♻️"
        case .eatBalanced: "🥦"
        case .eatLight: "⚖️"
        case .moreProtein: "💪"
        }
    }
}

/// The household's main way of eating.
///
/// Stored as a language-independent id (`vegetarian`, `kosher`, …) so switching
/// the app's language never loses a saved preference — only the label changes.
nonisolated enum DietPreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case omnivore
    case flexitarian
    case vegetarian
    case vegan
    case pescatarian
    case halal
    case kosher

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .omnivore: S.Diet.omnivore.s
        case .flexitarian: S.Diet.flexitarian.s
        case .vegetarian: S.Diet.vegetarian.s
        case .vegan: S.Diet.vegan.s
        case .pescatarian: S.Diet.pescatarian.s
        case .halal: S.Diet.halal.s
        case .kosher: S.Diet.kosher.s
        }
    }

    /// Plain-language rule sent to the recipe assistant, in the reader's language.
    nonisolated var promptRule: String? {
        switch self {
        case .omnivore, .flexitarian: nil
        case .vegetarian: S.DietRule.vegetarian.s
        case .vegan: S.DietRule.vegan.s
        case .pescatarian: S.DietRule.pescatarian.s
        case .halal: S.DietRule.halal.s
        case .kosher: S.DietRule.kosher.s
        }
    }
}

/// Extra eating preferences that stack on top of the main diet.
///
/// Kept separate from `DietPreference` because these combine freely: someone can
/// be vegetarian AND eat low-GI. Ids stay language-independent.
nonisolated enum DietTag: String, Codable, CaseIterable, Identifiable, Sendable {
    case lowGI = "low_gi"

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .lowGI: S.Diet.lowGI.s
        }
    }

    /// One-line explanation shown under the toggle.
    nonisolated var detail: String {
        switch self {
        case .lowGI: S.Diet.lowGIDetail.s
        }
    }

    /// Rule sent to the recipe assistant, in the reader's language.
    nonisolated var promptRule: String {
        switch self {
        case .lowGI: S.DietRule.lowGI.s
        }
    }
}

nonisolated enum Allergen: String, Codable, CaseIterable, Identifiable, Sendable {
    case gluten, lactose, nuts, eggs, seafood, soy

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .gluten: S.Allergens.gluten.s
        case .lactose: S.Allergens.lactose.s
        case .nuts: S.Allergens.nuts.s
        case .eggs: S.Allergens.eggs.s
        case .seafood: S.Allergens.seafood.s
        case .soy: S.Allergens.soy.s
        }
    }
}

nonisolated struct UserProfile: Codable, Sendable {
    var adults: Int = 2
    var children: Int = 0
    var goal: HouseholdGoal = .reduceWaste
    var diet: DietPreference = .omnivore
    var allergens: Set<Allergen> = []
    var dislikes: Set<String> = []
    var weeklyBudget: Double = 80
    var hasCompletedOnboarding: Bool = false
    var joinedAt: Date = .now
    /// Extra preferences such as low-GI. Optional so profiles saved before this
    /// feature keep decoding untouched — read and write it through `dietTags`.
    var tags: Set<DietTag>?
    /// Anti-waste reminders. Optional so profiles saved before this feature keep
    /// decoding — read and write it through `reminderSettings`.
    var reminders: ReminderSettings?

    /// Reminder preferences, falling back to the default set-up.
    nonisolated var reminderSettings: ReminderSettings {
        get { reminders ?? ReminderSettings() }
        set { reminders = newValue }
    }

    /// Extra eating preferences, empty for profiles saved before they existed.
    nonisolated var dietTags: Set<DietTag> {
        get { tags ?? [] }
        set { tags = newValue }
    }

    nonisolated func hasTag(_ tag: DietTag) -> Bool { dietTags.contains(tag) }

    nonisolated var householdSize: Int { max(adults + children, 1) }

    nonisolated var householdText: String {
        var parts: [String] = ["\(adults) \(adults > 1 ? S.Household.adults.s : S.Household.adult.s)"]
        if children > 0 {
            parts.append("\(children) \(children > 1 ? S.Household.children.s : S.Household.child.s)")
        }
        return parts.joined(separator: " • ")
    }
}

/// Foods commonly excluded, offered as taps instead of typing.
///
/// The stored value stays French so profiles saved before the US version keep
/// their exclusions working — only the label shown changes with the language.
/// Anything the user typed themselves is displayed exactly as they wrote it.
nonisolated enum DislikeCatalog {
    nonisolated static let all: [String] = [
        "Champignons", "Poisson", "Épinards", "Olives", "Fromage bleu",
        "Courgettes", "Chou-fleur", "Foie", "Aubergines", "Piment"
    ]

    private static let labels: [String: Loc] = [
        "Champignons": S.Dislikes.mushrooms,
        "Poisson": S.Dislikes.fish,
        "Épinards": S.Dislikes.spinach,
        "Olives": S.Dislikes.olives,
        "Fromage bleu": S.Dislikes.blueCheese,
        "Courgettes": S.Dislikes.zucchini,
        "Chou-fleur": S.Dislikes.cauliflower,
        "Foie": S.Dislikes.liver,
        "Aubergines": S.Dislikes.eggplant,
        "Piment": S.Dislikes.chili
    ]

    /// Label for a stored exclusion, in the reader's language.
    nonisolated static func display(_ stored: String) -> String {
        labels[stored]?.s ?? stored
    }
}
