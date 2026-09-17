import SwiftUI

/// The professional's own space once they've signed up (§13) — the missing
/// destination the sign-up flow had no page to land on before.
///
/// Shows exactly what the professional entered during sign-up, saved
/// locally on this device (`ProAccountStore`), plus the one basket they can
/// publish at their own shop front (`basketSection`). Still no real
/// reservations or statistics — none of that exists without a real backend
/// (see the Phase 1 audit), so `dashboardComingSoonNotice` says so plainly
/// instead of implying more than what's actually here.
struct ProfessionalProfileView: View {
    @Environment(ProAccountStore.self) private var proAccount
    @Environment(\.dismiss) private var dismiss
    @State private var showsLeaveConfirmation = false
    @State private var showsCreateOffer = false
    @State private var openingHoursText = ""
    @State private var pickupInstructionsText = ""

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
                    if proAccount.location != nil {
                        scheduleCard
                    }

                    basketSection

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
            .sheet(isPresented: $showsCreateOffer) {
                CreateBasketOfferView()
            }
            .onAppear {
                openingHoursText = proAccount.location?.openingHours ?? ""
                pickupInstructionsText = proAccount.location?.pickupInstructions ?? ""
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

    // MARK: - Schedule & pickup instructions (§8)

    private var scheduleCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(S.Pro.scheduleSectionTitle.s)
                    .font(SaveatTypography.caption(12))
                    .foregroundStyle(SaveatColors.textSecondary)
                field(S.Pro.openingHoursLabel.s, text: $openingHoursText, placeholder: S.Pro.openingHoursPlaceholder.s)
                Divider()
                field(S.Pro.pickupInstructionsLabel.s, text: $pickupInstructionsText, placeholder: S.Pro.pickupInstructionsPlaceholder.s)
                SaveatTextButton(title: S.Pro.saveScheduleCTA.s) {
                    proAccount.updateLocationDetails(
                        openingHours: openingHoursText,
                        pickupInstructions: pickupInstructionsText
                    )
                    Haptics.success()
                }
                .padding(.top, 2)
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(SaveatTypography.caption(11.5))
                .foregroundStyle(SaveatColors.textSecondary)
            TextField(placeholder, text: text)
                .font(SaveatTypography.body(14.5))
        }
    }

    // MARK: - Basket (§18-20)

    @ViewBuilder
    private var basketSection: some View {
        if let offer = proAccount.currentOffer {
            currentOfferCard(offer)
        } else if proAccount.location == nil {
            SaveatCard {
                Text(S.Pro.locationPendingNotice.s)
                    .font(SaveatTypography.body(14))
                    .foregroundStyle(SaveatColors.textSecondary)
            }
        } else {
            noOfferCard
        }
    }

    private func currentOfferCard(_ offer: BasketOffer) -> some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(S.Pro.currentOfferSectionTitle.s)
                        .font(SaveatTypography.caption(12))
                        .foregroundStyle(SaveatColors.textSecondary)
                    Spacer(minLength: 0)
                    SaveatBadge(text: offer.status.title, tone: .brand)
                }
                Text(offer.title)
                    .font(SaveatTypography.headline(17))
                    .foregroundStyle(SaveatColors.textPrimary)
                Text(pickupRangeText(offer))
                    .font(SaveatTypography.body(14))
                    .foregroundStyle(SaveatColors.textSecondary)
                Text(offer.quantityAvailable == 1
                     ? S.Pro.currentOfferQuantityRemaining.f(offer.quantityAvailable)
                     : S.Pro.currentOfferQuantityRemainingPlural.f(offer.quantityAvailable))
                    .font(SaveatTypography.caption(13))
                    .foregroundStyle(SaveatColors.brand)

                SaveatTextButton(title: S.Pro.currentOfferCancelCTA.s, tint: SaveatColors.alert) {
                    proAccount.cancelCurrentOffer()
                }
                .padding(.top, 4)
            }
        }
    }

    private var noOfferCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(S.Pro.noOfferTitle.s)
                    .font(SaveatTypography.headline(15))
                    .foregroundStyle(SaveatColors.textPrimary)
                Text(S.Pro.noOfferSubtitle.s)
                    .font(SaveatTypography.body(14))
                    .foregroundStyle(SaveatColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                SaveatPrimaryButton(title: S.Pro.createOfferCTA.s) {
                    showsCreateOffer = true
                }
                .padding(.top, 4)
            }
        }
    }

    private func pickupRangeText(_ offer: BasketOffer) -> String {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: offer.pickupStart)
        let endComponents = calendar.dateComponents([.hour, .minute], from: offer.pickupEnd)
        let start = Units.time(hour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0)
        let end = Units.time(hour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0)
        return "\(Units.weekdayDate(offer.pickupStart)) · \(start) – \(end)"
    }
}

#Preview {
    let store = ProAccountStore()
    return ProfessionalProfileView()
        .environment(store)
        .task {
            await store.createAccount(
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
        }
}
