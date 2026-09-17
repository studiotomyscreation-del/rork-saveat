import SwiftUI

/// Thirteenth and final screen of the product-pitch onboarding: closes the pitch
/// before the app hands off to the existing household setup (`OnboardingView`)
/// or straight to `RootView`.
struct OnboardingCompleteView: View {
    var onFinish: () -> Void

    /// Prefers a dedicated `onboarding_final` photo once one is added; the
    /// bundled soup photo is a deliberate fallback, not a random pick — it's
    /// the same warm, "home" mood this screen is meant to hand off into.
    private static let photoAssetNames = ["onboarding_final", "vegetable_soup_bread"]

    var body: some View {
        ZStack {
            OnboardingPhotoBackground(assetNames: Self.photoAssetNames)

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                BrandMark(size: 88)
                    .padding(.bottom, 18)

                Text("SAVEAT")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white)

                VStack(spacing: 12) {
                    Text(S.Intro.completeTitle.s)
                        .font(SaveatTypography.hero(30))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
                    Text(S.Intro.completeSubtitle.s)
                        .font(SaveatTypography.body(15))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.88))
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 1)
                }
                .padding(.top, 20)
                .padding(.horizontal, Theme.hMargin)

                Spacer(minLength: 24)

                Text(S.Intro.completeThanks.s)
                    .font(SaveatTypography.headline(15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.16), in: .capsule)

                Spacer(minLength: 24)

                SaveatPrimaryButton(title: S.Intro.completeCTA.s, action: onFinish)
                    .padding(.horizontal, Theme.hMargin)
                    .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingCompleteView(onFinish: {})
}
