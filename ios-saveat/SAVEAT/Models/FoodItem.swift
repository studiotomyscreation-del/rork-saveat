import Foundation

/// Where a food item is stored in the household.
nonisolated enum StorageLocation: String, Codable, CaseIterable, Identifiable, Sendable {
    case fridge
    case pantry
    case freezer

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .fridge: S.Storage.fridge.s
        case .pantry: S.Storage.pantry.s
        case .freezer: S.Storage.freezer.s
        }
    }

    nonisolated var shortTitle: String { title }

    nonisolated var emoji: String {
        switch self {
        case .fridge: "🧊"
        case .pantry: "🥫"
        case .freezer: "❄️"
        }
    }

    nonisolated var symbol: String {
        switch self {
        case .fridge: "refrigerator"
        case .pantry: "cabinet"
        case .freezer: "snowflake"
        }
    }
}

/// Freshness bucket derived from the user's own best-before input — never from image analysis.
nonisolated enum FreshnessState: String, Codable, Sendable, CaseIterable {
    case fresh
    case soon
    case urgent

    nonisolated var label: String {
        switch self {
        case .fresh: S.Freshness.fresh.s
        case .soon: S.Freshness.soon.s
        case .urgent: S.Freshness.urgent.s
        }
    }

    nonisolated var dot: String {
        switch self {
        case .fresh: "🟢"
        case .soon: "🟠"
        case .urgent: "🔴"
        }
    }

    nonisolated var order: Int {
        switch self {
        case .urgent: 0
        case .soon: 1
        case .fresh: 2
        }
    }
}

/// Food category, used for the smart shopping list and inventory grouping.
nonisolated enum FoodCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case produce
    case dairy
    case protein
    case grocery
    case frozen

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .produce: S.Category.produce.s
        case .dairy: S.Category.dairy.s
        case .protein: S.Category.protein.s
        case .grocery: S.Category.grocery.s
        case .frozen: S.Category.frozen.s
        }
    }

    nonisolated var emoji: String {
        switch self {
        case .produce: "🥕"
        case .dairy: "🥛"
        case .protein: "🥩"
        case .grocery: "🥫"
        case .frozen: "🧊"
        }
    }
}

/// A single food item in the household stock.
nonisolated struct FoodItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    var emoji: String
    /// Stock units left. Fractional values express opened packs (0.5 = half a pack).
    var quantity: Double
    var unit: String
    var category: FoodCategory
    var location: StorageLocation
    /// Best-before date entered by the user or read from the packaging. Nil means "no date known".
    var bestBefore: Date?
    /// Kind of date printed on the pack (DLC / DDM), as told by the user.
    /// Optional so items persisted before this feature keep decoding — read it
    /// through `dateType`, never directly.
    var dateKind: DateKind?
    var isOpened: Bool = false
    /// Rough retail value in euros, used for savings estimates (always presented as an estimate).
    var estimatedValue: Double = 1.5
    var addedAt: Date = .now
    /// Barcode when the item came from a grocery scan.
    var barcode: String?
    var brand: String?
    /// Full product record when scanned, so the SAVEAT score stays available.
    var product: ScannedProduct?
    /// Extra keywords helping the meal engine match this item.
    var matchKeys: [String] = []

    nonisolated var daysLeft: Int? {
        guard let bestBefore else { return nil }
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.startOfDay(for: bestBefore)
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }

    /// Kind of date, defaulting to "not specified" for older stock items.
    nonisolated var dateType: DateKind { dateKind ?? .unknown }

    /// Priority level derived from the date. Evolves on its own as days pass.
    nonisolated var status: ConsumptionStatus { ExpiryRules.status(daysLeft: daysLeft) }

    /// True once the date is reached or passed.
    nonisolated var isPastDate: Bool { status == .reached }

    /// A passed "à consommer jusqu'au" date: SAVEAT stops suggesting this product
    /// in meals rather than encouraging its consumption.
    nonisolated var isBlockedForMeals: Bool {
        dateType == .dlc && status == .reached
    }

    /// Cautious wording shown when the date is reached, or nil before that.
    nonisolated var safetyNotice: String? {
        status == .reached ? dateType.passedNotice : nil
    }

    /// Legacy freshness bucket, now derived from `status` so the two can never diverge.
    nonisolated var freshness: FreshnessState {
        switch status {
        case .keep: .fresh
        case .plan: .soon
        case .rescue, .reached: .urgent
        }
    }

    /// "2", "½", "1,5" — never "2.0".
    nonisolated var quantityText: String { Format.quantity(quantity) }

    nonisolated var stockLine: String {
        "\(quantityText) \(FoodUnits.display(unit, quantity: quantity))"
    }

    nonisolated var displayName: String { FoodNames.display(name) }

    /// Human friendly deadline copy, e.g. "dans 3 jours" or "in 3 days".
    ///
    /// Past a week the exact date is shown in the reader's own format, so a US
    /// user reads "Sep 12" where a French user reads "12 sept.".
    nonisolated var deadlineText: String {
        guard let bestBefore, let days = daysLeft else { return S.Common.noDate.s }
        switch days {
        case ..<0: return S.Common.expired.s
        case 0: return S.Common.today.s
        case 1: return S.Common.tomorrow.s
        case 2...6: return S.Common.inDays.f(days)
        default: return Units.shortDate(bestBefore)
        }
    }

    /// Builds a stock line from a scanned grocery product.
    nonisolated static func from(
        product: ScannedProduct,
        quantity: Double = 1,
        bestBefore: Date? = nil,
        dateKind: DateKind = .unknown
    ) -> FoodItem {
        FoodItem(
            name: product.displayTitle,
            emoji: product.emoji,
            quantity: quantity,
            unit: product.unit,
            category: product.suggestedCategory,
            location: product.suggestedLocation,
            bestBefore: bestBefore,
            dateKind: dateKind,
            estimatedValue: product.estimatedPrice,
            barcode: product.barcode,
            brand: product.brand,
            product: product
        )
    }
}
