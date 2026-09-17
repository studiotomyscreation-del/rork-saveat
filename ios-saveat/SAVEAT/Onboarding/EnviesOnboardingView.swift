import SwiftUI

/// Second screen of the product-pitch onboarding: what the household feels
/// like cooking this week. Purely presentational — selections here are not
/// persisted; the real preferences are collected later in the household
/// setup (`OnboardingView`), same as every other page in this pitch.
struct EnviesOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

    @State private var selected: Set<String> = []

    private var chips: [String] {
        [
            S.Intro.enviesChipQuick.s,
            S.Intro.enviesChipFamily.s,
            S.Intro.enviesChipBudget.s,
            S.Intro.enviesChipBalanced.s,
            S.Intro.enviesChipFrench.s,
            S.Intro.enviesChipItalian.s,
            S.Intro.enviesChipWorld.s,
            S.Intro.enviesChipVegetarian.s,
            S.Intro.enviesChipGourmet.s
        ]
    }

    var body: some View {
        IntroStepShell(
            photoAssetNames: [],
            stepIndex: 1,
            stepCount: 11,
            icon: "sparkles",
            title: S.Intro.enviesTitle.s,
            body_: S.Intro.enviesSubtitle.s,
            ctaTitle: S.Intro.continueCTA.s,
            onContinue: onContinue,
            onSkip: onSkip
        ) {
            FlowLayout(spacing: 10) {
                ForEach(chips, id: \.self) { chip in
                    chipButton(chip)
                }
            }
            .padding(.horizontal, Theme.hMargin)
        }
    }

    private func chipButton(_ label: String) -> some View {
        let isSelected = selected.contains(label)
        return Button {
            Haptics.light()
            if isSelected { selected.remove(label) } else { selected.insert(label) }
        } label: {
            Text(label)
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? SaveatColors.forestDeep : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? .white : .white.opacity(0.16), in: .capsule)
                .overlay {
                    Capsule().stroke(.white.opacity(isSelected ? 0 : 0.4), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

/// Minimal tag-wrapping layout — chips flow left to right and wrap onto a
/// new line once they run out of width, unlike a fixed grid.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var origin = CGPoint.zero
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > width, origin.x > 0 {
                origin.x = 0
                origin.y += lineHeight + spacing
                lineHeight = 0
            }
            origin.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, origin.x - spacing)
        }
        return CGSize(width: maxWidth, height: origin.y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: origin, proposal: .unspecified)
            origin.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    EnviesOnboardingView(onContinue: {}, onSkip: {})
}
