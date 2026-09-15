import Foundation

/// One piece of nutrition guidance SAVEAT shows after a scan (§29).
///
/// Purely informational — never a diagnosis, a treatment, or a promise about
/// health outcomes (§32). `NutritionAdvice.disclaimer` must be shown
/// wherever advice is displayed, so it never reads as medical guidance.
nonisolated struct NutritionAdvice: Sendable, Hashable {
    var title: String
    var summary: String
    var why: String
    var pairWith: String?
    var alternative: String?
    var frequencyAdvice: String?
    /// Higher wins when several conditions apply at once — see
    /// `NutritionAdviceEngine.advice(for:)`.
    var priority: Int

    static var disclaimer: String { S.Advice.disclaimer.s }
}

/// Turns a product's published nutrients into one prioritized, actionable
/// piece of advice.
///
/// A local, deterministic engine on purpose (§30): no network round-trip per
/// scan, the same input always gives the same advice, and it keeps working
/// offline. Thresholds mirror `SaveatScore` and `NutritionAnalysis` (12 g
/// sugars, 1 g salt, 3 g fiber, 8 g protein) so the three readings never
/// contradict each other. A missing nutrient never triggers advice about
/// it — silence, not a guess (§27).
nonisolated enum NutritionAdviceEngine {
    nonisolated static func advice(for product: ScannedProduct) -> NutritionAdvice? {
        let n = product.nutriments
        var candidates: [NutritionAdvice] = []

        if product.nova == 4 {
            candidates.append(NutritionAdvice(
                title: S.Advice.processedTitle.s,
                summary: S.Advice.processedSummary.s,
                why: S.Advice.processedWhy.s,
                pairWith: nil,
                alternative: S.Advice.processedAlternative.s,
                frequencyAdvice: S.Advice.occasional.s,
                priority: 5
            ))
        }

        if let salt = n.salt, salt >= 1 {
            candidates.append(NutritionAdvice(
                title: S.Advice.saltTitle.s,
                summary: S.Advice.saltSummary.s,
                why: S.Advice.saltWhy.s,
                pairWith: S.Advice.saltPairWith.s,
                alternative: nil,
                frequencyAdvice: nil,
                priority: 4
            ))
        }

        if let sugars = n.sugars, sugars >= 12 {
            candidates.append(NutritionAdvice(
                title: S.Advice.sugarTitle.s,
                summary: S.Advice.sugarSummary.s,
                why: S.Advice.sugarWhy.s,
                pairWith: S.Advice.sugarPairWith.s,
                alternative: nil,
                frequencyAdvice: nil,
                priority: 3
            ))
        }

        if let fiber = n.fiber, fiber < 3 {
            candidates.append(NutritionAdvice(
                title: S.Advice.fiberTitle.s,
                summary: S.Advice.fiberSummary.s,
                why: S.Advice.fiberWhy.s,
                pairWith: S.Advice.fiberPairWith.s,
                alternative: nil,
                frequencyAdvice: nil,
                priority: 2
            ))
        }

        if let proteins = n.proteins, proteins >= 8 {
            candidates.append(NutritionAdvice(
                title: S.Advice.proteinTitle.s,
                summary: S.Advice.proteinSummary.s,
                why: S.Advice.proteinWhy.s,
                pairWith: S.Advice.proteinPairWith.s,
                alternative: nil,
                frequencyAdvice: nil,
                priority: 1
            ))
        }

        if let winner = candidates.max(by: { $0.priority < $1.priority }) {
            return winner
        }
        return balancedAdvice(for: product)
    }

    /// Shown only when the product actually publishes enough data to say
    /// something — silence stays the honest answer for an empty sheet.
    private nonisolated static func balancedAdvice(for product: ScannedProduct) -> NutritionAdvice? {
        guard !product.nutriments.isEmpty else { return nil }
        return NutritionAdvice(
            title: S.Advice.balancedTitle.s,
            summary: S.Advice.balancedSummary.s,
            why: S.Advice.balancedWhy.s,
            pairWith: nil,
            alternative: nil,
            frequencyAdvice: nil,
            priority: 0
        )
    }
}
