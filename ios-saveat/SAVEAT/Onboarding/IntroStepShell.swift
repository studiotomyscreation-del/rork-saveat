import SwiftUI

/// Shared layout for the four pitch cards of the product onboarding
/// (Scan / Stock / Recipes / Map): icon, title, body, optional bullet list,
/// primary CTA. Keeps the four screens visually identical without repeating
/// the same layout code four times.
struct IntroStepShell<Extra: View>: View {
    let icon: String
    let title: String
    let body_: String
    let ctaTitle: String
    let onContinue: () -> Void
    private let extra: () -> Extra

    init(
        icon: String,
        title: String,
        body_: String,
        ctaTitle: String,
        onContinue: @escaping () -> Void,
        @ViewBuilder extra: @escaping () -> Extra
    ) {
        self.icon = icon
        self.title = title
        self.body_ = body_
        self.ctaTitle = ctaTitle
        self.onContinue = onContinue
        self.extra = extra
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            ZStack {
                Circle()
                    .fill(SaveatColors.brandSoft)
                    .frame(width: 120, height: 120)
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(SaveatColors.forestDeep)
            }
            .padding(.bottom, 28)

            VStack(spacing: 10) {
                Text(title)
                    .font(SaveatTypography.hero(26))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SaveatColors.textPrimary)
                Text(body_)
                    .font(SaveatTypography.body(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SaveatColors.textSecondary)
            }
            .padding(.horizontal, Theme.hMargin)

            extra()
                .padding(.top, 22)

            Spacer(minLength: 24)

            SaveatPrimaryButton(title: ctaTitle, action: onContinue)
                .padding(.horizontal, Theme.hMargin)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SaveatColors.background.ignoresSafeArea())
    }
}

extension IntroStepShell where Extra == EmptyView {
    init(icon: String, title: String, body_: String, ctaTitle: String, onContinue: @escaping () -> Void) {
        self.init(icon: icon, title: title, body_: body_, ctaTitle: ctaTitle, onContinue: onContinue) { EmptyView() }
    }
}

/// One line of a pitch bullet list — a small check and a label, nothing more.
struct IntroPointRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SaveatColors.brand)
                .frame(width: 20)
            Text(text)
                .font(SaveatTypography.caption(14))
                .foregroundStyle(SaveatColors.textPrimary)
            Spacer(minLength: 0)
        }
    }
}

/// A titled icon used by short pitch lists (Welcome's feature row, Account's
/// benefit list). A plain `Identifiable` struct rather than a tuple, so every
/// `ForEach` over one has an unambiguous, always-valid `id`.
struct IntroFeature: Identifiable {
    let id: String
    let icon: String

    init(_ title: String, icon: String) {
        self.id = title
        self.icon = icon
    }

    var title: String { id }
}
