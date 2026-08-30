import Foundation

/// Which kind of date is printed on the packaging.
///
/// SAVEAT never guesses this: it comes from the user, who reads the pack.
/// The distinction matters because a passed DLC and a passed DDM do not carry
/// the same meaning at all.
nonisolated enum DateKind: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Date limite de consommation — "à consommer jusqu'au".
    case dlc
    /// Date de durabilité minimale — "à consommer de préférence avant".
    case ddm
    /// The user has not told us which kind of date this is.
    case unknown

    nonisolated var id: String { rawValue }

    /// Short badge label, e.g. shown next to a date.
    nonisolated var badge: String {
        switch self {
        case .dlc: "DLC"
        case .ddm: "DDM"
        case .unknown: "Date"
        }
    }

    /// Full label used in pickers and on the product sheet.
    nonisolated var title: String {
        switch self {
        case .dlc: "DLC — À consommer jusqu'au"
        case .ddm: "DDM — À consommer de préférence avant"
        case .unknown: "Non renseigné"
        }
    }

    /// Compact picker label.
    nonisolated var pickerTitle: String {
        switch self {
        case .dlc: "DLC"
        case .ddm: "DDM"
        case .unknown: "Non renseigné"
        }
    }

    nonisolated var helpText: String {
        switch self {
        case .dlc: "À consommer jusqu'au — date de sécurité."
        case .ddm: "À consommer de préférence avant — date de qualité."
        case .unknown: "Regarde l'emballage pour connaître le type de date."
        }
    }

    /// Wording shown once the date is reached or passed.
    ///
    /// Never states that a food is safe to eat: SAVEAT has no reliable basis
    /// for such a claim and always sends the user back to the packaging.
    nonisolated var passedNotice: String {
        switch self {
        case .dlc:
            "Date limite de consommation dépassée. SAVEAT ne recommande pas la consommation après une DLC dépassée. Vérifie les indications figurant sur l'emballage et les recommandations officielles."
        case .ddm:
            "Date de durabilité minimale dépassée. Cela ne signifie pas automatiquement que le produit est impropre à la consommation. Vérifie son emballage, ses conditions de conservation et son état avant toute utilisation."
        case .unknown:
            "La date est atteinte. Le type de date n'est pas renseigné : vérifie l'emballage pour savoir s'il s'agit d'une DLC (date limite de consommation) ou d'une DDM (date de durabilité minimale)."
        }
    }
}

/// The four priority levels SAVEAT derives from a stored date.
///
/// They evolve on their own as days pass — the user never has to refresh anything.
nonisolated enum ConsumptionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case keep
    case plan
    case rescue
    case reached

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .keep: "À conserver"
        case .plan: "À prévoir"
        case .rescue: "À sauver"
        case .reached: "Date atteinte / dépassée"
        }
    }

    /// Shorter variant for pills and rows.
    nonisolated var shortTitle: String {
        switch self {
        case .keep: "À conserver"
        case .plan: "À prévoir"
        case .rescue: "À sauver"
        case .reached: "Date atteinte"
        }
    }

    nonisolated var dot: String {
        switch self {
        case .keep: "🟢"
        case .plan: "🟡"
        case .rescue: "🟠"
        case .reached: "🔴"
        }
    }

    nonisolated var detail: String {
        switch self {
        case .keep: "Rien d'urgent."
        case .plan: "La date approche — pense à l'intégrer à tes prochains repas."
        case .rescue: "À consommer rapidement pour éviter de le gaspiller."
        case .reached: "La date est atteinte ou dépassée."
        }
    }

    /// Most critical first, used to sort the stock.
    nonisolated var order: Int {
        switch self {
        case .reached: 0
        case .rescue: 1
        case .plan: 2
        case .keep: 3
        }
    }
}

/// Single place where the priority thresholds live.
///
/// Adjusting these constants reclassifies the whole stock — no other code
/// hardcodes a number of days.
nonisolated enum ExpiryRules {
    /// Strictly more days left than this → 🟢 À conserver.
    nonisolated static let keepAboveDays: Int = 5
    /// From this many days left, and up to `keepAboveDays` → 🟡 À prévoir (J-5 … J-3).
    nonisolated static let planFromDays: Int = 3
    /// Reminder offsets, in days before the date.
    nonisolated static let reminderOffsets: [Int] = [5, 2, 1, 0]

    /// Classifies an item from the days left before its date.
    ///
    /// A missing date means "unknown", never "urgent": SAVEAT does not invent dates.
    nonisolated static func status(daysLeft: Int?) -> ConsumptionStatus {
        guard let days = daysLeft else { return .keep }
        if days <= 0 { return .reached }
        if days > keepAboveDays { return .keep }
        if days >= planFromDays { return .plan }
        return .rescue
    }
}

/// How the household reminders are configured.
nonisolated struct ReminderSettings: Codable, Hashable, Sendable {
    var isEnabled: Bool = true
    var fiveDays: Bool = true
    var twoDays: Bool = true
    var oneDay: Bool = true
    var sameDay: Bool = true
    /// Hour of the day used for every reminder (local time).
    var hour: Int = 9

    /// Enabled offsets, in days before the date.
    nonisolated var offsets: [Int] {
        var result: [Int] = []
        if fiveDays { result.append(5) }
        if twoDays { result.append(2) }
        if oneDay { result.append(1) }
        if sameDay { result.append(0) }
        return result
    }

    nonisolated var hasAnyOffset: Bool { !offsets.isEmpty }
}

/// What happened to a product that left the stock.
nonisolated enum WasteOutcome: String, Codable, Sendable {
    /// Consumed before it was lost.
    case saved
    /// Thrown away.
    case discarded
}

/// One product leaving the stock, used for the anti-waste counters.
///
/// Deliberately stores no price: SAVEAT never claims a saving it cannot prove.
nonisolated struct WasteEvent: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var itemName: String
    var emoji: String
    var outcome: WasteOutcome
    var date: Date = .now
}
