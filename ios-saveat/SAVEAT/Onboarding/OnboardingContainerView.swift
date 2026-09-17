import SwiftUI

/// Product-pitch onboarding shown once, before the existing household setup
/// (`OnboardingView`): Welcome → Envies → Foyer → Chef → Différence →
/// Shopping list → Scan → Stock → Savings → Map → Account → Complete.
///
/// Repositioned around "your Chef takes care of your week" (Chef + weekly
/// planning + shopping list) rather than leading with scanning — see the
/// SAVEAT V2 onboarding master prompt. `RecipeOnboardingView` used to sit
/// between Stock and Savings; it's no longer wired in here since its pitch
/// ("Chef SAVEAT turns your stock into a menu") is now covered earlier by
/// `ChefOnboardingView`/`DifferenceOnboardingView`.
///
/// Purely presentational for now — it explains SAVEAT's value and collects no
/// data. The household setup that follows is untouched and still does the
/// real configuration work.
///
/// Every page is now a full-bleed photo (see `OnboardingPhotoBackground`),
/// so the progress dots live inside each page's own overlay
/// (`OnboardingProgressDots`) instead of a shared ivory bar above the
/// `TabView` — that bar would otherwise seam against a dark photo right
/// under it. Welcome and the closing screen don't show dots, matching the
/// validated mockups.
struct OnboardingContainerView: View {
    /// Called once, when the user finishes or skips the pitch.
    var onFinished: () -> Void

    @State private var step: Int = 0

    private let stepCount = 12

    var body: some View {
        TabView(selection: $step) {
            WelcomeOnboardingView(
                onStart: { advance() },
                onHaveAccount: { jump(to: 10) },
                onSkip: onFinished
            )
            .tag(0)

            EnviesOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(1)

            FoyerOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(2)

            ChefOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(3)

            DifferenceOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(4)

            ShoppingListOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(5)

            ScanOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(6)

            StockOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(7)

            SavingsOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(8)

            MapOnboardingView(onContinue: advance, onSkip: onFinished)
                .tag(9)

            AccountOnboardingView(onContinue: advance)
                .tag(10)

            OnboardingCompleteView(onFinish: onFinished)
                .tag(11)
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
