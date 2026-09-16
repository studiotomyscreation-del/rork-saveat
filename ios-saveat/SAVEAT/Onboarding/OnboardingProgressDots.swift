import SwiftUI

/// Progress dots for the product-pitch onboarding, styled to sit on top of a
/// photo (white-based) rather than the plain ivory bar the flow used before
/// full-bleed photos. Each page overlays its own copy near the top of its
/// own `ZStack`, so there is no separate bar above the `TabView` that would
/// otherwise seam against a dark photo underneath it.
struct OnboardingProgressDots: View {
    let stepIndex: Int
    let stepCount: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { index in
                Capsule()
                    .fill(index <= stepIndex ? .white : .white.opacity(0.32))
                    .frame(width: index == stepIndex ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: stepIndex)
            }
        }
    }
}
