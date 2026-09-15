import SwiftUI

/// First screen of the product-pitch onboarding: what SAVEAT does, in one look.
///
/// Reuses the bundled `open_refrigerator_interior` photo as the hero
/// background rather than a new placeholder asset — a real kitchen photo
/// already ships with the app.
struct WelcomeOnboardingView: View {
    var onStart: () -> Void
    var onHaveAccount: () -> Void
    var onSkip: () -> Void

    private let features: [IntroFeature] = [
        IntroFeature(S.Intro.welcomeIconScan.s, icon: "barcode.viewfinder"),
        IntroFeature(S.Intro.welcomeIconCook.s, icon: "fork.knife"),
        IntroFeature(S.Intro.welcomeIconSave.s, icon: "eurosign.circle.fill")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            background

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

    private var background: some View {
        GeometryReader { geo in
            Image("open_refrigerator_interior")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [
                            SaveatColors.nightBlue.opacity(0.55),
                            SaveatColors.nightBlue.opacity(0.72),
                            SaveatColors.nightBlue.opacity(0.94)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .ignoresSafeArea()
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
