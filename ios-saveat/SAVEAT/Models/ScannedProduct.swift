import Foundation

/// Nutritional values per 100 g / 100 ml, as published by the food database.
nonisolated struct Nutriments: Codable, Hashable, Sendable {
    var energyKcal: Double?
    var sugars: Double?
    var salt: Double?
    var saturatedFat: Double?
    var fat: Double?
    var proteins: Double?
    var fiber: Double?

    nonisolated var isEmpty: Bool {
        energyKcal == nil && sugars == nil && salt == nil && saturatedFat == nil
            && fat == nil && proteins == nil && fiber == nil
    }
}

/// A grocery product recognised from its barcode.
nonisolated struct ScannedProduct: Identifiable, Codable, Hashable, Sendable {
    var barcode: String
    var name: String
    var brand: String?
    var imageURLString: String?
    /// Net weight / volume printed on the pack, e.g. "500 g".
    var packagingText: String?
    var ingredientsText: String?
    var allergens: [String] = []
    var additives: [String] = []
    /// `false` when the database publishes no additive information at all, so
    /// "no additive" is never confused with "not documented". Absent in older
    /// persisted items, hence optional.
    var additivesKnown: Bool?
    /// Official Nutri-Score letter when published ("a" … "e").
    var nutriScore: String?
    /// NOVA food-processing group, 1 to 4.
    var nova: Int?
    var nutriments: Nutriments = Nutriments()

    var suggestedLocation: StorageLocation = .pantry
    var suggestedCategory: FoodCategory = .grocery
    var emoji: String = "🥫"
    var unit: String = "unité"
    /// Rough retail price in euros — always shown as an estimate.
    var estimatedPrice: Double = 2.0
    /// Typical shelf life used to pre-fill the best-before picker; never a claim about safety.
    var defaultShelfLifeDays: Int?
    /// True when the data comes from the offline demo catalogue instead of the online database.
    var isDemoData: Bool = false

    nonisolated var id: String { barcode }

    nonisolated var imageURL: URL? {
        guard let imageURLString, !imageURLString.isEmpty else { return nil }
        return URL(string: imageURLString)
    }

    nonisolated var displayTitle: String {
        name.isEmpty ? S.Product.unnamed.s : FoodNames.display(name)
    }

    /// Brand and pack size, the latter rewritten in the reader's units.
    nonisolated var subtitle: String {
        [brand, packagingText.map(Units.packaging)]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }

    nonisolated var score: SaveatScore { SaveatScore.evaluate(self) }

    /// The published Nutri-Score, or `nil` when the database has none.
    /// Guards against Open Food Facts' `unknown` / `not-applicable` placeholders.
    nonisolated var officialNutriScore: NutriScoreGrade? { NutriScoreGrade(published: nutriScore) }

    /// Plain-language nutritional read, built only from published data.
    nonisolated var nutritionAnalysis: NutritionAnalysis { NutritionAnalysis.evaluate(self) }
}

/// How a single criterion reads on the SAVEAT score card.
nonisolated enum ScoreTone: String, Sendable {
    case good, medium, poor, neutral
}

