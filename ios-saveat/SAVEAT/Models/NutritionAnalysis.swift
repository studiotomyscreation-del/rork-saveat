import Foundation

/// The official Nutri-Score letter, when the product actually publishes one.
///
/// Open Food Facts also returns `unknown` or `not-applicable`; those are **not**
/// grades and must never be displayed as one, hence the validating initialiser.
nonisolated enum NutriScoreGrade: String, CaseIterable, Sendable, Hashable {
    case a, b, c, d, e

    /// Accepts only a published `a`…`e` grade; everything else is treated as absent.
    nonisolated init?(published raw: String?) {
        guard let raw else { return nil }
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleaned.count == 1, let grade = NutriScoreGrade(rawValue: cleaned) else { return nil }
        self = grade
    }

    nonisolated var letter: String { rawValue.uppercased() }

    /// The plain-French reading of the official grade.
    nonisolated var verdict: NutritionVerdict {
        switch self {
        case .a: .veryGood
        case .b: .good
        case .c: .average
        case .d: .limit
        case .e: .poor
        }
    }
}

/// The five-step appreciation SAVEAT shows above the details.
nonisolated enum NutritionVerdict: Sendable, Hashable {
    case veryGood
    case good
    case average
    case limit
    case poor

    nonisolated var title: String {
        switch self {
        case .veryGood: "Très bon"
        case .good: "Bon"
        case .average: "Moyen"
        case .limit: "À limiter"
        case .poor: "Faible qualité nutritionnelle"
        }
    }

    nonisolated var tone: ScoreTone {
        switch self {
        case .veryGood, .good: .good
        case .average: .medium
        case .limit, .poor: .poor
        }
    }
}

/// One readable line of the analysis: a strength or something to keep an eye on.
nonisolated struct NutritionPoint: Identifiable, Sendable, Hashable {
    var emoji: String
    var title: String
    var detail: String

    nonisolated var id: String { title }
}

