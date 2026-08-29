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
        name.isEmpty ? "Produit sans nom" : name
    }

    nonisolated var subtitle: String {
        [brand, packagingText].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " • ")
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
        case 80...: "Excellent choix"
        case 60..<80: "Bon produit"
        case 40..<60: "Correct"
        case 20..<40: "À limiter"
        default: "À consommer rarement"
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
            case .a: points = 30; verdict = "Très bonne"; tone = .good
            case .b: points = 18; verdict = "Bonne"; tone = .good
            case .c: points = 4; verdict = "Moyenne"; tone = .medium
            case .d: points = -12; verdict = "Faible"; tone = .poor
            case .e: points = -24; verdict = "Très faible"; tone = .poor
            }
            total += points
            criteria.append(Criterion(
                emoji: "🥦", title: "Nutrition", verdict: verdict,
                detail: "Nutri-Score \(grade.letter) publié pour ce produit.",
                points: points, tone: tone
            ))
        }

        if let sugars = n.sugars {
            let points: Int
            let verdict: String
            let tone: ScoreTone
            switch sugars {
            case ..<5: points = 8; verdict = "Faibles"; tone = .good
            case 5..<12: points = 2; verdict = "Modérés"; tone = .medium
            case 12..<22: points = -6; verdict = "Élevés"; tone = .poor
            default: points = -12; verdict = "Très élevés"; tone = .poor
            }
            total += points
            criteria.append(Criterion(
                emoji: "🍬", title: "Sucres", verdict: verdict,
                detail: "\(Format.grams(sugars)) pour 100 g.",
                points: points, tone: tone
            ))
        }

        if let salt = n.salt {
            let points: Int
            let verdict: String
            let tone: ScoreTone
            switch salt {
            case ..<0.3: points = 6; verdict = "Faible"; tone = .good
            case 0.3..<1: points = 1; verdict = "Modéré"; tone = .medium
            case 1..<1.5: points = -5; verdict = "Élevé"; tone = .poor
            default: points = -10; verdict = "Très élevé"; tone = .poor
            }
            total += points
            criteria.append(Criterion(
                emoji: "🧂", title: "Sel", verdict: verdict,
                detail: "\(Format.grams(salt)) pour 100 g.",
                points: points, tone: tone
            ))
        }

        if let sat = n.saturatedFat {
            let points: Int
            let verdict: String
            let tone: ScoreTone
            switch sat {
            case ..<1.5: points = 6; verdict = "Faibles"; tone = .good
            case 1.5..<5: points = 1; verdict = "Modérées"; tone = .medium
            case 5..<10: points = -5; verdict = "Élevées"; tone = .poor
            default: points = -10; verdict = "Très élevées"; tone = .poor
            }
            total += points
            criteria.append(Criterion(
                emoji: "🧈", title: "Graisses saturées", verdict: verdict,
                detail: "\(Format.grams(sat)) pour 100 g.",
                points: points, tone: tone
            ))
        }

        if let proteins = n.proteins, proteins >= 8 {
            total += 5
            criteria.append(Criterion(
                emoji: "💪", title: "Protéines", verdict: "Intéressantes",
                detail: "\(Format.grams(proteins)) pour 100 g.",
                points: 5, tone: .good
            ))
        }

        if let fiber = n.fiber, fiber >= 3 {
            total += 5
            criteria.append(Criterion(
                emoji: "🌾", title: "Fibres", verdict: "Bonne source",
                detail: "\(Format.grams(fiber)) pour 100 g.",
                points: 5, tone: .good
            ))
        }

        if let nova = product.nova {
            let points: Int
            let verdict: String
            let tone: ScoreTone
            switch nova {
            case 1: points = 12; verdict = "Aliment brut"; tone = .good
            case 2: points = 6; verdict = "Peu transformé"; tone = .good
            case 3: points = -5; verdict = "Transformé"; tone = .medium
            default: points = -16; verdict = "Ultra-transformé"; tone = .poor
            }
            total += points
            criteria.append(Criterion(
                emoji: "🏭", title: "Transformation", verdict: "NOVA \(nova) — \(verdict)",
                detail: "Classification NOVA du degré de transformation.",
                points: points, tone: tone
            ))
        }

        let additiveCount = product.additives.count
        if (product.additivesKnown ?? (product.nova != nil)) || additiveCount > 0 {
            let points = max(-15, -3 * additiveCount)
            total += points
            criteria.append(Criterion(
                emoji: "🧪", title: "Additifs identifiés", verdict: "\(additiveCount)",
                detail: additiveCount == 0
                    ? "Aucun additif listé dans la base de données."
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

    nonisolated static let methodology: [String] = [
        "On part de 50 points, puis on ajoute ou retire des points selon les données publiques du produit.",
        "Le Nutri-Score officiel pèse le plus lourd quand il est publié.",
        "Le groupe NOVA mesure le degré de transformation, pas la qualité gustative.",
        "Chaque additif listé retire 3 points, dans la limite de 15.",
        "Sucres, sel et graisses saturées sont comparés aux repères pour 100 g.",
        "SAVEAT n'est pas un avis médical et ne remplace pas l'étiquette du produit."
    ]
}
