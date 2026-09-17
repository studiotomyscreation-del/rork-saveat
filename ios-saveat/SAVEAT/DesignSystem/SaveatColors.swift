import SwiftUI

/// SAVEAT V2 palette — additive to `Theme`, not a replacement.
///
/// `Theme` remains the source of truth for every screen already shipping.
/// `SaveatColors` is scoped to the V2 surfaces built from this palette
/// (the new onboarding, and future Home / Map / Deals work): once a screen
/// has fully migrated, it should read `SaveatColors`; until then it keeps
/// reading `Theme` exactly as before.
enum SaveatColors {
    /// #0F5132 — deep green, headlines and primary text on light surfaces.
    static let forestDeep = Color(red: 0x0F / 255, green: 0x51 / 255, blue: 0x32 / 255)
    /// #22C55E — SAVEAT green, the primary brand and action color.
    static let brand = Color(red: 0x22 / 255, green: 0xC5 / 255, blue: 0x5E / 255)
    /// #8FE34F — light green, highlights and secondary accents.
    static let brandLight = Color(red: 0x8F / 255, green: 0xE3 / 255, blue: 0x4F / 255)
    /// #101C2C — night blue, dark surfaces and high-contrast text.
    static let nightBlue = Color(red: 0x10 / 255, green: 0x1C / 255, blue: 0x2C / 255)
    /// #FFF5E8 — ivory, the warm default background.
    static let ivory = Color(red: 0xFF / 255, green: 0xF5 / 255, blue: 0xE8 / 255)
    /// #FFFFFF — plain white, cards on ivory or dark grounds.
    static let white = Color.white
    /// #FFB347 — orange, promotions and deals only. Never a status color.
    static let promo = Color(red: 0xFF / 255, green: 0xB3 / 255, blue: 0x47 / 255)
    /// #F25C54 — red, alerts and destructive actions only.
    static let alert = Color(red: 0xF2 / 255, green: 0x5C / 255, blue: 0x54 / 255)
    /// #938ED0 — lavender, secondary accent for non-food, non-money moments.
    static let lavender = Color(red: 0x93 / 255, green: 0x8E / 255, blue: 0xD0 / 255)

    // MARK: - Semantic roles

    /// Default page background for V2 surfaces.
    static let background = ivory
    /// Card / surface fill on top of `background`.
    static let surface = white
    /// Primary text on `background` / `surface`.
    static let textPrimary = forestDeep
    /// Secondary text — captions, helper lines.
    static let textSecondary = forestDeep.opacity(0.62)
    /// Text on `nightBlue` or `brand` grounds.
    static let textOnDark = ivory
    /// Soft tint fill for selected rows, chips, badges.
    static let brandSoft = brand.opacity(0.14)
}

extension View {
    /// Soft "aurora" backdrop for V2 surfaces — the ivory background plus
    /// two large blurred brand-green blobs, echoing `NativePaywallView`'s
    /// backdrop (ivory + soft blurred circles) while staying inside
    /// `SaveatColors`' own palette rather than reusing `Theme`'s sage/
    /// terracotta directly, and never `promo`/`alert` (reserved for actual
    /// deals and warnings, not plain ambience).
    func saveatSoftBackdrop() -> some View {
        background {
            ZStack {
                SaveatColors.background
                Circle()
                    .fill(SaveatColors.brand.opacity(0.16))
                    .frame(width: 420, height: 420)
                    .blur(radius: 90)
                    .offset(x: -130, y: -260)
                Circle()
                    .fill(SaveatColors.brandLight.opacity(0.22))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .offset(x: 150, y: 200)
            }
            .ignoresSafeArea()
        }
    }
}
