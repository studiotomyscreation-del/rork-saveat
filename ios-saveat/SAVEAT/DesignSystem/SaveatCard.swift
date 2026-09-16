import SwiftUI

/// SAVEAT V2 card surface: white on ivory, generous radius, soft shadow.
///
/// Equivalent to `.saveatCard()` from `Theme.swift` but built on
/// `SaveatColors`, for screens using the new palette.
struct SaveatCard<Content: View>: View {
    var padding: CGFloat = 20
    var radius: CGFloat = 24
    private let content: () -> Content

    init(padding: CGFloat = 20, radius: CGFloat = 24, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.radius = radius
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(SaveatColors.surface, in: .rect(cornerRadius: radius))
            .shadow(color: SaveatColors.nightBlue.opacity(0.06), radius: 14, x: 0, y: 6)
    }
}

extension View {
    /// Wraps the view in a SAVEAT V2 card surface.
    func saveatV2Card(padding: CGFloat = 20, radius: CGFloat = 24) -> some View {
        self
            .padding(padding)
            .background(SaveatColors.surface, in: .rect(cornerRadius: radius))
            .shadow(color: SaveatColors.nightBlue.opacity(0.06), radius: 14, x: 0, y: 6)
    }

    /// Card surface for content sitting on top of a photo background — white,
    /// but only 92% opaque with a thin highlight border, so a sliver of the
    /// photo keeps showing through at the edges instead of the card reading
    /// as a flat opaque sheet (§ "cartes blanches légèrement translucides").
    func saveatTranslucentCard(padding: CGFloat = 18, radius: CGFloat = 22) -> some View {
        self
            .padding(padding)
            .background(.white.opacity(0.92), in: .rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: SaveatColors.nightBlue.opacity(0.25), radius: 18, x: 0, y: 8)
    }
}
