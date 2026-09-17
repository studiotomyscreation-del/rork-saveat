import SwiftUI
import RevenueCat
import RevenueCatUI

/// Entry point for every upsell in SAVEAT.
///
/// Uses the RevenueCat hosted Paywall when one is configured for the current
/// offering, and falls back to the native SAVEAT paywall otherwise so the app
/// always has a sellable screen (Test Store, offline, no remote paywall yet).
struct PaywallSheet: View {
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss

    var feature: PremiumFeature?

    var body: some View {
        Group {
            if let offering = subscriptions.remotePaywallOffering {
                RevenueCatUI.PaywallView(offering: offering, displayCloseButton: true)
                    .onPurchaseCompleted { (info: CustomerInfo) in
                        subscriptions.apply(info)
                        Haptics.success()
                    }
                    .onRestoreCompleted { (info: CustomerInfo) in
                        subscriptions.apply(info)
                    }
            } else {
                NativePaywallView(feature: feature)
            }
        }
        .onChange(of: subscriptions.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
    }
}

/// SAVEAT-branded paywall driven by the RevenueCat offering packages.
///
/// Layout follows the 17/09 design: a photographic kitchen hero carrying the
/// "Votre Chef au quotidien." promise, one white card with the five benefits,
/// the plan choices priced straight from the App Store, then the CTA, the
/// trust row and the legal block.
///
/// Every amount on this screen comes from `StoreProduct` — the monthly
/// equivalent and the yearly saving are computed from the two real store
/// prices, so France reads 1,99 € / 19,99 € while the US reads its own
/// dollar prices. No price is ever written into the app.
struct NativePaywallView: View {
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss

    var feature: PremiumFeature?

    @State private var selectedPackage: Package?

    private var packages: [Package] { subscriptions.packages }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                    .padding(.bottom, -46)

                VStack(spacing: 18) {
                    benefits
                    testerProof

                    if subscriptions.isLoadingOfferings && packages.isEmpty {
                        ProgressView().tint(SaveatColors.brand).padding(.vertical, 30)
                    } else if packages.isEmpty {
                        unavailableCard
                    } else {
                        planList
                        purchaseBlock
                    }

                    trustRow
                    legal
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .scrollIndicators(.hidden)
        .background(SaveatColors.ivory.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topTrailing) { closeButton }
        .task {
            // Always ask again when the sheet opens: the first attempt may have run
            // before StoreKit was ready, or while the device was offline.
            if packages.isEmpty { await subscriptions.loadOfferings() }
            selectedPackage = selectedPackage ?? preferredPackage
        }
        .onChange(of: packages.count) { _, _ in
            selectedPackage = selectedPackage ?? preferredPackage
        }
        .alert(S.Paywall.oops.s, isPresented: alertBinding(for: \.errorMessage)) {
            Button(S.Common.ok.s) { subscriptions.errorMessage = nil }
        } message: {
            Text(subscriptions.errorMessage ?? "")
        }
        .alert(S.Paywall.pendingPurchase.s, isPresented: alertBinding(for: \.pendingMessage)) {
            Button(S.Common.ok.s) { subscriptions.pendingMessage = nil }
        } message: {
            Text(subscriptions.pendingMessage ?? "")
        }
    }

    /// Annual is pre-selected when it exists (it is the plan marked as best
    /// value), matching the design; otherwise the first available package.
    private var preferredPackage: Package? {
        packages.first { $0.packageType == .annual } ?? packages.first
    }

    private func alertBinding(for keyPath: ReferenceWritableKeyPath<SubscriptionStore, String?>) -> Binding<Bool> {
        Binding(
            get: { subscriptions[keyPath: keyPath] != nil },
            set: { if !$0 { subscriptions[keyPath: keyPath] = nil } }
        )
    }

    // MARK: - Hero

