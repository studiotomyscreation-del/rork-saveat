import SwiftUI

/// Seventh screen of the product-pitch onboarding: the account pitch.
///
/// No `AuthService` exists yet in SAVEAT (confirmed during the Phase 1 audit),
/// and Sign in with Apple / Google both need capabilities, entitlements and a
/// backend decision that are out of scope here. Every action on this screen
/// therefore only moves on to the closing screen — nothing is authenticated,
/// no account is created, and no local data is touched.
/// `accountComingSoonNotice` says so openly rather than pretending sign-in works.
struct AccountOnboardingView: View {
    var onContinue: () -> Void

    private let benefits: [IntroFeature] = [
        IntroFeature(S.Intro.accountBenefitStock.s, icon: "shippingbox.fill"),
        IntroFeature(S.Intro.accountBenefitSavings.s, icon: "chart.line.uptrend.xyaxis"),
        IntroFeature(S.Intro.accountBenefitFavorites.s, icon: "heart.fill"),
        IntroFeature(S.Intro.accountBenefitSync.s, icon: "arrow.triangle.2.circlepath")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            ZStack {
                Circle().fill(SaveatColors.brandSoft).frame(width: 108, height: 108)
                BrandMark(size: 56)
            }
            .padding(.bottom, 24)

            Text(S.Intro.accountTitle.s)
                .font(SaveatTypography.hero(25))
                .multilineTextAlignment(.center)
                .foregroundStyle(SaveatColors.textPrimary)
                .padding(.horizontal, Theme.hMargin)

            SaveatCard {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(benefits) { benefit in
                        IntroPointRow(icon: benefit.icon, text: benefit.title)
                    }
                }
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 22)

            Spacer(minLength: 20)

            VStack(spacing: 12) {
                SaveatPrimaryButton(title: S.Intro.continueWithApple.s, action: onContinue)
                SaveatSecondaryButton(title: S.Intro.continueWithGoogle.s, action: onContinue)
                SaveatSecondaryButton(title: S.Intro.continueWithEmail.s, action: onContinue)

                SaveatTextButton(title: S.Intro.later.s, action: onContinue)
                    .padding(.top, 4)

                Text(S.Intro.accountComingSoonNotice.s)
                    .font(SaveatTypography.caption(11))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SaveatColors.textSecondary)
                    .padding(.top, 2)
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SaveatColors.background.ignoresSafeArea())
    }
}

#Preview {
    AccountOnboardingView(onContinue: {})
}
