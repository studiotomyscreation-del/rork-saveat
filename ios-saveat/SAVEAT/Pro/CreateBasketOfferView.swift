import SwiftUI

/// §18-20 of the SAVEAT PRO spec — a professional publishes one basket at
/// their own shop front.
///
/// Presented from `ProfessionalProfileView` once a `MerchantLocation` exists.
/// Saved through `ProAccountStore.publishOffer`, which is honest that this
/// only ever shows up on **this device's own map** — see that method's doc
/// comment and `basketFormLocalOnlyNotice` below.
struct CreateBasketOfferView: View {
    @Environment(ProAccountStore.self) private var proAccount
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var basketType: BasketType = .surprise
    @State private var originalPriceText = ""
    @State private var discountedPriceText = ""
    @State private var quantity = 1
    @State private var pickupStart = Self.defaultPickupStart
    @State private var pickupEnd = Self.defaultPickupEnd
    @State private var dietaryInformation: Set<DietaryClaim> = []

    private static var defaultPickupStart: Date {
        Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now
    }

    private static var defaultPickupEnd: Date {
        Calendar.current.date(byAdding: .hour, value: 3, to: .now) ?? .now
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if proAccount.location == nil {
                        locationPendingNotice
                    }

                    basketDetailsCard
                    priceCard
                    pickupCard
                    dietaryCard

                    SaveatPrimaryButton(title: S.Pro.basketFormPublishCTA.s, isEnabled: canPublish) {
                        publish()
                    }

                    Text(S.Pro.basketFormLocalOnlyNotice.s)
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
            .navigationTitle(S.Pro.basketFormTitle.s)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(S.Common.close.s) { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var locationPendingNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "location.slash.fill")
                .foregroundStyle(SaveatBadgeTone.alert.foreground)
            Text(S.Pro.locationPendingNotice.s)
                .font(SaveatTypography.caption(12.5))
                .foregroundStyle(SaveatBadgeTone.alert.foreground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(SaveatBadgeTone.alert.background, in: .rect(cornerRadius: Theme.cardRadius))
    }

    private var basketDetailsCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 14) {
                field(S.Pro.basketFormTitleLabel.s, text: $title, placeholder: S.Pro.basketFormTitlePlaceholder.s)
                Divider()
                field(S.Pro.basketFormDescriptionLabel.s, text: $description, placeholder: S.Pro.basketFormDescriptionPlaceholder.s)
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text(S.Pro.basketFormTypeLabel.s)
                        .font(SaveatTypography.caption(12))
                        .foregroundStyle(SaveatColors.textSecondary)
                    Picker(S.Pro.basketFormTypeLabel.s, selection: $basketType) {
                        Text(BasketType.surprise.title).tag(BasketType.surprise)
                        Text(BasketType.detailed.title).tag(BasketType.detailed)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var priceCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    priceField(S.Pro.basketFormOriginalPriceLabel.s, text: $originalPriceText)
                    priceField(S.Pro.basketFormDiscountedPriceLabel.s, text: $discountedPriceText)
                }
                Divider()
                Stepper(value: $quantity, in: 1...50) {
                    HStack {
                        Text(S.Pro.basketFormQuantityLabel.s)
                            .font(SaveatTypography.body(15))
                            .foregroundStyle(SaveatColors.textPrimary)
                        Spacer(minLength: 0)
                        Text("\(quantity)")
                            .font(SaveatTypography.headline(15))
                            .foregroundStyle(SaveatColors.brand)
                    }
                }
            }
        }
    }

    private var pickupCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(text: S.Pro.basketFormPickupLabel.s, color: SaveatColors.forestDeep)
                DatePicker(S.Pro.basketFormPickupStartLabel.s, selection: $pickupStart, displayedComponents: [.date, .hourAndMinute])
                Divider()
                DatePicker(S.Pro.basketFormPickupEndLabel.s, selection: $pickupEnd, displayedComponents: [.date, .hourAndMinute])
            }
        }
    }

    private var dietaryCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: S.Pro.basketFormDietaryLabel.s, color: SaveatColors.forestDeep)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(DietaryClaim.allCases) { claim in
                        dietaryChip(claim)
                    }
                }
            }
        }
    }

    private func dietaryChip(_ claim: DietaryClaim) -> some View {
        let isSelected = dietaryInformation.contains(claim)
        return Button {
            Haptics.light()
            if isSelected { dietaryInformation.remove(claim) } else { dietaryInformation.insert(claim) }
        } label: {
            Text(claim.title)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? SaveatColors.textOnDark : SaveatColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? SaveatColors.brand : SaveatColors.surface, in: .capsule)
                .overlay {
                    Capsule().stroke(isSelected ? .clear : SaveatColors.textSecondary.opacity(0.2), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(SaveatTypography.caption(12))
                .foregroundStyle(SaveatColors.textSecondary)
            TextField(placeholder, text: text)
                .font(SaveatTypography.body(15))
        }
    }

    private func priceField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(SaveatTypography.caption(12))
                .foregroundStyle(SaveatColors.textSecondary)
            HStack(spacing: 4) {
                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .font(SaveatTypography.numeric(17))
                Text(Money.symbol)
                    .font(SaveatTypography.body(15))
                    .foregroundStyle(SaveatColors.textSecondary)
            }
        }
    }

    // MARK: - Validation & submit

    private var originalPrice: Double? {
        Double(originalPriceText.replacingOccurrences(of: ",", with: "."))
    }

    private var discountedPrice: Double? {
        Double(discountedPriceText.replacingOccurrences(of: ",", with: "."))
    }

    private var canPublish: Bool {
        guard proAccount.location != nil else { return false }
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let originalPrice, originalPrice > 0 else { return false }
        guard let discountedPrice, discountedPrice > 0, discountedPrice < originalPrice else { return false }
        guard pickupEnd > pickupStart else { return false }
        return true
    }

    private func publish() {
        guard let originalPrice, let discountedPrice else { return }
        proAccount.publishOffer(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            basketType: basketType,
            originalPrice: originalPrice,
            discountedPrice: discountedPrice,
            quantity: quantity,
            pickupStart: pickupStart,
            pickupEnd: pickupEnd,
            dietaryInformation: Array(dietaryInformation)
        )
        Haptics.success()
        dismiss()
    }
}

#Preview {
    let store = ProAccountStore()
    return CreateBasketOfferView()
        .environment(store)
}
