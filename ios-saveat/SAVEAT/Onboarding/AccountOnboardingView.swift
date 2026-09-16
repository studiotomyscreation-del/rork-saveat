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
        ZStack {
            // No specific photo fits an account/sign-in step — the brand
            // gradient alone (same base every page shares) stays premium
            // without forcing an unrelated food shot behind a login screen.
            OnboardingPhotoBackground(assetNames: [])

            VStack(spacing: 0) {
                OnboardingProgressDots(stepIndex: 6, stepCount: 7)
                    .padding(.top, 8)

                Spacer(minLength: 20)

                ZStack {
                    Circle().fill(.white.opacity(0.16)).frame(width: 108, height: 108)
                    BrandMark(size: 56)
                }
                .padding(.bottom, 22)

                Text(S.Intro.accountTitle.s)
                    .font(SaveatTypography.hero(25))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
                    .padding(.horizontal, Theme.hMargin)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(benefits) { benefit in
                        IntroPointRow(icon: benefit.icon, text: benefit.title)
                    }
                }
                .saveatTranslucentCard()
                .padding(.horizontal, Theme.hMargin)
                .padding(.top, 20)

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
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.top, 2)
                }
                .padding(.horizontal, Theme.hMargin)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AccountOnboardingView(onContinue: {})
}
