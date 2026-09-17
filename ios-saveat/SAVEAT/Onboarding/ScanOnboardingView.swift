import SwiftUI

/// Eighth screen of the product-pitch onboarding: what scanning gets you.
struct ScanOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

    /// No existing bundled photo fits "scanning a product package" well
    /// (the food photos on hand are all finished dishes) — reserves
    /// `onboarding_scan` for a dedicated photo and falls back to the plain
    /// brand gradient alone until it's added, never a mismatched stand-in.
    private static let photoAssetNames = ["onboarding_scan"]

    var body: some View {
        IntroStepShell(
            photoAssetNames: Self.photoAssetNames,
            stepIndex: 7,
            stepCount: 12,
            icon: "barcode.viewfinder",
            title: "\(S.Intro.scanEyebrow.s)\n\(S.Intro.scanHeadline.s)",
            body_: S.Intro.scanBody.s,
            ctaTitle: S.Common.next.s,
            onContinue: onContinue,
            onSkip: onSkip
        ) {
            VStack(alignment: .leading, spacing: 14) {
                IntroPointRow(icon: "checkmark.seal.fill", text: S.Intro.scanPointNutriScore.s)
                IntroPointRow(icon: "checkmark.circle.fill", text: S.Intro.scanPointBarcode.s)
                IntroPointRow(icon: "checkmark.circle.fill", text: S.Intro.scanPointAnalysis.s)
                IntroPointRow(icon: "checkmark.circle.fill", text: S.Intro.scanPointAutoStock.s)
                IntroPointRow(icon: "checkmark.circle.fill", text: S.Intro.scanPointExpiry.s)
                IntroPointRow(icon: "checkmark.circle.fill", text: S.Intro.scanPointDeal.s)
            }
            .saveatTranslucentCard()
            .padding(.horizontal, Theme.hMargin)
        }
    }
}

#Preview {
    ScanOnboardingView(onContinue: {}, onSkip: {})
}
