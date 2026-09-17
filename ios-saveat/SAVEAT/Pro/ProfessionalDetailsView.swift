import SwiftUI

/// §13 of the SAVEAT PRO spec — only the fields SAVEAT actually needs from
/// the responsible person, once their establishment is confirmed.
///
/// No real, synced account is created here: SAVEAT has no backend yet (see
/// the Phase 1 audit — 100% local app, no server, no auth). What this screen
/// does instead is save the merchant and responsible-person records locally
/// via `ProAccountStore`, so `ProfessionalProfileView` has something real to
/// show afterward. `proAccountComingSoonNotice` says plainly that this stays
/// on-device only — the same honesty pattern already used for the
/// particulier account in `AccountOnboardingView`.
struct ProfessionalDetailsView: View {
    @Environment(ProAccountStore.self) private var proAccount
    let record: BusinessRegistryRecord
    var onDone: () -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(S.Pro.responsibleInfoTitle.s)
                        .font(SaveatTypography.title(22))
                        .foregroundStyle(SaveatColors.textPrimary)
                    Text(record.tradeName ?? record.legalName)
                        .font(SaveatTypography.body(15))
                        .foregroundStyle(SaveatColors.textSecondary)
                }

                SaveatCard {
                    VStack(spacing: 14) {
                        field(S.Pro.firstNameLabel.s, text: $firstName, contentType: .givenName)
                        Divider()
                        field(S.Pro.lastNameLabel.s, text: $lastName, contentType: .familyName)
                        Divider()
                        field(S.Pro.emailLabel.s, text: $email, contentType: .emailAddress, keyboard: .emailAddress)
                        Divider()
                        field(S.Pro.phoneLabel.s, text: $phone, contentType: .telephoneNumber, keyboard: .phonePad)
                    }
                }

                SaveatPrimaryButton(title: S.Pro.createProAccountCTA.s, isEnabled: canSubmit) {
                    proAccount.createAccount(
                        from: record,
                        firstName: firstName.trimmingCharacters(in: .whitespaces),
                        lastName: lastName.trimmingCharacters(in: .whitespaces),
                        email: email.trimmingCharacters(in: .whitespaces),
                        phone: phone.trimmingCharacters(in: .whitespaces)
                    )
                    onDone()
                }

                Text(S.Pro.proAccountComingSoonNotice.s)
                    .font(SaveatTypography.caption(11.5))
                    .foregroundStyle(SaveatColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(SaveatColors.background.ignoresSafeArea())
        .navigationTitle(S.Pro.responsibleInfoTitle.s)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canSubmit: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
            && email.contains("@")
    }

    private func field(
        _ label: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(SaveatTypography.caption(12))
                .foregroundStyle(SaveatColors.textSecondary)
            TextField("", text: text)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .font(SaveatTypography.body(15))
        }
    }
}

#Preview {
    NavigationStack {
        ProfessionalDetailsView(
            record: BusinessRegistryRecord(
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
            onDone: {}
        )
        .environment(ProAccountStore())
    }
}
