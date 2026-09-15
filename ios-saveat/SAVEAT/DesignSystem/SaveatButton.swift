import SwiftUI

/// SAVEAT V2 primary action button: full-width pill, brand green fill.
///
/// A `View`, not a `ButtonStyle`, so it never collides with the existing
/// `SaveatButtonStyle` in `Theme.swift` — both can be used side by side while
/// screens migrate one at a time.
struct SaveatPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.soft()
            action()
        } label: {
            ZStack {
                Text(title)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(SaveatColors.textOnDark)
                }
            }
            .font(SaveatTypography.headline(17))
            .foregroundStyle(SaveatColors.textOnDark)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(SaveatColors.brand, in: .capsule)
            .opacity(isEnabled ? 1 : 0.5)
        }
        .buttonStyle(SoftPressStyle())
        .disabled(!isEnabled || isLoading)
    }
}

/// SAVEAT V2 secondary action button: outlined, no fill.
struct SaveatSecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Text(title)
                .font(SaveatTypography.headline(16))
                .foregroundStyle(SaveatColors.forestDeep)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(SaveatColors.surface, in: .capsule)
                .overlay {
                    Capsule().stroke(SaveatColors.forestDeep.opacity(0.18), lineWidth: 1.2)
                }
        }
        .buttonStyle(SoftPressStyle())
    }
}

/// SAVEAT V2 quiet text-only action ("Passer", "J'ai déjà un compte").
struct SaveatTextButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SaveatTypography.caption(14))
                .foregroundStyle(SaveatColors.textSecondary)
        }
        .buttonStyle(.plain)
    }
}
