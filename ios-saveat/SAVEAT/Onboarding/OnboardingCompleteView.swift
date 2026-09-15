import SwiftUI

/// Eighth and final screen of the product-pitch onboarding: closes the pitch
/// before the app hands off to the existing household setup (`OnboardingView`)
/// or straight to `RootView`.
struct OnboardingCompleteView: View {
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            BrandMark(size: 88)
                .padding(.bottom, 18)

            Text("SAVEAT")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .tracking(4)
                .foregroundStyle(SaveatColors.forestDeep)

            VStack(spacing: 12) {
                Text(S.Intro.completeTitle.s)
                    .font(SaveatTypography.hero(30))
                    .foregroundStyle(SaveatColors.forestDeep)
                Text(S.Intro.completeSubtitle.s)
                    .font(SaveatTypography.body(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SaveatColors.textSecondary)
            }
            .padding(.top, 20)
            .padding(.horizontal, Theme.hMargin)

            Spacer(minLength: 24)

            heroImage

            VStack(spacing: 6) {
                Text(S.Intro.completeThanks.s)
                    .font(SaveatTypography.headline(15))
                    .foregroundStyle(SaveatColors.forestDeep)
            }
            .padding(.top, 18)

            Spacer(minLength: 24)

            SaveatPrimaryButton(title: S.Intro.completeCTA.s, action: onFinish)
                .padding(.horizontal, Theme.hMargin)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SaveatColors.background.ignoresSafeArea())
    }

    private var heroImage: some View {
        Image("vegetable_soup_bread")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .clipShape(.rect(cornerRadius: 24))
            .padding(.horizontal, Theme.hMargin)
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(SaveatColors.forestDeep.opacity(0.08), lineWidth: 1)
                    .padding(.horizontal, Theme.hMargin)
            }
    }
}

#Preview {
    OnboardingCompleteView(onFinish: {})
}
