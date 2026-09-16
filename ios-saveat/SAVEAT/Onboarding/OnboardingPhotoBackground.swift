import SwiftUI

/// Full-bleed photo backdrop shared by every onboarding page: a real photo,
/// clipped and filled, under SAVEAT's dark-green scrim for legible text.
///
/// Tries each name in `assetNames` in order and renders the first one that
/// actually exists in the asset catalog (same `UIImage(named:) != nil` guard
/// already used by `MealCard`/`MealDetailView`) — so a page can prefer a
/// dedicated photo (`onboarding_scan`) while still falling back to an
/// existing, thematically close one, and finally to the plain brand gradient
/// alone when nothing fits yet. Never a placeholder image, only ever a real
/// photo or the gradient — so an unfinished asset never ships as a visible
/// "missing image" box.
struct OnboardingPhotoBackground: View {
    /// Preferred asset name first, fallbacks after — e.g.
    /// `["onboarding_scan"]` or `["onboarding_stock", "open_refrigerator_interior"]`.
    let assetNames: [String]

    /// Darkest at the bottom, where the title and CTA usually sit; still
    /// dark enough near the top that an icon or eyebrow stays legible too.
    private static let scrim = LinearGradient(
        colors: [
            SaveatColors.nightBlue.opacity(0.38),
            SaveatColors.forestDeep.opacity(0.62),
            SaveatColors.nightBlue.opacity(0.93)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private var resolvedAssetName: String? {
        assetNames.first { UIImage(named: $0) != nil }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Plain brand gradient first — the base every page falls back
                // to, so a not-yet-added photo never leaves a blank/white gap.
                LinearGradient(
                    colors: [SaveatColors.forestDeep, SaveatColors.nightBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let resolvedAssetName {
                    Image(resolvedAssetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }

                Self.scrim
            }
        }
        .ignoresSafeArea()
    }
}