/// What is known about the additives of a product.
///
/// `isKnown` distinguishes "the database lists no additive" from "the database has
/// no additive information at all" — the two must never be shown the same way.
nonisolated struct AdditivesInfo: Sendable, Hashable {
    var isKnown: Bool
    var codes: [String]

    nonisolated var count: Int { codes.count }

    /// French summary line, or the explicit unavailable notice.
    nonisolated var summary: String {
        guard isKnown else { return NutritionAnalysis.unavailableText }
        if codes.isEmpty { return "Aucun additif listé pour ce produit." }
        return "\(codes.count) additif\(codes.count > 1 ? "s" : "") listé\(codes.count > 1 ? "s" : "") dans la base de données."
    }

    /// `E330 — acide citrique (correcteur d'acidité)` when the code is known, else the raw code.
    nonisolated func describe(_ code: String) -> String {
        let normalised = code.uppercased()
        guard let name = AdditivesInfo.names[normalised] else { return normalised }
        return "\(normalised) — \(name)"
    }

    /// Standard names of the additives most often met on French shelves.
    /// Only documented entries are listed; unknown codes are shown as-is.
    private static let names: [String: String] = [
        "E100": "curcumine (colorant)",
        "E120": "cochenille (colorant)",
        "E150A": "caramel ordinaire (colorant)",
        "E150C": "caramel ammoniacal (colorant)",
        "E150D": "caramel au sulfite d'ammonium (colorant)",
        "E160A": "carotènes (colorant)",
        "E160C": "extrait de paprika (colorant)",
        "E162": "rouge de betterave (colorant)",
        "E163": "anthocyanes (colorant)",
        "E170": "carbonate de calcium",
        "E200": "acide sorbique (conservateur)",
        "E202": "sorbate de potassium (conservateur)",
        "E211": "benzoate de sodium (conservateur)",
        "E223": "métabisulfite de sodium (conservateur)",
        "E250": "nitrite de sodium (conservateur)",
        "E252": "nitrate de potassium (conservateur)",
        "E260": "acide acétique (acidifiant)",
        "E270": "acide lactique (acidifiant)",
        "E296": "acide malique (acidifiant)",
        "E300": "acide ascorbique — vitamine C (antioxydant)",
        "E301": "ascorbate de sodium (antioxydant)",
        "E306": "extrait riche en tocophérols (antioxydant)",
        "E316": "érythorbate de sodium (antioxydant)",
        "E322": "lécithines (émulsifiant)",
        "E330": "acide citrique (correcteur d'acidité)",
        "E331": "citrates de sodium (correcteur d'acidité)",
        "E333": "citrates de calcium (correcteur d'acidité)",
        "E338": "acide phosphorique (acidifiant)",
        "E339": "phosphates de sodium",
        "E340": "phosphates de potassium",
        "E401": "alginate de sodium (épaississant)",
        "E405": "alginate de propane-1,2-diol (épaississant)",
        "E406": "agar-agar (gélifiant)",
        "E407": "carraghénanes (épaississant)",
        "E410": "farine de graines de caroube (épaississant)",
        "E412": "gomme guar (épaississant)",
        "E414": "gomme arabique (épaississant)",
        "E415": "gomme xanthane (épaississant)",
        "E418": "gomme gellane (épaississant)",
        "E420": "sorbitol (édulcorant)",
        "E422": "glycérol (humectant)",
        "E440": "pectines (gélifiant)",
        "E450": "diphosphates (stabilisant)",
        "E451": "triphosphates (stabilisant)",
        "E460": "cellulose (anti-agglomérant)",
        "E464": "hydroxypropylméthylcellulose (épaississant)",
        "E466": "carboxyméthylcellulose (épaississant)",
        "E471": "mono- et diglycérides d'acides gras (émulsifiant)",
        "E472E": "esters d'acides gras (émulsifiant)",
        "E476": "polyricinoléate de polyglycérol (émulsifiant)",
        "E481": "stéaroyl-2-lactylate de sodium (émulsifiant)",
        "E500": "carbonates de sodium (poudre à lever)",
        "E501": "carbonates de potassium (poudre à lever)",
        "E503": "carbonates d'ammonium (poudre à lever)",
        "E504": "carbonates de magnésium (anti-agglomérant)",
        "E509": "chlorure de calcium (affermissant)",
        "E551": "dioxyde de silicium (anti-agglomérant)",
        "E621": "glutamate monosodique (exhausteur de goût)",
        "E627": "guanylate disodique (exhausteur de goût)",
        "E631": "inosinate disodique (exhausteur de goût)",
        "E635": "ribonucléotides disodiques (exhausteur de goût)",
        "E950": "acésulfame K (édulcorant)",
        "E951": "aspartame (édulcorant)",
        "E952": "cyclamates (édulcorant)",
        "E954": "saccharines (édulcorant)",
        "E955": "sucralose (édulcorant)",
        "E960": "glycosides de stéviol (édulcorant)",
        "E965": "maltitol (édulcorant)",
        "E967": "xylitol (édulcorant)",
        "E968": "érythritol (édulcorant)"
    ]
}

