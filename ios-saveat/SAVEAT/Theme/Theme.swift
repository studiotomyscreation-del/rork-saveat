import SwiftUI

/// SAVEAT design system: soft sage greens on warm cream, cosy family-kitchen mood.
enum Theme {
    // MARK: Colors
    static let cream = Color(red: 0.980, green: 0.969, blue: 0.945)      // #FAF7F1
    static let creamDeep = Color(red: 0.960, green: 0.945, blue: 0.914)  // #F5F1E9
    static let surface = Color.white
    static let sage = Color(red: 0.616, green: 0.733, blue: 0.643)       // #9DBBA4
    static let sageDeep = Color(red: 0.431, green: 0.549, blue: 0.467)   // #6E8C77
    static let sageMist = Color(red: 0.929, green: 0.949, blue: 0.925)   // #EDF2EC
    static let terracotta = Color(red: 0.878, green: 0.643, blue: 0.494) // #E0A47E
    static let clay = Color(red: 0.788, green: 0.435, blue: 0.353)       // #C96F5A
    static let ink = Color(red: 0.239, green: 0.290, blue: 0.243)        // #3D4A3E
    static let inkSoft = Color(red: 0.478, green: 0.522, blue: 0.482)    // #7A857B

    // MARK: Metrics
    static let cardRadius: CGFloat = 24
    static let tileRadius: CGFloat = 20
    static let pillRadius: CGFloat = 28
    static let hMargin: CGFloat = 20

    // MARK: Type roles
    static func display(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func title(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func numeric(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded).monospacedDigit()
    }

    static let sectionLabel: Font = .system(size: 12, weight: .semibold, design: .rounded)
}

extension View {
    /// Soft white card used across every SAVEAT surface.
    func saveatCard(padding: CGFloat = 18, radius: CGFloat = Theme.cardRadius) -> some View {
        self
            .padding(padding)
            .background(Theme.surface, in: .rect(cornerRadius: radius))
            .shadow(color: Theme.ink.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    /// Warm cream page background that ignores safe areas.
    func saveatBackground() -> some View {
        self.background(Theme.cream.ignoresSafeArea())
    }
}

/// Small uppercase section header in sage.
struct SectionLabel: View {
    let text: String
    var color: Color = Theme.sageDeep

    var body: some View {
        Text(text.uppercased())
            .font(Theme.sectionLabel)
            .tracking(1.1)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Primary pill button in sage.
struct SaveatButtonStyle: ButtonStyle {
    var tint: Color = Theme.sage
    var foreground: Color = .white
    var isProminent: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(isProminent ? foreground : tint)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                isProminent ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.14)),
                in: .rect(cornerRadius: Theme.pillRadius)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Subtle press feedback for cards and tiles.
struct SoftPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
