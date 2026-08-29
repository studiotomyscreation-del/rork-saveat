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
        case .save: "Économiser"
        case .reduceWaste: "Moins gaspiller"
        case .eatBalanced: "Manger équilibré"
        case .eatLight: "Manger plus léger"
        case .moreProtein: "Plus de protéines"
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

nonisolated enum DietPreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case omnivore
    case flexitarian
    case vegetarian
    case vegan
    case pescatarian
    case halal

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .omnivore: "Je mange de tout"
        case .flexitarian: "Flexitarien"
        case .vegetarian: "Végétarien"
        case .vegan: "Végétalien"
        case .pescatarian: "Pescétarien"
        case .halal: "Halal"
        }
    }
}

nonisolated enum Allergen: String, Codable, CaseIterable, Identifiable, Sendable {
    case gluten, lactose, nuts, eggs, seafood, soy

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .gluten: "Gluten"
        case .lactose: "Lactose"
        case .nuts: "Fruits à coque"
        case .eggs: "Œufs"
        case .seafood: "Fruits de mer"
        case .soy: "Soja"
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

    nonisolated var householdSize: Int { max(adults + children, 1) }

    nonisolated var householdText: String {
        var parts: [String] = ["\(adults) adulte\(adults > 1 ? "s" : "")"]
        if children > 0 { parts.append("\(children) enfant\(children > 1 ? "s" : "")") }
        return parts.joined(separator: " • ")
    }
}

/// Foods commonly excluded, offered as taps instead of typing.
nonisolated enum DislikeCatalog {
    nonisolated static let all: [String] = [
        "Champignons", "Poisson", "Épinards", "Olives", "Fromage bleu",
        "Courgettes", "Chou-fleur", "Foie", "Aubergines", "Piment"
    ]
}