    /// Photographic header. The image sits in an `.overlay` on top of a sized
    /// `Color` so a `.fill` crop can never widen the layout, and it is marked
    /// `allowsHitTesting(false)` so the close button above it stays tappable.
    private var hero: some View {
        Color(SaveatColors.ivory)
            .frame(height: 430)
            .overlay {
                Image("kitchen_counter_produce")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
            }
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, SaveatColors.ivory.opacity(0.7), SaveatColors.ivory],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topLeading) { heroCopy }
            .overlay(alignment: .topTrailing) { heroScript }
    }

    /// Handwritten-style promise from the design, tucked under the close
    /// button. Purely decorative, so it stays out of the accessibility tree.
    private var heroScript: some View {
        VStack(spacing: 4) {
            Text(S.Paywall.heroScript.s)
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .rotationEffect(.degrees(-7))
            Image(systemName: "heart")
                .font(.system(size: 15, weight: .medium))
        }
        .foregroundStyle(SaveatColors.forestDeep.opacity(0.85))
        .frame(maxWidth: 150)
        .padding(.trailing, 22)
        .padding(.top, 104)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(S.Paywall.badge.s)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(SaveatColors.forestDeep)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white.opacity(0.75), in: .capsule)

            Text(S.Paywall.heroTitleV2.s)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(SaveatColors.forestDeep)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)

            Capsule()
                .fill(SaveatColors.forestDeep.opacity(0.35))
                .frame(width: 46, height: 2)

            Text(heroSubtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(SaveatColors.forestDeep.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 260, alignment: .leading)
        .padding(.leading, 18)
        .padding(.top, 78)
    }

    /// The hero keeps the brand promise by default, and swaps to the reason the
    /// user hit the wall when a specific feature triggered it.
    private var heroSubtitle: String {
        guard let feature else { return S.Paywall.heroSubtitleV2.s }
        return upsellLine(for: feature)
    }

    private func upsellLine(for feature: PremiumFeature) -> String {
        switch feature {
        case .unlimitedScans: S.Paywall.upsellScans.s
        case .unlimitedAI: S.Paywall.upsellAI.s
        case .zeroEuroMode: S.Paywall.upsellZeroCost.s
        case .endOfMonth: S.Paywall.upsellEndOfMonth.s
        case .savingsStats: S.Paywall.upsellStats.s
        case .weeklyPlanning: S.Paywall.upsellWeeklyPlanning.s
        }
    }

    private var closeButton: some View {
        Button {
            Haptics.light()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(SaveatColors.forestDeep)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.92), in: .circle)
                .shadow(color: SaveatColors.nightBlue.opacity(0.12), radius: 8, y: 3)
        }
        .buttonStyle(SoftPressStyle())
        .padding(.trailing, 18)
        .padding(.top, 54)
        .accessibilityLabel(S.Common.close.s)
    }

    // MARK: - Benefits

    /// The five benefits, each one mapping to a screen that genuinely ships
    /// (recipes from stock, weekly plan + shopping list, stock & dates,
    /// expiry alerts, savings tracking) — never a promised feature.
    private var benefitItems: [(String, String, String)] {
        [
            ("fork.knife", S.Paywall.benefitChefTitle.s, S.Paywall.benefitChefBody.s),
            ("cart.fill", S.Paywall.benefitGroceriesTitle.s, S.Paywall.benefitGroceriesBody.s),
            ("refrigerator.fill", S.Paywall.benefitFridgeTitle.s, S.Paywall.benefitFridgeBody.s),
            ("leaf.fill", S.Paywall.benefitWasteTitle.s, S.Paywall.benefitWasteBody.s),
            ("chart.bar.fill", S.Paywall.benefitBudgetTitle.s, S.Paywall.benefitBudgetBody.s)
        ]
    }

    private var benefits: some View {
        VStack(spacing: 16) {
            ForEach(benefitItems, id: \.1) { benefit in
                HStack(spacing: 14) {
                    Image(systemName: benefit.0)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(SaveatColors.forestDeep)
                        .frame(width: 48, height: 48)
                        .background(SaveatColors.brand.opacity(0.13), in: .circle)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(benefit.1)
                            .font(.system(size: 16.5, weight: .bold, design: .rounded))
                            .foregroundStyle(SaveatColors.forestDeep)
                        Text(benefit.2)
                            .font(.system(size: 13.5, weight: .medium, design: .rounded))
                            .foregroundStyle(SaveatColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }

            HStack {
                Text(S.Paywall.benefitMapChip.s)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(SaveatColors.forestDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(SaveatColors.brand.opacity(0.13), in: .capsule)
                Spacer(minLength: 0)
            }
        }
        .saveatV2Card(padding: 20)
    }

    /// Observed result from our 10-person test group.
    ///
    /// Presented as an observation, never as a promise: the exact sentence and
    /// the disclaimer below it are fixed and inseparable, and this figure never
    /// touches anyone's personal savings statistics, which are always computed
    /// from real usage.
    private var testerProof: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(S.Paywall.testerProofTitle.s)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.clay)

            Text(S.Paywall.testerProof.s)
                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                .foregroundStyle(SaveatColors.forestDeep)
                .fixedSize(horizontal: false, vertical: true)

            Text(S.Paywall.testerProofDisclaimer.s)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(SaveatColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .saveatV2Card(padding: 18)
    }

    // MARK: - Plans

    private var planList: some View {
        VStack(spacing: 12) {
            ForEach(packages, id: \.identifier) { package in
                planRow(package)
            }
        }
    }

    private func planRow(_ package: Package) -> some View {
        let isSelected = selectedPackage?.identifier == package.identifier
        let isBest = package.packageType == .annual && packages.count > 1

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                selectedPackage = package
            }
            Haptics.light()
        } label: {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? SaveatColors.forestDeep : SaveatColors.forestDeep.opacity(0.25),
                                      lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Circle().fill(SaveatColors.forestDeep).frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(planTitle(package))
                            .font(.system(size: 17.5, weight: .bold, design: .rounded))
                            .foregroundStyle(SaveatColors.forestDeep)
                        if isBest {
                            Text(S.Paywall.bestValueV2.s)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(SaveatColors.forestDeep, in: .capsule)
                        }
                    }

                    ForEach(planSubtitleLines(package), id: \.self) { line in
                        Text(line)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(SaveatColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(subscriptions.priceLabel(for: package))
                        .font(.system(size: 21, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(SaveatColors.forestDeep)
                    if let suffix = periodSuffix(package) {
                        Text(suffix)
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(SaveatColors.textSecondary)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? SaveatColors.brand.opacity(0.08) : SaveatColors.surface,
                        in: .rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(isSelected ? SaveatColors.brand : SaveatColors.forestDeep.opacity(0.08),
                                  lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: SaveatColors.nightBlue.opacity(isSelected ? 0.07 : 0.04), radius: 10, y: 4)
            .contentShape(.rect)
        }
        .buttonStyle(SoftPressStyle())
        .accessibilityLabel("\(planTitle(package)), \(subscriptions.priceLabel(for: package))")
    }

    private func planTitle(_ package: Package) -> String {
        switch package.packageType {
        case .annual: S.Paywall.annual.s
        case .monthly: S.Paywall.monthly.s
        case .lifetime: S.Paywall.lifetime.s
        case .weekly: S.Paywall.weekly.s
        default: package.storeProduct.localizedTitle
        }
    }

    /// Billing period written under the price ("/ mois", "/ an").
    private func periodSuffix(_ package: Package) -> String? {
        switch package.packageType {
        case .annual: S.Paywall.perYearSuffix.s
        case .monthly: S.Paywall.perMonthSuffix.s
        case .weekly: S.Paywall.perWeekSuffix.s
        default: nil
        }
    }

    /// Up to two helper lines per plan: the free trial when Apple confirms this
    /// account is eligible, otherwise the monthly equivalent plus what a year
    /// actually saves — both derived from the real App Store prices.
    private func planSubtitleLines(_ package: Package) -> [String] {
        if let intro = package.storeProduct.introductoryDiscount, intro.price == 0,
           subscriptions.isEligibleForIntroOffer(package) {
            let value = intro.subscriptionPeriod.value
            let trial = "\(value) \(periodText(intro.subscriptionPeriod))"
            let price = subscriptions.priceLabel(for: package)
            return [value > 1
                ? S.Paywall.trialThenPlural.f(trial, price)
                : S.Paywall.trialThen.f(trial, price)]
        }

        switch package.packageType {
        case .annual:
            var lines: [String] = []
            if let monthly = subscriptions.monthlyEquivalentAmount(for: package) {
                lines.append(S.Paywall.monthlyEquivalentLine.f(monthly))
            }
            if let saved = subscriptions.annualSavings(for: package) {
                lines.append(S.Paywall.annualSavingsLine.f(saved))
            }
            return lines
        case .monthly:
            return [S.Paywall.monthlyNote.s]
        case .lifetime:
            return [S.Paywall.lifetimeNote.s]
        default:
            return []
        }
    }

    private func periodText(_ period: SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: period.value > 1 ? S.Paywall.days.s : S.Paywall.day.s
        case .week: period.value > 1 ? S.Paywall.weeks.s : S.Paywall.week.s
        case .month: S.Paywall.months.s
        case .year: period.value > 1 ? S.Paywall.years.s : S.Paywall.year.s
        }
    }

    private var unavailableCard: some View {
        VStack(spacing: 12) {
            Text("😕").font(.system(size: 34))
            Text(S.Paywall.unavailableTitle.s)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(SaveatColors.forestDeep)
            Text(subscriptions.unavailableReason)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(SaveatColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Haptics.light()
                Task { await subscriptions.loadOfferings() }
            } label: {
                if subscriptions.isLoadingOfferings {
                    ProgressView().tint(SaveatColors.brand)
                } else {
                    Text(S.Common.retry.s)
                }
            }
            .buttonStyle(SaveatButtonStyle(tint: SaveatColors.brand, isProminent: false))
            .disabled(subscriptions.isLoadingOfferings)
        }
        .saveatV2Card(padding: 22)
    }

    // MARK: - Purchase

    private var purchaseBlock: some View {
        VStack(spacing: 14) {
            Button {
                guard let package = selectedPackage else { return }
                Haptics.soft()
                Task { await subscriptions.purchase(package) }
            } label: {
                HStack(spacing: 10) {
                    Spacer(minLength: 0)
                    if subscriptions.isPurchasing {
                        ProgressView().tint(.white)
                    }
                    Text(ctaTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(SaveatColors.forestDeep, in: .capsule)
                .opacity(selectedPackage == nil ? 0.5 : 1)
            }
            .buttonStyle(SoftPressStyle())
            .disabled(selectedPackage == nil || subscriptions.isPurchasing)

            HStack(spacing: 0) {
                Button(S.Paywall.continueFree.s) { dismiss() }
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(SaveatColors.forestDeep.opacity(0.15))
                    .frame(width: 1, height: 20)

                Button {
                    Task { await subscriptions.restore() }
                } label: {
                    if subscriptions.isRestoring {
                        ProgressView().tint(SaveatColors.textSecondary)
                    } else {
                        Text(S.Paywall.restore.s)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            .foregroundStyle(SaveatColors.textSecondary)
            .frame(minHeight: 44)
        }
        .padding(.top, 4)
    }

    private var ctaTitle: String {
        guard let package = selectedPackage else { return S.Paywall.subscribeCTA.s }
        if let intro = package.storeProduct.introductoryDiscount, intro.price == 0,
           subscriptions.isEligibleForIntroOffer(package) {
            return S.Paywall.trialCTA.s
        }
        return S.Paywall.subscribeCTA.s
    }

    // MARK: - Trust & legal

    private var trustRow: some View {
        HStack(alignment: .top, spacing: 10) {
            trustItem("lock.fill", S.Paywall.trustSecure.s)
            trustItem("applelogo", S.Paywall.trustAppStore.s)
            trustItem("checkmark.shield.fill", S.Paywall.trustCancel.s)
        }
        .padding(.top, 2)
    }

    private func trustItem(_ icon: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SaveatColors.forestDeep)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(SaveatColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var legal: some View {
        VStack(spacing: 10) {
            Text(S.Paywall.renewalTermsV2.s)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(SaveatColors.textSecondary.opacity(0.9))

            Text(consentText)
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(SaveatColors.textSecondary)
                .tint(SaveatColors.forestDeep)

            Text(S.Paywall.estimatesNote.s)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(SaveatColors.textSecondary.opacity(0.75))
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 2)
    }

    /// Terms and Privacy as inline links inside the consent sentence, so the
    /// App Store required destinations stay one tap away.
    private var consentText: AttributedString {
        let markdown = S.Paywall.consentMarkdown.f(
            SaveatInfo.termsURL.absoluteString,
            SaveatInfo.privacyURL.absoluteString
        )
        return (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }
}

/// RevenueCat Customer Center: cancellations, refunds, plan changes, billing issues.
struct ManageSubscriptionSheet: View {
    @Environment(SubscriptionStore.self) private var subscriptions

    var body: some View {
        CustomerCenterView()
            .onDisappear {
                Task { await subscriptions.refreshCustomerInfo() }
            }
    }
}

/// Reusable premium lock used to gate a feature inline.
struct PremiumLockCard: View {
    let feature: PremiumFeature
    var message: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        LinearGradient(colors: [Theme.sage, Theme.sageDeep],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: .circle
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text(feature.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(message)
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.sageDeep)
            }
            .saveatCard(padding: 16)
            .contentShape(.rect)
        }
        .buttonStyle(SoftPressStyle())
    }
}
