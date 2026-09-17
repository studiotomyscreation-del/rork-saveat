import SwiftUI

/// Second screen of the product-pitch onboarding: what SAVEAT does, in one look.
///
/// Prefers a dedicated `onboarding_welcome` photo once one is added; until
/// then falls back to a bundled premium food photo rather than a new
/// placeholder asset (see `OnboardingPhotoBackground`).
struct WelcomeOnboardingView: View {
    var onStart: () -> Void
    var onHaveAccount: () -> Void
    var onSkip: () -> Void

    private static let photoAssetNames = ["onboarding_welcome", "chicken_rice_bowl_topdown"]

    private let features: [IntroFeature] = [
        IntroFeature(S.Intro.welcomeIconChef.s, icon: "fork.knife"),
        IntroFeature(S.Intro.welcomeIconWeek.s, icon: "calendar"),
        IntroFeature(S.Intro.welcomeIconGroceries.s, icon: "cart.fill")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            OnboardingPhotoBackground(assetNames: Self.photoAssetNames)

            VStack {
                HStack {
                    Spacer()
                    SaveatTextButton(title: S.Common.skip.s, action: onSkip)
                        .padding(.trailing, Theme.hMargin)
                        .padding(.top, 8)
                }
                Spacer()
            }

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 210)

                    VStack(spacing: 10) {
                        BrandMark(size: 56)
                        Text("SAVEAT")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .tracking(4)
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 8) {
                        Text(S.Intro.welcomeEyebrow.s)
                            .font(SaveatTypography.eyebrow(13))
                            .tracking(1.4)
                            .foregroundStyle(SaveatColors.brandLight)
                        Text(S.Intro.welcomeTitle.s)
                            .font(SaveatTypography.hero(30))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        Text(S.Intro.welcomeSubtitle.s)
                            .font(SaveatTypography.body(15))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 12)
                    }
                    .padding(.horizontal, Theme.hMargin)

                    featureRow
                        .padding(.horizontal, Theme.hMargin)

                    VStack(spacing: 12) {
                        SaveatPrimaryButton(title: S.Intro.startNow.s, action: onStart)
                        SaveatSecondaryButton(title: S.Intro.alreadyHaveAccount.s, action: onHaveAccount)
                    }
                    .padding(.horizontal, Theme.hMargin)
                    .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var featureRow: some View {
        HStack(spacing: 0) {
            ForEach(features) { feature in
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(.white.opacity(0.14)).frame(width: 52, height: 52)
                        Image(systemName: feature.icon)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(SaveatColors.brandLight)
                    }
                    Text(feature.title)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    WelcomeOnboardingView(onStart: {}, onHaveAccount: {}, onSkip: {})
}
