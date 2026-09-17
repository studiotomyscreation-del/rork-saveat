import SwiftUI

/// Very first screen of the product-pitch onboarding: particulier or
/// professional — asked upfront rather than leaving SAVEAT PRO discoverable
/// only by digging into Profile after onboarding.
///
/// Choosing "Particulier" simply advances into the existing pitch
/// (Welcome → … → Account). Choosing "Professionnel" opens the existing
/// SAVEAT PRO sign-up flow (`ProSignUpContainerView`, already built —
/// nothing duplicated here) as a sheet; once a local pro profile exists
/// (`ProAccountStore.hasAccount`), the whole pitch is skipped and the app
/// opens directly, since a food business doesn't need the "Chef plans your
/// week" pitch aimed at home cooks.
struct AccountTypeOnboardingView: View {
    @Environment(ProAccountStore.self) private var proAccount
    var onSelectParticulier: () -> Void
    var onFinished: () -> Void

    @State private var showsProSignUp = false

    var body: some View {
        ZStack {
            OnboardingPhotoBackground(assetNames: [])

            VStack(spacing: 28) {
                Spacer(minLength: 40)

                VStack(spacing: 14) {
                    BrandMark(size: 64)
                    Text(S.Intro.accountTypeTitle.s)
                        .font(SaveatTypography.hero(28))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 14) {
                    optionCard(
                        icon: "house.fill",
                        title: S.Intro.accountTypeParticulier.s,
                        subtitle: S.Intro.accountTypeParticulierSubtitle.s,
                        action: onSelectParticulier
                    )
                    optionCard(
                        icon: "storefront.fill",
                        title: S.Intro.accountTypePro.s,
                        subtitle: S.Intro.accountTypeProSubtitle.s,
                        action: { showsProSignUp = true }
                    )
                }
                .padding(.horizontal, Theme.hMargin)

                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showsProSignUp, onDismiss: {
            if proAccount.hasAccount { onFinished() }
        }) {
            ProSignUpContainerView()
        }
    }

    private func optionCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(.white.opacity(0.16)).frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SaveatTypography.headline(16))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(SaveatTypography.caption(12.5))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(16)
            .background(.white.opacity(0.12), in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.25), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AccountTypeOnboardingView(onSelectParticulier: {}, onFinished: {})
        .environment(ProAccountStore())
}
