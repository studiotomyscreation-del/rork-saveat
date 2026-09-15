import SwiftUI

/// Product-pitch onboarding shown once, before the existing household setup
/// (`OnboardingView`): Welcome → Scan → Stock → Recipes → Savings → Map →
/// Account → Complete.
///
/// Purely presentational for now — it explains SAVEAT's value and collects no
/// data. The household setup that follows is untouched and still does the
/// real configuration work.
struct OnboardingContainerView: View {
    /// Called once, when the user finishes or skips the pitch.
    var onFinished: () -> Void

    @State private var step: Int = 0

    /// The seven pitch screens carry the progress dots; the closing screen
    /// (index 7) does not, matching the validated mockups.
    private let pageCount = 7
    private let stepCount = 8

    var body: some View {
        VStack(spacing: 0) {
            // Hidden on the welcome screen (its own full-bleed photo has no
            // room for a top bar) and on the closing screen.
            if step > 0 && step < pageCount {
                progressDots
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }

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
        }
        .background(SaveatColors.background.ignoresSafeArea())
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

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? SaveatColors.brand : SaveatColors.forestDeep.opacity(0.12))
                    .frame(width: index == step ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
            }
        }
        .padding(.horizontal, Theme.hMargin)
    }
}

#Preview {
    OnboardingContainerView(onFinished: {})
}
