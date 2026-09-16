import SwiftUI

/// Product-pitch onboarding shown once, before the existing household setup
/// (`OnboardingView`): Welcome → Scan → Stock → Recipes → Savings → Map →
/// Account → Complete.
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

    private let stepCount = 8

    var body: some View {
        TabView(selection: $step) {
            WelcomeOnboardingView(
                onStart: { advance() },
                onHaveAccount: { jump(to: 6) },
                onSkip: onFinished
            )
            .tag(0)

            ScanOnboardingView(onContinue: advance)
                .tag(1)

            StockOnboardingView(onContinue: advance)
                .tag(2)

            RecipeOnboardingView(onContinue: advance)
                .tag(3)

            SavingsOnboardingView(onContinue: advance)
                .tag(4)

            MapOnboardingView(onContinue: advance)
                .tag(5)

            AccountOnboardingView(onContinue: advance)
                .tag(6)

            OnboardingCompleteView(onFinish: onFinished)
                .tag(7)
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
