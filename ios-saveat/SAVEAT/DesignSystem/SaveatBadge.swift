import SwiftUI

/// SAVEAT V2 badge tones. Semantic, kept separate from the brand accent so a
/// promo or alert never gets mistaken for the primary action color.
enum SaveatBadgeTone {
    case brand
    case promo
    case alert
    case neutral

    var foreground: Color {
        switch self {
        case .brand: SaveatColors.forestDeep
        case .promo: Color(red: 0x8A / 255, green: 0x52 / 255, blue: 0x00 / 255)
        case .alert: SaveatColors.alert
        case .neutral: SaveatColors.textSecondary
        }
    }

    var background: Color {
        switch self {
        case .brand: SaveatColors.brandSoft
        case .promo: SaveatColors.promo.opacity(0.18)
        case .alert: SaveatColors.alert.opacity(0.14)
        case .neutral: SaveatColors.nightBlue.opacity(0.06)
        }
    }
}

/// SAVEAT V2 pill badge — feature tags, "BIENTÔT", promo/alert flags.
struct SaveatBadge: View {
    let text: String
    var tone: SaveatBadgeTone = .brand
    var icon: String?

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
            }
            Text(text)
        }
        .font(SaveatTypography.eyebrow(11.5))
        .tracking(0.4)
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tone.background, in: .capsule)
    }
}