/// SAVEAT's own transparent product score.
///
/// It is a readability aid built from public data (Nutri-Score, NOVA group,
/// additives count, sugar / salt / saturated fat levels). It is not a medical
/// assessment and never states whether a food is safe or unsafe to eat.
nonisolated struct SaveatScore: Hashable, Sendable {
    nonisolated struct Criterion: Identifiable, Hashable, Sendable {
        var emoji: String
        var title: String
        var verdict: String
        var detail: String
        var points: Int
        var tone: ScoreTone

        nonisolated var id: String { title }

        nonisolated var pointsText: String {
            points > 0 ? "+\(points)" : "\(points)"
        }
    }

    var value: Int
    var criteria: [Criterion]
    var hasEnoughData: Bool

    nonisolated var label: String {
        switch value {
        case 80...: S.Product.excellent.s
        case 60..<80: S.Product.good.s
        case 40..<60: S.Product.fine.s
        case 20..<40: S.Product.limit.s
        default: S.Product.rarely.s
        }
    }

    nonisolated var tone: ScoreTone {
        switch value {
        case 65...: .good
        case 40..<65: .medium
        default: .poor
        }
    }

    /// Base + weighted criteria, clamped to 0…100. Every step is shown to the user.
    nonisolated static func evaluate(_ product: ScannedProduct) -> SaveatScore {
        var criteria: [Criterion] = []
        var total = 50
        let n = product.nutriments

        if let grade = product.officialNutriScore {
            let points: Int
            let verdict: String
            let tone: ScoreTone
            switch grade {
            case .a: points = 30; verdict = S.Product.veryGood.s; tone = .good
            case .b: points = 18; verdict = S.Product.goodVerdict.s; tone = .good
            case .c: points = 4; verdict = S.Product.average.s; tone = .medium
            case .d: points = -12; verdict = S.Product.weak.s; tone = .poor
            case .e: points = -24; verdict = S.Product.veryWeak.s; tone = .poor
            }
            total += points
            criteria.append(Criterion(
                emoji: "🥦", title: S.Product.nutrition.s, verdict: verdict,
                detail: S.Product.nutriScorePublished.f(grade.letter),
                points: points, tone: tone
            ))
        }

        if let sugars = n.sugars {
            let points: Int
            let verdict: String
            let tone: ScoreTone
            switch sugars {
            case ..<5: points = 8; verdict = S.Product.low.s; tone = .good
            case 5..<12: points = 2; verdict = S.Product.moderate.s; tone = .medium
            case 12..<22: points = -6; verdict = S.Product.high.s; tone = .poor
            default: points = -12; verdict = S.Product.veryHigh.s; tone = .poor
            }
            total += points
            criteria.append(Criterion(
                emoji: "🍬", title: S.Product.sugars.s, verdict: verdict,
                detail: S.Product.per100g.f(Format.grams(sugars)),
                points: points, tone: tone
            ))
        }

        if let salt = n.salt {
            let points: Int
            let verdict: String
            let tone: ScoreTone
            switch salt {
            case ..<0.3: points = 6; verdict = S.Product.lowSingular.s; tone = .good
            case 0.3..<1: points = 1; verdict = S.Product.moderateSingular.s; tone = .medium
            case 1..<1.5: points = -5; verdict = S.Product.highSingular.s; tone = .poor
            default: points = -10; verdict = S.Product.veryHighSingular.s; tone = .poor
            }
            total += points
            criteria.append(Criterion(
                emoji: "🧂", title: S.Product.salt.s, verdict: verdict,
                detail: S.Product.per100g.f(Format.grams(salt)),
                points: points, tone: tone
            ))
        }

        if let sat = n.saturatedFat {
            let points: Int
            let verdict: String
            let tone: ScoreTone
            switch sat {
            case ..<1.5: points = 6; verdict = S.Product.low.s; tone = .good
            case 1.5..<5: points = 1; verdict = S.Product.moderate.s; tone = .medium
            case 5..<10: points = -5; verdict = S.Product.high.s; tone = .poor
            default: points = -10; verdict = S.Product.veryHigh.s; tone = .poor
            }
            total += points
            criteria.append(Criterion(
                emoji: "🧈", title: S.Product.saturatedFat.s, verdict: verdict,
                detail: S.Product.per100g.f(Format.grams(sat)),
                points: points, tone: tone
            ))
        }

        if let proteins = n.proteins, proteins >= 8 {
            total += 5
            criteria.append(Criterion(
                emoji: "💪", title: S.Product.proteins.s, verdict: S.Product.interesting.s,
                detail: S.Product.per100g.f(Format.grams(proteins)),
                points: 5, tone: .good
            ))
        }

        if let fiber = n.fiber, fiber >= 3 {
            total += 5
            criteria.append(Criterion(
                emoji: "🌾", title: S.Product.fiber.s, verdict: S.Product.goodSource.s,
                detail: S.Product.per100g.f(Format.grams(fiber)),
                points: 5, tone: .good
            ))
        }

        if let nova = product.nova {
            let points: Int
            let verdict: String
            let tone: ScoreTone
            switch nova {
            case 1: points = 12; verdict = S.Product.rawFood.s; tone = .good
            case 2: points = 6; verdict = S.Product.lightlyProcessed.s; tone = .good
            case 3: points = -5; verdict = S.Product.processed.s; tone = .medium
            default: points = -16; verdict = S.Product.ultraProcessed.s; tone = .poor
            }
            total += points
            criteria.append(Criterion(
                emoji: "🏭", title: S.Product.processing.s, verdict: S.Product.novaTitle.f(nova, verdict),
                detail: S.Product.novaDetail.s,
                points: points, tone: tone
            ))
        }

        let additiveCount = product.additives.count
        if (product.additivesKnown ?? (product.nova != nil)) || additiveCount > 0 {
            let points = max(-15, -3 * additiveCount)
            total += points
            criteria.append(Criterion(
                emoji: "🧪", title: S.Product.additives.s, verdict: "\(additiveCount)",
                detail: additiveCount == 0
                    ? S.Product.noAdditives.s
                    : product.additives.prefix(4).joined(separator: ", ").uppercased(),
                points: points, tone: additiveCount == 0 ? .good : (additiveCount <= 2 ? .medium : .poor)
            ))
        }

        return SaveatScore(
            value: min(max(total, 0), 100),
            criteria: criteria,
            hasEnoughData: criteria.count >= 3
        )
    }

    nonisolated static var methodology: [String] {
        S.Product.methodology.map(\.s)
    }
}
