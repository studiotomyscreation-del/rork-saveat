import SwiftUI

/// Second screen of the product-pitch onboarding: what scanning gets you.
struct ScanOnboardingView: View {
    var onContinue: () -> Void

    var body: some View {
        IntroStepShell(
            icon: "barcode.viewfinder",
            title: "\(S.Intro.scanEyebrow.s)\n\(S.Intro.scanHeadline.s)",
            body_: S.Intro.scanBody.s,
            ctaTitle: S.Common.next.s,
            onContinue: onContinue
        ) {
            SaveatCard {
                VStack(alignment: .leading, spacing: 14) {
                    IntroPointRow(icon: "checkmark.seal.fill", text: S.Intro.scanPointNutriScore.s)
                    IntroPointRow(icon: "checkmark.circle.fill", text: S.Intro.scanPointBarcode.s)
                    IntroPointRow(icon: "checkmark.circle.fill", text: S.Intro.scanPointAnalysis.s)
                    IntroPointRow(icon: "checkmark.circle.fill", text: S.Intro.scanPointAutoStock.s)
                    IntroPointRow(icon: "checkmark.circle.fill", text: S.Intro.scanPointExpiry.s)
                    IntroPointRow(icon: "checkmark.circle.fill", text: S.Intro.scanPointDeal.s)
                }
            }
            .padding(.horizontal, Theme.hMargin)
        }
    }
}

#Preview {
    ScanOnboardingView(onContinue: {})
}
