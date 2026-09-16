import SwiftUI

/// Shared layout for the photographic pitch cards of the product onboarding
/// (Scan / Stock / Recipes / Savings): a full-bleed photo, SAVEAT's dark
/// scrim, then icon, title, body, optional extra content and a primary CTA —
/// all native SwiftUI on top, never text baked into the photo itself. Keeps
/// every screen visually identical without repeating the same layout code.
struct IntroStepShell<Extra: View>: View {
    /// Preferred photo asset name(s) for this page, most-preferred first —
    /// see `OnboardingPhotoBackground`.
    let photoAssetNames: [String]
    let stepIndex: Int
    let stepCount: Int
    let icon: String
    let title: String
    let body_: String
    let ctaTitle: String
    let onContinue: () -> Void
    var onSkip: (() -> Void)? = nil
    private let extra: () -> Extra

    init(
        photoAssetNames: [String],
        stepIndex: Int,
        stepCount: Int,
        icon: String,
        title: String,
        body_: String,
        ctaTitle: String,
        onContinue: @escaping () -> Void,
        onSkip: (() -> Void)? = nil,
        @ViewBuilder extra: @escaping () -> Extra
    ) {
        self.photoAssetNames = photoAssetNames
        self.stepIndex = stepIndex
        self.stepCount = stepCount
        self.icon = icon
        self.title = title
        self.body_ = body_
        self.ctaTitle = ctaTitle
        self.onContinue = onContinue
        self.onSkip = onSkip
        self.extra = extra
    }

    var body: some View {
        ZStack {
            OnboardingPhotoBackground(assetNames: photoAssetNames)

            VStack(spacing: 0) {
                ZStack {
                    OnboardingProgressDots(stepIndex: stepIndex, stepCount: stepCount)
                    if let onSkip {
                        HStack {
                            Spacer()
                            SaveatTextButton(title: S.Common.skip.s, action: onSkip)
                        }
                        .padding(.trailing, Theme.hMargin)
                    }
                }
                .padding(.top, 8)

                Spacer(minLength: 20)

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.16))
                        .frame(width: 92, height: 92)
                    Image(systemName: icon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 22)

                VStack(spacing: 10) {
                    Text(title)
                        .font(SaveatTypography.hero(25))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
                    Text(body_)
                        .font(SaveatTypography.body(15))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.88))
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 1)
                }
                .padding(.horizontal, Theme.hMargin)

                extra()
                    .padding(.top, 20)

                Spacer(minLength: 20)

                SaveatPrimaryButton(title: ctaTitle, action: onContinue)
                    .padding(.horizontal, Theme.hMargin)
                    .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension IntroStepShell where Extra == EmptyView {
    init(
        photoAssetNames: [String],
        stepIndex: Int,
        stepCount: Int,
        icon: String,
        title: String,
        body_: String,
        ctaTitle: String,
        onContinue: @escaping () -> Void,
        onSkip: (() -> Void)? = nil
    ) {
        self.init(
            photoAssetNames: photoAssetNames, stepIndex: stepIndex, stepCount: stepCount,
            icon: icon, title: title, body_: body_, ctaTitle: ctaTitle, onContinue: onContinue,
            onSkip: onSkip
        ) { EmptyView() }
    }
}

/// One line of a pitch bullet list — a small check and a label, nothing more.
struct IntroPointRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SaveatColors.brand)
                .frame(width: 20)
            Text(text)
                .font(SaveatTypography.caption(14))
                .foregroundStyle(SaveatColors.textPrimary)
            Spacer(minLength: 0)
        }
    }
}

/// A titled icon used by short pitch lists (Welcome's feature row, Account's
/// benefit list). A plain `Identifiable` struct rather than a tuple, so every
/// `ForEach` over one has an unambiguous, always-valid `id`.
struct IntroFeature: Identifiable {
    let id: String
    let icon: String

    init(_ title: String, icon: String) {
        self.id = title
        self.icon = icon
    }

    var title: String { id }
}
