import SwiftUI

/// Tenth screen of the product-pitch onboarding: what the savings dashboard
/// will look like — clearly labelled as example data, since a brand-new
/// account starts genuinely at zero (see `AppStore.hasNoHistory`).
struct SavingsOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

    /// Ties "what you save" back to real food rather than an abstract chart —
    /// used until a dedicated `onboarding_savings` photo exists.
    private static let photoAssetNames = ["onboarding_savings", "zucchini_cheese_gratin"]

    var body: some View {
        IntroStepShell(
            photoAssetNames: Self.photoAssetNames,
            stepIndex: 9,
            stepCount: 12,
            icon: "chart.line.uptrend.xyaxis",
            title: S.Intro.savingsTitle.s,
            body_: S.Intro.savingsBody.s,
            ctaTitle: S.Common.next.s,
            onContinue: onContinue,
            onSkip: onSkip
        ) {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(S.Intro.savingsMonthLabel.s)
                                .font(SaveatTypography.caption(12.5))
                                .foregroundStyle(SaveatColors.textSecondary)
                            Text(Format.euro(64.80, decimals: 2))
                                .font(SaveatTypography.numeric(30))
                                .foregroundStyle(SaveatColors.forestDeep)
                        }
                        Spacer(minLength: 0)
                        SaveatBadge(text: "+12%", tone: .brand, icon: "arrow.up.right")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        savingsLine(icon: "leaf.fill", text: "12 \(S.Home.savedItemsLabel.s)")
                        savingsLine(icon: "fork.knife", text: "8 \(S.Intro.savingsMealsFromStock.s)")
                        savingsLine(icon: "tag.fill", text: "4 \(S.Intro.savingsDealsUsed.s)")
                    }
                }
                .saveatTranslucentCard()
                .padding(.horizontal, Theme.hMargin)

                Text(S.Intro.savingsDemoNotice.s)
                    .font(SaveatTypography.caption(11.5))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private func savingsLine(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SaveatColors.brand)
                .frame(width: 18)
            Text(text)
                .font(SaveatTypography.caption(14))
                .foregroundStyle(SaveatColors.textPrimary)
        }
    }
}

#Preview {
    SavingsOnboardingView(onContinue: {}, onSkip: {})
}
