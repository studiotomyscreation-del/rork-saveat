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
    ///
    /// US packs print "Use By" and "Best By" rather than DLC / DDM, so the badge
    /// follows the reader instead of the French regulatory wording.
    nonisolated var badge: String {
        switch self {
        case .dlc: S.DateType.useByBadge.s
        case .ddm: S.DateType.bestByBadge.s
        case .unknown: S.DateType.unknownBadge.s
        }
    }

    /// Full label used in pickers and on the product sheet.
    nonisolated var title: String {
        switch self {
        case .dlc: S.DateType.useByTitle.s
        case .ddm: S.DateType.bestByTitle.s
        case .unknown: S.DateType.unknownTitle.s
        }
    }

    /// Compact picker label.
    nonisolated var pickerTitle: String {
        switch self {
        case .dlc: S.DateType.useByPicker.s
        case .ddm: S.DateType.bestByPicker.s
        case .unknown: S.DateType.unknownPicker.s
        }
    }

    nonisolated var helpText: String {
        switch self {
        case .dlc: S.DateType.useByHelp.s
        case .ddm: S.DateType.bestByHelp.s
        case .unknown: S.DateType.unknownHelp.s
        }
    }

    /// Wording shown once the date is reached or passed.
    ///
    /// Never states that a food is safe to eat: SAVEAT has no reliable basis
    /// for such a claim and always sends the user back to the packaging.
    nonisolated var passedNotice: String {
        switch self {
        case .dlc: S.DateType.useByPassed.s
        case .ddm: S.DateType.bestByPassed.s
        case .unknown: S.DateType.unknownPassed.s
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
        case .keep: S.Status.keepTitle.s
        case .plan: S.Status.planTitle.s
        case .rescue: S.Status.rescueTitle.s
        case .reached: S.Status.reachedTitle.s
        }
    }

    /// Shorter variant for pills and rows.
    nonisolated var shortTitle: String {
        switch self {
        case .keep: S.Status.keepShort.s
        case .plan: S.Status.planShort.s
        case .rescue: S.Status.rescueShort.s
        case .reached: S.Status.reachedShort.s
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
        case .keep: S.Status.keepDetail.s
        case .plan: S.Status.planDetail.s
        case .rescue: S.Status.rescueDetail.s
        case .reached: S.Status.reachedDetail.s
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
/// The value is an ESTIMATE and only present when the product actually carried a
/// known price. It stays optional so events saved before this field keep
/// decoding — a missing value simply contributes nothing to the money figure,
/// because SAVEAT never claims a saving it cannot back up.
nonisolated struct WasteEvent: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var itemName: String
    var emoji: String
    var outcome: WasteOutcome
    var date: Date = .now
    /// Estimated value of what was saved, when known.
    var estimatedValue: Double?
    /// True when this save came from cooking a meal, whose value is already
    /// counted in the cooking history — prevents counting the same save twice.
    var fromMeal: Bool?

    /// Money this event contributes on its own, avoiding any double count.
    nonisolated var standaloneValue: Double {
        (fromMeal == true) ? 0 : (estimatedValue ?? 0)
    }
}
