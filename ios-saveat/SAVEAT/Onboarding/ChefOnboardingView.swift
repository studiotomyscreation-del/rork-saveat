import SwiftUI

/// Fifth screen of the product-pitch onboarding: a preview of what a
/// generated week looks like. Content here is fixed, clearly-labelled
/// example data (`chefDemoNotice`) — the real week will come from
/// `MealAIService` once the household's actual stock and preferences exist,
/// neither of which is available at this point in onboarding.
struct ChefOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

    private struct DemoDay: Identifiable {
        let id = UUID()
        let day: String
        let dish: String
    }

    private var demoDays: [DemoDay] {
        [
            DemoDay(day: S.Intro.chefDay1.s, dish: S.Intro.chefDay1Dish.s),
            DemoDay(day: S.Intro.chefDay2.s, dish: S.Intro.chefDay2Dish.s),
            DemoDay(day: S.Intro.chefDay3.s, dish: S.Intro.chefDay3Dish.s),
            DemoDay(day: S.Intro.chefDay4.s, dish: S.Intro.chefDay4Dish.s)
        ]
    }

    var body: some View {
        IntroStepShell(
            photoAssetNames: ["onboarding_chef", "chicken_rice_bowl_topdown"],
            stepIndex: 4,
            stepCount: 12,
            icon: "fork.knife",
            title: S.Intro.chefTitle.s,
            body_: S.Intro.chefSubtitle.s,
            ctaTitle: S.Intro.chefCTA.s,
            onContinue: onContinue,
            onSkip: onSkip
        ) {
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    ForEach(demoDays) { entry in
                        dayRow(entry)
                    }
                }
                .saveatTranslucentCard(padding: 14)

                Text(S.Intro.chefDemoNotice.s)
                    .font(SaveatTypography.caption(11.5))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, Theme.hMargin)
        }
    }

    private func dayRow(_ entry: DemoDay) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.day.uppercased())
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(SaveatColors.brand)
                .frame(width: 64, alignment: .leading)
            Text(entry.dish)
                .font(SaveatTypography.body(14))
                .foregroundStyle(SaveatColors.textPrimary)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ChefOnboardingView(onContinue: {}, onSkip: {})
}
