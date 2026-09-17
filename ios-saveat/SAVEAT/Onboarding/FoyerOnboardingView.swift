import SwiftUI

/// Third screen of the product-pitch onboarding: household size and how many
/// days to plan for. Reuses `QuantityStepper` (already used for servings in
/// `MealAssistantView`) rather than a new counter component. Purely
/// presentational — not persisted; the real household size is set later in
/// `OnboardingView`.
struct FoyerOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

    @State private var people = 4
    @State private var days = 7

    var body: some View {
        IntroStepShell(
            photoAssetNames: [],
            stepIndex: 2,
            stepCount: 11,
            icon: "person.2.fill",
            title: S.Intro.foyerTitle.s,
            body_: S.Intro.foyerSubtitle.s,
            ctaTitle: S.Intro.foyerCTA.s,
            onContinue: onContinue,
            onSkip: onSkip
        ) {
            VStack(spacing: 16) {
                HStack {
                    Spacer(minLength: 0)
                    QuantityStepper(value: $people, range: 1...12)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
                .saveatTranslucentCard()

                Text(S.Intro.foyerDaysTitle.s)
                    .font(SaveatTypography.headline(15))
                    .foregroundStyle(.white)

                HStack(spacing: 10) {
                    dayOption(5, label: S.Intro.foyerDays5.s)
                    dayOption(7, label: S.Intro.foyerDays7.s)
                }
            }
            .padding(.horizontal, Theme.hMargin)
        }
    }

    private func dayOption(_ value: Int, label: String) -> some View {
        let isSelected = days == value
        return Button {
            Haptics.light()
            days = value
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? SaveatColors.forestDeep : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? .white : .white.opacity(0.16), in: .capsule)
                .overlay {
                    Capsule().stroke(.white.opacity(isSelected ? 0 : 0.4), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FoyerOnboardingView(onContinue: {}, onSkip: {})
}
