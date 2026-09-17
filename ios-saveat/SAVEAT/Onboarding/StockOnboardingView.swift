import SwiftUI

/// Eighth screen of the product-pitch onboarding: Frigo / Placard / Congélateur.
///
/// The tab row and rows below are a static preview — illustrative examples,
/// not the user's real stock, which does not exist yet at this point in
/// onboarding.
struct StockOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

    @State private var selected: StorageLocation = .fridge

    private struct PreviewRow {
        let emoji: String
        let name: String
        let detail: String
        let isSoon: Bool
    }

    private let rows: [PreviewRow] = [
        PreviewRow(emoji: "🥛", name: "Lait", detail: "12/09/2026", isSoon: false),
        PreviewRow(emoji: "🍅", name: "Tomates", detail: S.Intro.stockExampleSoon.s, isSoon: true),
        PreviewRow(emoji: "🥣", name: "Yaourt nature", detail: "15/09/2026", isSoon: false),
        PreviewRow(emoji: "🥒", name: "Courgettes", detail: S.Intro.stockExampleSoon.s, isSoon: true)
    ]

    /// The bundled fridge-interior photo already used on the welcome page
    /// fits this screen's own topic (frigo/placard/congélateur) even more
    /// literally — reused here until a dedicated `onboarding_stock` photo
    /// exists.
    private static let photoAssetNames = ["onboarding_stock", "open_refrigerator_interior"]

    var body: some View {
        IntroStepShell(
            photoAssetNames: Self.photoAssetNames,
            stepIndex: 7,
            stepCount: 11,
            icon: "refrigerator",
            title: S.Intro.stockTitle.s,
            body_: S.Intro.stockBody.s,
            ctaTitle: S.Common.next.s,
            onContinue: onContinue,
            onSkip: onSkip
        ) {
            VStack(spacing: 12) {
                locationTabs

                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        HStack(spacing: 12) {
                            Text(row.emoji).font(.system(size: 22))
                            Text(row.name)
                                .font(SaveatTypography.headline(14.5))
                                .foregroundStyle(SaveatColors.textPrimary)
                            Spacer(minLength: 8)
                            Text(row.detail)
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(row.isSoon ? SaveatColors.promo : SaveatColors.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        if index < rows.count - 1 {
                            Divider().overlay(SaveatColors.forestDeep.opacity(0.06))
                        }
                    }
                }
                .saveatTranslucentCard(padding: 10)
            }
            .padding(.horizontal, Theme.hMargin)
        }
    }

    private var locationTabs: some View {
        HStack(spacing: 8) {
            ForEach(StorageLocation.allCases) { location in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selected = location }
                } label: {
                    Text(location.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(selected == location ? SaveatColors.textOnDark : SaveatColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selected == location ? SaveatColors.brand : .white.opacity(0.92),
                            in: .capsule
                        )
                }
                .buttonStyle(SoftPressStyle())
            }
        }
    }
}

#Preview {
    StockOnboardingView(onContinue: {}, onSkip: {})
}
