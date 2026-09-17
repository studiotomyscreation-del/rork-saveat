import SwiftUI

/// Product-pitch onboarding shown once, before the existing household setup
/// (`OnboardingView`): Account type → Welcome → Envies → Foyer → Chef →
/// Différence → Shopping list → Scan → Stock → Savings → Map → Account →
/// Complete.
///
/// Repositioned around "your Chef takes care of your week" (Chef + weekly
/// planning + shopping list) rather than leading with scanning — see the
/// SAVEAT V2 onboarding master prompt. `RecipeOnboardingView` used to sit
/// between Stock and Savings; it's no longer wired in here since its pitch
/// ("Chef SAVEAT turns your stock into a menu") is now covered earlier by
/// `ChefOnboardingView`/`DifferenceOnboardingView`.
///
/// The very first screen (`AccountTypeOnboardingView`) picks particulier vs
/// professionnel upfront, so SAVEAT PRO is no longer only discoverable deep
/// in Profile — choosing "Professionnel" skips straight to `ProSignUpContainerView`
/// and, once signed up, past the rest of this particulier-focused pitch.
///
/// Purely presentational for now — it explains SAVEAT's value and collects no
/// data. The household setup that follows is untouched and still does the
/// real configuration work.
///
/// Every page is now a full-bleed photo (see `OnboardingPhotoBackground`),
/// so the progress dots live inside each page's own overlay
/// (`OnboardingProgressDots`) instead of a shared ivory bar above the
/// `TabView` — that bar would otherwise seam against a dark photo right
/// under it. The account type screen, Welcome and the closing screen don't
/// show dots, matching the validated mockups.
struct OnboardingContainerView: View {
    /// Called once, when the user finishes or skips the pitch.
    var onFinished: () -> Void

    @State private var step: Int = 0

    private let stepCount = 13

    var body: some View {
        TabView(selection: $step) {
            AccountTypeOnboardingView(
                onSelectParticulier: { advance() },
                onFinished: onFinished
            )
            .tag(0)

            WelcomeOnboardingView(
                onStart: { advance() },
                onHaveAccount: { jump(to: 11) },
                onSkip: onFinished
            )
            .tag(1)

            EnviesOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(2)

            FoyerOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(3)

            ChefOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(4)

            DifferenceOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(5)

            ShoppingListOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(6)

            ScanOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(7)

            StockOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(8)

            SavingsOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(9)

            MapOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(10)

            AccountOnboardingView(onContinue: advance)
                .tag(11)

            OnboardingCompleteView(onFinish: onFinished)
                .tag(12)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: step)
        .background(SaveatColors.nightBlue.ignoresSafeArea())
    }

    private func advance() {
        Haptics.soft()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            step = min(step + 1, stepCount - 1)
        }
    }

    private func jump(to destination: Int) {
        Haptics.soft()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            step = min(destination, stepCount - 1)
        }
    }
}

#Preview {
    OnboardingContainerView(onFinished: {})
}
