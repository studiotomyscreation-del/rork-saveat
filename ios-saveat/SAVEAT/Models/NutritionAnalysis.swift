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
        case .veryGood: S.Nutrition.veryGood.s
        case .good: S.Nutrition.good.s
        case .average: S.Nutrition.average.s
        case .limit: S.Nutrition.limit.s
        case .poor: S.Nutrition.poor.s
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

    /// Summary line in the reader's language, or the explicit unavailable notice.
    nonisolated var summary: String {
        guard isKnown else { return NutritionAnalysis.unavailableText }
        if codes.isEmpty { return S.Nutrition.noAdditivesListed.s }
        return codes.count > 1
            ? S.Nutrition.additivesListed.f(codes.count)
            : S.Nutrition.additiveListed.f(codes.count)
    }

    /// `E330 — citric acid (acidity regulator)` when the code is known, else the raw code.
    nonisolated func describe(_ code: String) -> String {
        let normalised = code.uppercased()
        guard let name = AdditivesInfo.names[normalised] else { return normalised }
        return "\(normalised) — \(name.s)"
    }

    /// Standard names of the additives most often met on French and US shelves.
    /// Only documented entries are listed; unknown codes are shown as-is.
    private static let names: [String: Loc] = [
        "E100": Loc(fr: "curcumine (colorant)", en: "curcumin (color)"),
        "E120": Loc(fr: "cochenille (colorant)", en: "cochineal / carmine (color)"),
        "E150A": Loc(fr: "caramel ordinaire (colorant)", en: "plain caramel (color)"),
        "E150C": Loc(fr: "caramel ammoniacal (colorant)", en: "ammonia caramel (color)"),
        "E150D": Loc(fr: "caramel au sulfite d'ammonium (colorant)", en: "sulfite ammonia caramel (color)"),
        "E160A": Loc(fr: "carotènes (colorant)", en: "carotenes (color)"),
        "E160C": Loc(fr: "extrait de paprika (colorant)", en: "paprika extract (color)"),
        "E162": Loc(fr: "rouge de betterave (colorant)", en: "beet red (color)"),
        "E163": Loc(fr: "anthocyanes (colorant)", en: "anthocyanins (color)"),
        "E170": Loc(fr: "carbonate de calcium", en: "calcium carbonate"),
        "E200": Loc(fr: "acide sorbique (conservateur)", en: "sorbic acid (preservative)"),
        "E202": Loc(fr: "sorbate de potassium (conservateur)", en: "potassium sorbate (preservative)"),
        "E211": Loc(fr: "benzoate de sodium (conservateur)", en: "sodium benzoate (preservative)"),
        "E223": Loc(fr: "métabisulfite de sodium (conservateur)", en: "sodium metabisulfite (preservative)"),
        "E250": Loc(fr: "nitrite de sodium (conservateur)", en: "sodium nitrite (preservative)"),
        "E252": Loc(fr: "nitrate de potassium (conservateur)", en: "potassium nitrate (preservative)"),
        "E260": Loc(fr: "acide acétique (acidifiant)", en: "acetic acid (acidifier)"),
        "E270": Loc(fr: "acide lactique (acidifiant)", en: "lactic acid (acidifier)"),
        "E296": Loc(fr: "acide malique (acidifiant)", en: "malic acid (acidifier)"),
        "E300": Loc(fr: "acide ascorbique — vitamine C (antioxydant)", en: "ascorbic acid — vitamin C (antioxidant)"),
        "E301": Loc(fr: "ascorbate de sodium (antioxydant)", en: "sodium ascorbate (antioxidant)"),
        "E306": Loc(fr: "extrait riche en tocophérols (antioxydant)", en: "tocopherol-rich extract (antioxidant)"),
        "E316": Loc(fr: "érythorbate de sodium (antioxydant)", en: "sodium erythorbate (antioxidant)"),
        "E322": Loc(fr: "lécithines (émulsifiant)", en: "lecithins (emulsifier)"),
        "E330": Loc(fr: "acide citrique (correcteur d'acidité)", en: "citric acid (acidity regulator)"),
        "E331": Loc(fr: "citrates de sodium (correcteur d'acidité)", en: "sodium citrates (acidity regulator)"),
        "E333": Loc(fr: "citrates de calcium (correcteur d'acidité)", en: "calcium citrates (acidity regulator)"),
        "E338": Loc(fr: "acide phosphorique (acidifiant)", en: "phosphoric acid (acidifier)"),
        "E339": Loc(fr: "phosphates de sodium", en: "sodium phosphates"),
        "E340": Loc(fr: "phosphates de potassium", en: "potassium phosphates"),
        "E401": Loc(fr: "alginate de sodium (épaississant)", en: "sodium alginate (thickener)"),
        "E405": Loc(fr: "alginate de propane-1,2-diol (épaississant)", en: "propylene glycol alginate (thickener)"),
        "E406": Loc(fr: "agar-agar (gélifiant)", en: "agar (gelling agent)"),
        "E407": Loc(fr: "carraghénanes (épaississant)", en: "carrageenan (thickener)"),
        "E410": Loc(fr: "farine de graines de caroube (épaississant)", en: "locust bean gum (thickener)"),
        "E412": Loc(fr: "gomme guar (épaississant)", en: "guar gum (thickener)"),
        "E414": Loc(fr: "gomme arabique (épaississant)", en: "gum arabic (thickener)"),
        "E415": Loc(fr: "gomme xanthane (épaississant)", en: "xanthan gum (thickener)"),
        "E418": Loc(fr: "gomme gellane (épaississant)", en: "gellan gum (thickener)"),
        "E420": Loc(fr: "sorbitol (édulcorant)", en: "sorbitol (sweetener)"),
        "E422": Loc(fr: "glycérol (humectant)", en: "glycerol (humectant)"),
        "E440": Loc(fr: "pectines (gélifiant)", en: "pectins (gelling agent)"),
        "E450": Loc(fr: "diphosphates (stabilisant)", en: "diphosphates (stabilizer)"),
        "E451": Loc(fr: "triphosphates (stabilisant)", en: "triphosphates (stabilizer)"),
        "E460": Loc(fr: "cellulose (anti-agglomérant)", en: "cellulose (anti-caking agent)"),
        "E464": Loc(fr: "hydroxypropylméthylcellulose (épaississant)", en: "hydroxypropyl methylcellulose (thickener)"),
        "E466": Loc(fr: "carboxyméthylcellulose (épaississant)", en: "carboxymethyl cellulose (thickener)"),
        "E471": Loc(fr: "mono- et diglycérides d'acides gras (émulsifiant)", en: "mono- and diglycerides of fatty acids (emulsifier)"),
        "E472E": Loc(fr: "esters d'acides gras (émulsifiant)", en: "fatty acid esters (emulsifier)"),
        "E476": Loc(fr: "polyricinoléate de polyglycérol (émulsifiant)", en: "polyglycerol polyricinoleate (emulsifier)"),
        "E481": Loc(fr: "stéaroyl-2-lactylate de sodium (émulsifiant)", en: "sodium stearoyl lactylate (emulsifier)"),
        "E500": Loc(fr: "carbonates de sodium (poudre à lever)", en: "sodium carbonates (leavening agent)"),
        "E501": Loc(fr: "carbonates de potassium (poudre à lever)", en: "potassium carbonates (leavening agent)"),
        "E503": Loc(fr: "carbonates d'ammonium (poudre à lever)", en: "ammonium carbonates (leavening agent)"),
        "E504": Loc(fr: "carbonates de magnésium (anti-agglomérant)", en: "magnesium carbonates (anti-caking agent)"),
        "E509": Loc(fr: "chlorure de calcium (affermissant)", en: "calcium chloride (firming agent)"),
        "E551": Loc(fr: "dioxyde de silicium (anti-agglomérant)", en: "silicon dioxide (anti-caking agent)"),
        "E621": Loc(fr: "glutamate monosodique (exhausteur de goût)", en: "monosodium glutamate — MSG (flavor enhancer)"),
        "E627": Loc(fr: "guanylate disodique (exhausteur de goût)", en: "disodium guanylate (flavor enhancer)"),
        "E631": Loc(fr: "inosinate disodique (exhausteur de goût)", en: "disodium inosinate (flavor enhancer)"),
        "E635": Loc(fr: "ribonucléotides disodiques (exhausteur de goût)", en: "disodium ribonucleotides (flavor enhancer)"),
        "E950": Loc(fr: "acésulfame K (édulcorant)", en: "acesulfame potassium (sweetener)"),
        "E951": Loc(fr: "aspartame (édulcorant)", en: "aspartame (sweetener)"),
        "E952": Loc(fr: "cyclamates (édulcorant)", en: "cyclamates (sweetener)"),
        "E954": Loc(fr: "saccharines (édulcorant)", en: "saccharin (sweetener)"),
        "E955": Loc(fr: "sucralose (édulcorant)", en: "sucralose (sweetener)"),
        "E960": Loc(fr: "glycosides de stéviol (édulcorant)", en: "steviol glycosides (sweetener)"),
        "E965": Loc(fr: "maltitol (édulcorant)", en: "maltitol (sweetener)"),
        "E967": Loc(fr: "xylitol (édulcorant)", en: "xylitol (sweetener)"),
        "E968": Loc(fr: "érythritol (édulcorant)", en: "erythritol (sweetener)")
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
                S.Nutrition.basisOfficial.f(grade.letter)
            case .estimatedFromNutrients(let count):
                count > 1
                    ? S.Nutrition.basisEstimated.f(count)
                    : S.Nutrition.basisEstimatedSingular.f(count)
            case .unavailable:
                S.Nutrition.basisUnavailable.s
            }
        }
    }

    static var unavailableText: String { S.Nutrition.unavailable.s }

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
            let per100 = S.Nutrition.per100g.f(Format.grams(sugars))
            switch sugars {
            case ..<5:
                penalties.append(0)
                positives.append(NutritionPoint(emoji: "🍬", title: S.Nutrition.lowSugar.s, detail: per100))
            case 5..<12:
                penalties.append(1)
            case 12..<22:
                penalties.append(2)
                watchOuts.append(NutritionPoint(emoji: "🍬", title: S.Nutrition.highSugar.s, detail: per100))
            default:
                penalties.append(3)
                watchOuts.append(NutritionPoint(emoji: "🍬", title: S.Nutrition.veryHighSugar.s, detail: per100))
            }
        } else {
            missing.append(S.Nutrition.missingSugars.s)
        }

        // Salt.
        if let salt = n.salt {
            let per100 = S.Nutrition.per100g.f(Format.grams(salt))
            switch salt {
            case ..<0.3:
                penalties.append(0)
                positives.append(NutritionPoint(emoji: "🧂", title: S.Nutrition.lowSalt.s, detail: per100))
            case 0.3..<1:
                penalties.append(1)
            case 1..<1.5:
                penalties.append(2)
                watchOuts.append(NutritionPoint(emoji: "🧂", title: S.Nutrition.highSalt.s, detail: per100))
            default:
                penalties.append(3)
                watchOuts.append(NutritionPoint(emoji: "🧂", title: S.Nutrition.veryHighSalt.s, detail: per100))
            }
        } else {
            missing.append(S.Nutrition.missingSalt.s)
        }

        // Saturated fat.
        if let sat = n.saturatedFat {
            let per100 = S.Nutrition.per100g.f(Format.grams(sat))
            switch sat {
            case ..<1.5:
                penalties.append(0)
                positives.append(NutritionPoint(emoji: "🧈", title: S.Nutrition.lowSaturated.s, detail: per100))
            case 1.5..<5:
                penalties.append(1)
            case 5..<10:
                penalties.append(2)
                watchOuts.append(NutritionPoint(emoji: "🧈", title: S.Nutrition.highSaturated.s, detail: per100))
            default:
                penalties.append(3)
                watchOuts.append(NutritionPoint(emoji: "🧈", title: S.Nutrition.veryHighSaturated.s, detail: per100))
            }
        } else {
            missing.append(S.Nutrition.missingSaturated.s)
        }

        // Energy.
        if let kcal = n.energyKcal {
            let per100 = S.Nutrition.kcalPer100g.f(Int(kcal.rounded()))
            switch kcal {
            case ..<100:
                penalties.append(0)
                positives.append(NutritionPoint(emoji: "🔥", title: S.Nutrition.lowCalorie.s, detail: per100))
            case 100..<250:
                penalties.append(1)
            case 250..<400:
                penalties.append(2)
                watchOuts.append(NutritionPoint(emoji: "🔥", title: S.Nutrition.calorieDense.s, detail: per100))
            default:
                penalties.append(3)
                watchOuts.append(NutritionPoint(emoji: "🔥", title: S.Nutrition.veryCalorie.s, detail: per100))
            }
        } else {
            missing.append(S.Nutrition.missingCalories.s)
        }

        // Nutrients of interest — bonuses only, never used to soften a warning.
        if let fiber = n.fiber, fiber >= 3 {
            positives.append(NutritionPoint(
                emoji: "🌾",
                title: fiber >= 6 ? S.Nutrition.richFiber.s : S.Nutrition.sourceFiber.s,
                detail: S.Nutrition.per100g.f(Format.grams(fiber))
            ))
        } else if n.fiber == nil {
            missing.append(S.Nutrition.missingFiber.s)
        }

        if let proteins = n.proteins, proteins >= 8 {
            positives.append(NutritionPoint(
                emoji: "💪",
                title: S.Nutrition.goodProtein.s,
                detail: S.Nutrition.per100g.f(Format.grams(proteins))
            ))
        } else if n.proteins == nil {
            missing.append(S.Nutrition.missingProteins.s)
        }

        // Processing level (NOVA), when published.
        if let nova = product.nova {
            switch nova {
            case 1:
                positives.append(NutritionPoint(emoji: "🌱", title: S.Nutrition.novaWhole.s, detail: S.Nutrition.novaGroup.f(1)))
            case 2:
                positives.append(NutritionPoint(emoji: "🌱", title: S.Nutrition.novaCulinary.s, detail: S.Nutrition.novaGroup.f(2)))
            case 4:
                watchOuts.append(NutritionPoint(emoji: "🏭", title: S.Nutrition.novaUltra.s, detail: S.Nutrition.novaGroup.f(4)))
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
                title: S.Nutrition.manyAdditives.s,
                detail: S.Nutrition.additivesCount.f(additives.count)
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
            return S.Nutrition.notEnoughData.s
        }

        var sentences: [String] = []

        if let grade {
            sentences.append(S.Nutrition.officialSentence.f(grade.letter, verdict.title.lowercased()))
        } else {
            sentences.append(S.Nutrition.estimatedSentence.f(verdict.title.lowercased()))
        }

        let joiner = S.Nutrition.andJoiner.s

        if !positives.isEmpty {
            let list = positives.prefix(2).map { $0.title.lowercased() }.joined(separator: joiner)
            sentences.append(S.Nutrition.inItsFavor.f(list))
        }

        if !watchOuts.isEmpty {
            let list = watchOuts.prefix(2).map { $0.title.lowercased() }.joined(separator: joiner)
            sentences.append(S.Nutrition.watchOut.f(list))
        } else if additives.isKnown, additives.codes.isEmpty {
            sentences.append(S.Nutrition.nothingNotable.s)
        }

        if !missing.isEmpty {
            sentences.append(S.Nutrition.notPublished.f(missing.joined(separator: ", ")))
        }

        switch verdict {
        case .veryGood, .good:
            sentences.append(S.Nutrition.closingGood.s)
        case .average:
            sentences.append(S.Nutrition.closingAverage.s)
        case .limit, .poor:
            sentences.append(S.Nutrition.closingLimit.s)
        }

        return sentences.joined(separator: " ")
    }
}
