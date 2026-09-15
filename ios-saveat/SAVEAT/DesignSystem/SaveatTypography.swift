import SwiftUI

/// SAVEAT V2 type roles — same rounded system font family already used across
/// the app (`Theme.display`/`Theme.title`/`Theme.body`), organised as named
/// roles so new screens pick a role instead of a raw size.
enum SaveatTypography {
    /// Large pitch headlines (onboarding, hero moments).
    static func hero(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    /// Section / screen titles.
    static func title(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    /// Card and row titles.
    static func headline(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    /// Default running text.
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    /// Captions, helper lines, legal notices.
    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    /// Uppercase eyebrow labels ("BIENTÔT", section markers).
    static func eyebrow(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    /// Digits that must line up — prices, counters.
    static func numeric(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
    }
}
