import SwiftUI

/// Not currently wired into `OnboardingContainerView` — its pitch ("Chef
/// SAVEAT turns your stock into a menu") is now covered earlier by
/// `ChefOnboardingView`/`DifferenceOnboardingView`, and keeping both back to
/// back read as repetitive. Left in place in case a future flow variant
/// wants it back.
///
/// No fabricated recipe names or ingredient-coverage numbers here — those
/// are only ever shown once they come from a real stock and a real
/// `MealAIService` call, neither of which exists yet at this point in
/// onboarding. The tagline bubble is pure pitch copy, not a data claim.
struct RecipeOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

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
            onContinue: onContinue,
            onSkip: onSkip
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
    RecipeOnboardingView(onContinue: {}, onSkip: {})
}
