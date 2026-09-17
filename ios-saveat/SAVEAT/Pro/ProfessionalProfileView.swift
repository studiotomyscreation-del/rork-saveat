import SwiftUI

/// The professional's own space once they've signed up (§13) — the missing
/// destination the sign-up flow had no page to land on before.
///
/// Shows exactly what the professional entered during sign-up, saved
/// locally on this device (`ProAccountStore`). No dashboard, no baskets, no
/// reservations yet — none of that exists without a real backend (see the
/// Phase 1 audit), so `dashboardComingSoonNotice` says so plainly instead of
/// implying more than what's actually here.
struct ProfessionalProfileView: View {
    @Environment(ProAccountStore.self) private var proAccount
    @Environment(\.dismiss) private var dismiss
    @State private var showsLeaveConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let merchant = proAccount.merchant {
                        establishmentCard(merchant)
                    }
                    if let account = proAccount.account {
                        responsibleCard(account)
                    }

                    Text(S.Pro.dashboardComingSoonNotice.s)
                        .font(SaveatTypography.caption(11.5))
                        .foregroundStyle(SaveatColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    SaveatTextButton(
                        title: S.Pro.leaveProSpaceCTA.s,
                        tint: SaveatColors.alert
                    ) {
                        showsLeaveConfirmation = true
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, Theme.hMargin)
                .padding(.top, 8)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .background(SaveatColors.background.ignoresSafeArea())
            .navigationTitle(S.Pro.proProfileTitle.s)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(S.Common.close.s) { dismiss() }
                }
            }
            .alert(S.Pro.leaveProSpaceConfirmTitle.s, isPresented: $showsLeaveConfirmation) {
                Button(S.Common.cancel.s, role: .cancel) {}
                Button(S.Pro.leaveProSpaceCTA.s, role: .destructive) {
                    proAccount.reset()
                    dismiss()
                }
            } message: {
                Text(S.Pro.leaveProSpaceConfirmMessage.s)
            }
        }
    }

    private func establishmentCard(_ merchant: Merchant) -> some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(S.Pro.establishmentSectionTitle.s)
                        .font(SaveatTypography.caption(12))
                        .foregroundStyle(SaveatColors.textSecondary)
                    Spacer(minLength: 0)
                    if merchant.administrativeStatus == .active {
                        SaveatBadge(text: S.Pro.statusEstablishmentIdentified.s, tone: .brand)
                    }
                }
                Text(merchant.displayName)
                    .font(SaveatTypography.headline(17))
                    .foregroundStyle(SaveatColors.textPrimary)
                Text(merchant.businessIdentifier)
                    .font(SaveatTypography.caption(13))
                    .foregroundStyle(SaveatColors.textSecondary)
            }
        }
    }

    private func responsibleCard(_ account: ProfessionalAccount) -> some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(S.Pro.responsibleSectionTitle.s)
                    .font(SaveatTypography.caption(12))
                    .foregroundStyle(SaveatColors.textSecondary)
                Text(account.fullName)
                    .font(SaveatTypography.headline(15))
                    .foregroundStyle(SaveatColors.textPrimary)
                Text(account.email)
                    .font(SaveatTypography.body(14))
                    .foregroundStyle(SaveatColors.textSecondary)
                Text(account.phone)
                    .font(SaveatTypography.body(14))
                    .foregroundStyle(SaveatColors.textSecondary)
            }
        }
    }
}

#Preview {
    let store = ProAccountStore()
    store.createAccount(
        from: BusinessRegistryRecord(
            siren: "123456789",
            siret: "12345678900012",
            legalName: "Boulangerie Martin",
            tradeName: nil,
            activityCode: "10.71C",
            administrativeStatus: .active,
            address: "12 rue de la Paix",
            postalCode: "33000",
            city: "Bordeaux",
            countryCode: "FR",
            isHeadquarters: true,
            totalEstablishmentCount: 1
        ),
        firstName: "Julie",
        lastName: "Martin",
        email: "julie@boulangerie-martin.fr",
        phone: "0601020304"
    )
    return ProfessionalProfileView()
        .environment(store)
}
