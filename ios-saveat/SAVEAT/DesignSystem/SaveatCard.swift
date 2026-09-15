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
}
