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

    /// The lifestyle kitchen-counter photo the user supplied for this exact
    /// screen — this is the very first thing anyone sees, so it carries the
    /// most weight of any onboarding page. Falls back to a bundled dish
    /// photo, distinct from `WelcomeOnboardingView`'s
    /// (`chicken_rice_bowl_topdown`), so two consecutive pages never repeat
    /// the same shot.
    private static let photoAssetNames = ["onboarding_account_type", "french_omelette_ham_cheese"]

    var body: some View {
        ZStack {
            OnboardingPhotoBackground(assetNames: Self.photoAssetNames)

            VStack(spacing: 28) {
                Spacer(minLength: 60)

                VStack(spacing: 14) {
                    BrandMark(size: 60)
                    Text(S.Intro.accountTypeTitle.s)
                        .font(SaveatTypography.hero(30))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
                }

                Spacer(minLength: 20)

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
                .padding(.bottom, 40)
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
                    Circle().fill(SaveatColors.brandSoft).frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(SaveatColors.forestDeep)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SaveatTypography.headline(16))
                        .foregroundStyle(SaveatColors.textPrimary)
                    Text(subtitle)
                        .font(SaveatTypography.caption(12.5))
                        .foregroundStyle(SaveatColors.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SaveatColors.textSecondary.opacity(0.6))
            }
            .saveatTranslucentCard(padding: 16, radius: 20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AccountTypeOnboardingView(onSelectParticulier: {}, onFinished: {})
        .environment(ProAccountStore())
}
