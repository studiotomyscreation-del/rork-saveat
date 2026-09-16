import SwiftUI

/// Fourth screen of the product-pitch onboarding: Chef SAVEAT, the cooking
/// assistant that turns whatever is in stock into a real menu.
///
/// No fabricated recipe names or ingredient-coverage numbers here — those
/// are only ever shown once they come from a real stock and a real
/// `MealAIService` call, neither of which exists yet at this point in
/// onboarding. The tagline bubble is pure pitch copy, not a data claim.
struct RecipeOnboardingView: View {
    var onContinue: () -> Void

    /// A finished, plated dish reads as "premium cuisine" better than a raw
    /// ingredient shot — used until a dedicated `onboarding_recipes` photo
    /// (Chef SAVEAT turning stock into a meal) exists.
    private static let photoAssetNames = ["onboarding_recipes", "fried_rice_cast_iron_pan"]

    var body: some View {
        IntroStepShell(
            photoAssetNames: Self.photoAssetNames,
            stepIndex: 3,
            stepCount: 7,
            icon: "fork.knife",
            title: S.Intro.recipesTitle.s,
            body_: S.Intro.recipesBody.s,
            ctaTitle: S.Common.next.s,
            onContinue: onContinue
        ) {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(SaveatColors.brand)
                Text(S.Intro.recipesTagline.s)
                    .font(SaveatTypography.headline(14.5))
                    .foregroundStyle(SaveatColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .saveatTranslucentCard(padding: 0, radius: 18)
            .padding(.horizontal, Theme.hMargin)
        }
    }
}

#Preview {
    RecipeOnboardingView(onContinue: {})
}
