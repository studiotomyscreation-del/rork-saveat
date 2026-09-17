import SwiftUI

/// Seventh screen of the product-pitch onboarding: the shopping list SAVEAT
/// builds once the week is planned, with what's already at home removed.
///
/// Every item, category and count here is fixed example data
/// (`shoppingPreviewDemoNotice`) — there is no real week or real stock yet
/// at this point in onboarding. The real list must come from
/// `ShoppingListEngine` (future phase), never be invented here.
struct ShoppingListOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

    private struct DemoSection: Identifiable {
        let id = UUID()
        let category: String
        let items: [String]
    }

    private var sections: [DemoSection] {
        [
            DemoSection(category: S.Category.produce.s, items: [
                S.Intro.shoppingPreviewOnions.s,
                S.Intro.shoppingPreviewZucchini.s,
                S.Intro.shoppingPreviewMushrooms.s
            ]),
            DemoSection(category: S.Category.protein.s, items: [S.Intro.shoppingPreviewSalmon.s]),
            DemoSection(category: S.Category.dairy.s, items: [
                S.Intro.shoppingPreviewParmesan.s,
                S.Intro.shoppingPreviewYogurt.s
            ])
        ]
    }

    var body: some View {
        IntroStepShell(
            photoAssetNames: [],
            stepIndex: 6,
            stepCount: 12,
            icon: "cart.fill",
            title: S.Intro.shoppingPreviewTitle.s,
            body_: S.Intro.shoppingPreviewSubtitle.s,
            ctaTitle: S.Intro.shoppingPreviewCTA.s,
            onContinue: onContinue,
            onSkip: onSkip
        ) {
            VStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.category.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(0.6)
                                .foregroundStyle(SaveatColors.brand)
                            ForEach(section.items, id: \.self) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: "square")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(SaveatColors.textSecondary)
                                    Text(item)
                                        .font(SaveatTypography.body(14))
                                        .foregroundStyle(SaveatColors.textPrimary)
                                }
                            }
                        }
                    }

                    Divider()

                    HStack {
                        Text(S.Intro.shoppingPreviewToBuy.f(17))
                            .font(SaveatTypography.headline(14))
                            .foregroundStyle(SaveatColors.forestDeep)
                        Spacer(minLength: 0)
                        Text(S.Intro.shoppingPreviewAlreadyHave.f(12))
                            .font(SaveatTypography.caption(12.5))
                            .foregroundStyle(SaveatColors.textSecondary)
                    }
                }
                .saveatTranslucentCard()

                Text(S.Intro.shoppingPreviewDemoNotice.s)
                    .font(SaveatTypography.caption(11.5))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, Theme.hMargin)
        }
    }
}

#Preview {
    ShoppingListOnboardingView(onContinue: {}, onSkip: {})
}
