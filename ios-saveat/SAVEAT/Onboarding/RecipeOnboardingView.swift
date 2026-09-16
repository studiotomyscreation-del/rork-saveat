import SwiftUI

/// Fourth screen of the product-pitch onboarding: the AI cooking assistant.
///
/// The three recipe cards are illustrative examples of what the assistant
/// can propose — not a live call to `MealAIService`, which needs a real stock
/// to reason about and none exists yet at this point in onboarding.
struct RecipeOnboardingView: View {
    var onContinue: () -> Void

    private struct PreviewRecipe {
        let emoji: String
        let name: String
        let minutes: Int
    }

    private let recipes: [PreviewRecipe] = [
        PreviewRecipe(emoji: "🍝", name: "Pâtes crémeuses aux courgettes", minutes: 15),
        PreviewRecipe(emoji: "🍳", name: "Omelette aux légumes", minutes: 10),
        PreviewRecipe(emoji: "🍲", name: "Soupe anti-gaspi", minutes: 20)
    ]

    /// A finished, plated dish reads as "premium cuisine" better than a raw
    /// ingredient shot — used until a dedicated `onboarding_recipes` photo
    /// (the AI turning stock into a meal) exists.
    private static let photoAssetNames = ["onboarding_recipes", "fried_rice_cast_iron_pan"]

    var body: some View {
        IntroStepShell(
            photoAssetNames: Self.photoAssetNames,
            stepIndex: 3,
            stepCount: 7,
            icon: "sparkles",
            title: S.Intro.recipesTitle.s,
            body_: S.Intro.recipesBody.s,
            ctaTitle: S.Common.next.s,
            onContinue: onContinue
        ) {
            VStack(spacing: 12) {
                SaveatBadge(text: S.Intro.recipesBadge.s, tone: .brand, icon: "sparkles")

                VStack(spacing: 8) {
                    ForEach(Array(recipes.enumerated()), id: \.offset) { _, recipe in
                        HStack(spacing: 12) {
                            Text(recipe.emoji).font(.system(size: 24))
                            Text(recipe.name)
                                .font(SaveatTypography.headline(14))
                                .foregroundStyle(SaveatColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Spacer(minLength: 6)
                            Text("\(recipe.minutes) min")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(SaveatColors.textSecondary)
                        }
                        .padding(12)
                        .saveatTranslucentCard(padding: 0, radius: 14)
                    }
                }

                Text(S.Intro.recipesCounter.f(8, 3))
                    .font(SaveatTypography.caption(12.5))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, Theme.hMargin)
        }
    }
}

#Preview {
    RecipeOnboardingView(onContinue: {})
}