/// Plain-language nutritional read of a scanned product, built **only** from the
/// data the product actually publishes.
///
/// Nothing is ever inferred beyond what the numbers say: no Nutri-Score is
/// invented, no missing value is guessed, and every absent piece of information is
/// reported as `Information non disponible`. Thresholds mirror the ones already
/// used by `SaveatScore` so the two readings can never contradict each other.
nonisolated struct NutritionAnalysis: Sendable, Hashable {
    /// Where the appreciation comes from — shown to the user, never hidden.
    nonisolated enum Basis: Sendable, Hashable {
        /// The official Nutri-Score published for this product.
        case officialNutriScore(NutriScoreGrade)
        /// Derived from the published nutrient values because no Nutri-Score exists.
        case estimatedFromNutrients(usedFactors: Int)
        /// Not enough published data to say anything.
        case unavailable

        nonisolated var caption: String {
            switch self {
            case .officialNutriScore(let grade):
                "D'après le Nutri-Score officiel \(grade.letter) publié pour ce produit."
            case .estimatedFromNutrients(let count):
                "Aucun Nutri-Score publié. Estimation SAVEAT à partir des \(count) valeur\(count > 1 ? "s" : "") nutritionnelle\(count > 1 ? "s" : "") disponible\(count > 1 ? "s" : "")."
            case .unavailable:
                "Les données nutritionnelles de ce produit ne sont pas publiées."
            }
        }
    }

    static let unavailableText = "Information non disponible"

    /// Official grade, `nil` when the product does not publish one.
    var grade: NutriScoreGrade?
    /// `nil` when there is not enough published data to form an appreciation.
    var verdict: NutritionVerdict?
    var basis: Basis
    var positives: [NutritionPoint]
    var watchOuts: [NutritionPoint]
    var additives: AdditivesInfo
    /// Two or three sentences explaining what the product is really worth.
    var explanation: String
    /// Nutrient facts that the database does not publish for this product.
    var missingFacts: [String]

    /// True as soon as there is something factual to show.
    nonisolated var hasContent: Bool {
        grade != nil || verdict != nil || !positives.isEmpty || !watchOuts.isEmpty || additives.isKnown
    }

    // MARK: - Build

    nonisolated static func evaluate(_ product: ScannedProduct) -> NutritionAnalysis {
        let n = product.nutriments
        let grade = NutriScoreGrade(published: product.nutriScore)

        var positives: [NutritionPoint] = []
        var watchOuts: [NutritionPoint] = []
        var missing: [String] = []
        /// 0 = low, 3 = very high. Only published values contribute.
        var penalties: [Int] = []

        // Sugars — thresholds shared with SaveatScore.
        if let sugars = n.sugars {
            let per100 = "\(Format.grams(sugars)) pour 100 g"
            switch sugars {
            case ..<5:
                penalties.append(0)
                positives.append(NutritionPoint(emoji: "🍬", title: "Peu de sucres", detail: per100))
            case 5..<12:
                penalties.append(1)
            case 12..<22:
                penalties.append(2)
                watchOuts.append(NutritionPoint(emoji: "🍬", title: "Sucres élevés", detail: per100))
            default:
                penalties.append(3)
                watchOuts.append(NutritionPoint(emoji: "🍬", title: "Sucres très élevés", detail: per100))
            }
        } else {
            missing.append("sucres")
        }

        // Salt.
        if let salt = n.salt {
            let per100 = "\(Format.grams(salt)) pour 100 g"
            switch salt {
            case ..<0.3:
                penalties.append(0)
                positives.append(NutritionPoint(emoji: "🧂", title: "Peu de sel", detail: per100))
            case 0.3..<1:
                penalties.append(1)
            case 1..<1.5:
                penalties.append(2)
                watchOuts.append(NutritionPoint(emoji: "🧂", title: "Sel élevé", detail: per100))
            default:
                penalties.append(3)
                watchOuts.append(NutritionPoint(emoji: "🧂", title: "Sel très élevé", detail: per100))
            }
        } else {
            missing.append("sel")
        }

        // Saturated fat.
        if let sat = n.saturatedFat {
            let per100 = "\(Format.grams(sat)) pour 100 g"
            switch sat {
            case ..<1.5:
                penalties.append(0)
                positives.append(NutritionPoint(emoji: "🧈", title: "Peu de graisses saturées", detail: per100))
            case 1.5..<5:
                penalties.append(1)
            case 5..<10:
                penalties.append(2)
                watchOuts.append(NutritionPoint(emoji: "🧈", title: "Graisses saturées élevées", detail: per100))
            default:
                penalties.append(3)
                watchOuts.append(NutritionPoint(emoji: "🧈", title: "Graisses saturées très élevées", detail: per100))
            }
        } else {
            missing.append("graisses saturées")
        }

        // Energy.
        if let kcal = n.energyKcal {
            let per100 = "\(Int(kcal.rounded())) kcal pour 100 g"
            switch kcal {
            case ..<100:
                penalties.append(0)
                positives.append(NutritionPoint(emoji: "🔥", title: "Peu calorique", detail: per100))
            case 100..<250:
                penalties.append(1)
            case 250..<400:
                penalties.append(2)
                watchOuts.append(NutritionPoint(emoji: "🔥", title: "Densité calorique élevée", detail: per100))
            default:
                penalties.append(3)
                watchOuts.append(NutritionPoint(emoji: "🔥", title: "Très calorique", detail: per100))
            }
        } else {
            missing.append("calories")
        }

        // Nutrients of interest — bonuses only, never used to soften a warning.
        if let fiber = n.fiber, fiber >= 3 {
            positives.append(NutritionPoint(
                emoji: "🌾",
                title: fiber >= 6 ? "Riche en fibres" : "Source de fibres",
                detail: "\(Format.grams(fiber)) pour 100 g"
            ))
        } else if n.fiber == nil {
            missing.append("fibres")
        }

        if let proteins = n.proteins, proteins >= 8 {
            positives.append(NutritionPoint(
                emoji: "💪",
                title: "Teneur intéressante en protéines",
                detail: "\(Format.grams(proteins)) pour 100 g"
            ))
        } else if n.proteins == nil {
            missing.append("protéines")
        }

        // Processing level (NOVA), when published.
        if let nova = product.nova {
            switch nova {
            case 1:
                positives.append(NutritionPoint(emoji: "🌱", title: "Aliment brut ou peu transformé", detail: "Groupe NOVA 1"))
            case 2:
                positives.append(NutritionPoint(emoji: "🌱", title: "Ingrédient culinaire peu transformé", detail: "Groupe NOVA 2"))
            case 4:
                watchOuts.append(NutritionPoint(emoji: "🏭", title: "Produit ultra-transformé", detail: "Groupe NOVA 4"))
            default:
                break
            }
        }

        let additives = AdditivesInfo(
            isKnown: product.additivesKnown ?? !product.additives.isEmpty,
            codes: product.additives.map { $0.uppercased() }
        )
        if additives.isKnown, additives.count >= 4 {
            watchOuts.append(NutritionPoint(
                emoji: "🧪",
                title: "Nombreux additifs",
                detail: "\(additives.count) additifs listés"
            ))
        }

        // Appreciation: official grade first, published nutrients otherwise.
        let verdict: NutritionVerdict?
        let basis: Basis
        if let grade {
            verdict = grade.verdict
            basis = .officialNutriScore(grade)
        } else if penalties.count >= 3 {
            verdict = estimatedVerdict(penalties: penalties, positives: positives)
            basis = .estimatedFromNutrients(usedFactors: penalties.count)
        } else {
            verdict = nil
            basis = .unavailable
        }

        return NutritionAnalysis(
            grade: grade,
            verdict: verdict,
            basis: basis,
            positives: positives,
            watchOuts: watchOuts,
            additives: additives,
            explanation: explanation(
                product: product,
                grade: grade,
                verdict: verdict,
                positives: positives,
                watchOuts: watchOuts,
                additives: additives,
                missing: missing
            ),
            missingFacts: missing
        )
    }

    /// Average penalty level of the published nutrients, softened by at most one
    /// step when the product also has real nutritional strengths.
    private nonisolated static func estimatedVerdict(penalties: [Int], positives: [NutritionPoint]) -> NutritionVerdict {
        let average = Double(penalties.reduce(0, +)) / Double(penalties.count)
        let bonus = min(positives.count, 2) == 2 ? 0.25 : 0
        switch average - bonus {
        case ..<0.4: return .veryGood
        case 0.4..<1.0: return .good
        case 1.0..<1.7: return .average
        case 1.7..<2.4: return .limit
        default: return .poor
        }
    }

    /// Short, honest paragraph: what the product is worth, and what is missing.
    private nonisolated static func explanation(
        product: ScannedProduct,
        grade: NutriScoreGrade?,
        verdict: NutritionVerdict?,
        positives: [NutritionPoint],
        watchOuts: [NutritionPoint],
        additives: AdditivesInfo,
        missing: [String]
    ) -> String {
        guard let verdict else {
            return "Ce produit ne publie pas assez de données nutritionnelles pour être analysé. SAVEAT préfère ne rien afficher plutôt que d'estimer une qualité qu'il ne peut pas vérifier."
        }

        var sentences: [String] = []

        if let grade {
            sentences.append("Nutri-Score \(grade.letter) officiel : \(verdict.title.lowercased()) sur le plan nutritionnel.")
        } else {
            sentences.append("Sans Nutri-Score publié, les valeurs disponibles situent ce produit à un niveau \(verdict.title.lowercased()).")
        }

        if !positives.isEmpty {
            let list = positives.prefix(2).map { $0.title.lowercased() }.joined(separator: " et ")
            sentences.append("Ce qui joue en sa faveur : \(list).")
        }

        if !watchOuts.isEmpty {
            let list = watchOuts.prefix(2).map { $0.title.lowercased() }.joined(separator: " et ")
            sentences.append("À surveiller : \(list).")
        } else if additives.isKnown, additives.codes.isEmpty {
            sentences.append("Rien de particulier à signaler dans les valeurs publiées.")
        }

        if !missing.isEmpty {
            sentences.append("Non publié pour ce produit : \(missing.joined(separator: ", ")).")
        }

        switch verdict {
        case .veryGood, .good:
            sentences.append("Une bonne base à garder au frais et à cuisiner avant sa date.")
        case .average:
            sentences.append("Correct au quotidien, surtout accompagné de produits frais de ton stock.")
        case .limit, .poor:
            sentences.append("À garder pour les petits plaisirs, en petite quantité — et à finir avant de le jeter.")
        }

        return sentences.joined(separator: " ")
    }
}
