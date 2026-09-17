import SwiftUI

/// Fifth screen of the product-pitch onboarding: SAVEAT's actual
/// differentiator — the Chef starts from real stock, not a blank page.
///
/// The three figures shown are fixed example numbers (`differenceDemoNotice`
/// makes that explicit), never a claim about this household's real stock —
/// there is no real stock yet at this point in onboarding. Once the real
/// planner exists (later phases), these must be computed from `AppStore`,
/// never hardcoded.
struct DifferenceOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

    var body: some View {
        IntroStepShell(
            photoAssetNames: [],
            stepIndex: 4,
            stepCount: 11,
            icon: "shippingbox.fill",
            title: S.Intro.differenceTitle.s,
            body_: S.Intro.differenceBody.s,
            ctaTitle: S.Intro.differenceCTA.s,
            onContinue: onContinue,
            onSkip: onSkip
        ) {
            VStack(spacing: 10) {
                VStack(spacing: 12) {
                    statLine(icon: "checkmark.circle.fill", text: S.Intro.differenceExampleAvailable.f(14))
                    statLine(icon: "exclamationmark.triangle.fill", text: S.Intro.differenceExamplePriority.f(3))
                    statLine(icon: "chart.pie.fill", text: S.Intro.differenceExamplePercent.f(68))
                }
                .saveatTranslucentCard()

                Text(S.Intro.differenceDemoNotice.s)
                    .font(SaveatTypography.caption(11.5))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, Theme.hMargin)
        }
    }

    private func statLine(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SaveatColors.brand)
                .frame(width: 20)
            Text(text)
                .font(SaveatTypography.body(14.5))
                .foregroundStyle(SaveatColors.textPrimary)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    DifferenceOnboardingView(onContinue: {}, onSkip: {})
}
