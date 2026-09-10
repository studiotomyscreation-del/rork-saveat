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
struct NativePaywallView: View {
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss

    var feature: PremiumFeature?

    @State private var selectedPackage: Package?

    private var packages: [Package] { subscriptions.packages }

    var body: some View {
        ZStack {
            backdrop

            ScrollView {
                VStack(spacing: 22) {
                    hero
                    benefits
                    if subscriptions.isLoadingOfferings && packages.isEmpty {
                        ProgressView().tint(Theme.sageDeep).padding(.vertical, 30)
                    } else if packages.isEmpty {
                        unavailableCard
                    } else {
                        planList
                    }
                    legal
                }
                .padding(.horizontal, Theme.hMargin)
                .padding(.top, 8)
                .padding(.bottom, 190)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) { purchaseBar }
        .overlay(alignment: .topTrailing) { closeButton }
        .task {
            // Always ask again when the sheet opens: the first attempt may have run
            // before StoreKit was ready, or while the device was offline.
            if packages.isEmpty { await subscriptions.loadOfferings() }
            selectedPackage = selectedPackage ?? packages.first
        }
        .onChange(of: packages.count) { _, _ in
            selectedPackage = selectedPackage ?? packages.first
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

    private func alertBinding(for keyPath: ReferenceWritableKeyPath<SubscriptionStore, String?>) -> Binding<Bool> {
        Binding(
            get: { subscriptions[keyPath: keyPath] != nil },
            set: { if !$0 { subscriptions[keyPath: keyPath] = nil } }
        )
    }

    private var backdrop: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            Circle()
                .fill(Theme.sage.opacity(0.28))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -120, y: -260)
            Circle()
                .fill(Theme.terracotta.opacity(0.22))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: 150, y: 120)
        }
        .ignoresSafeArea()
    }

    private var closeButton: some View {
        Button {
            Haptics.light()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 32, height: 32)
                .background(Theme.surface, in: .circle)
        }
        .buttonStyle(SoftPressStyle())
        .padding(.trailing, Theme.hMargin)
        .padding(.top, 10)
        .accessibilityLabel(S.Common.close.s)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Text(S.Paywall.badge.s)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(Theme.sageDeep)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Theme.sageMist, in: .capsule)

            Text(S.Paywall.title.s)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let feature {
                Text(upsellLine(for: feature))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(S.Paywall.subtitle.s)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 34)
    }

    private func upsellLine(for feature: PremiumFeature) -> String {
        switch feature {
        case .unlimitedScans: S.Paywall.upsellScans.s
        case .unlimitedAI: S.Paywall.upsellAI.s
        case .zeroEuroMode: S.Paywall.upsellZeroCost.s
        case .endOfMonth: S.Paywall.upsellEndOfMonth.s
        case .savingsStats: S.Paywall.upsellStats.s
        }
    }

    private var perks: [(String, String, String)] {
        [
            ("barcode.viewfinder", S.Paywall.perkScansTitle.s, S.Paywall.perkScansBody.s),
            ("sparkles", S.Paywall.perkAITitle.s, S.Paywall.perkAIBody.s),
            ("tag.circle.fill", S.Paywall.perkZeroTitle.s, S.Paywall.perkZeroBody.s),
            ("calendar.badge.clock", S.Paywall.perkBudgetTitle.s, S.Paywall.perkBudgetBody.s),
            ("chart.line.uptrend.xyaxis", S.Paywall.perkStatsTitle.s, S.Paywall.perkStatsBody.s),
            ("bell.badge.fill", S.Paywall.perkAlertsTitle.s, S.Paywall.perkAlertsBody.s)
        ]
    }

    private var benefits: some View {
        VStack(spacing: 14) {
            ForEach(perks, id: \.1) { perk in
                HStack(spacing: 13) {
                    Image(systemName: perk.0)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.sageDeep)
                        .frame(width: 38, height: 38)
                        .background(Theme.sageMist, in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(perk.1)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text(perk.2)
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .saveatCard(padding: 18)
    }

    private var planList: some View {
        VStack(spacing: 12) {
            ForEach(packages, id: \.identifier) { package in
                planRow(package)
            }
        }
    }

    private func planRow(_ package: Package) -> some View {
        let isSelected = selectedPackage?.identifier == package.identifier
        let isBest = package.packageType == .annual

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                selectedPackage = package
            }
            Haptics.light()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Theme.sageDeep : Theme.inkSoft.opacity(0.35), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle().fill(Theme.sageDeep).frame(width: 13, height: 13)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(planTitle(package))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        if isBest {
                            Text(S.Paywall.bestValue.s)
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.terracotta, in: .capsule)
                        }
                    }
                    if let subtitle = planSubtitle(package) {
                        Text(subtitle)
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }

                Spacer(minLength: 0)

                Text(subscriptions.priceLabel(for: package))
                    .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.ink)
            }
            .padding(16)
            .background(Theme.surface, in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isSelected ? Theme.sageDeep : Color.clear, lineWidth: 2)
            }
            .shadow(color: Theme.ink.opacity(isSelected ? 0.09 : 0.04), radius: 10, y: 4)
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

    private func planSubtitle(_ package: Package) -> String? {
        if let intro = package.storeProduct.introductoryDiscount, intro.price == 0 {
            let value = intro.subscriptionPeriod.value
            let trial = "\(value) \(periodText(intro.subscriptionPeriod))"
            let price = subscriptions.priceLabel(for: package)
            return value > 1
                ? S.Paywall.trialThenPlural.f(trial, price)
                : S.Paywall.trialThen.f(trial, price)
        }
        if let monthly = subscriptions.monthlyEquivalent(for: package) {
            return S.Paywall.billedYearly.f(monthly)
        }
        if package.packageType == .lifetime {
            return S.Paywall.lifetimeNote.s
        }
        if package.packageType == .monthly {
            return S.Paywall.monthlyNote.s
        }
        return nil
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
                .font(Theme.title(18))
                .foregroundStyle(Theme.ink)
            Text(subscriptions.unavailableReason)
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Haptics.light()
                Task { await subscriptions.loadOfferings() }
            } label: {
                if subscriptions.isLoadingOfferings {
                    ProgressView().tint(Theme.sageDeep)
                } else {
                    Text(S.Common.retry.s)
                }
            }
            .buttonStyle(SaveatButtonStyle(tint: Theme.sage, isProminent: false))
            .disabled(subscriptions.isLoadingOfferings)
        }
        .saveatCard(padding: 22)
    }

    private var purchaseBar: some View {
        VStack(spacing: 10) {
            Button {
                guard let package = selectedPackage else { return }
                Haptics.soft()
                Task { await subscriptions.purchase(package) }
            } label: {
                HStack(spacing: 8) {
                    if subscriptions.isPurchasing {
                        ProgressView().tint(.white)
                    }
                    Text(ctaTitle)
                }
            }
            .buttonStyle(SaveatButtonStyle(tint: Theme.sageDeep))
            .disabled(selectedPackage == nil || subscriptions.isPurchasing)

            HStack(spacing: 18) {
                Button(S.Paywall.continueFree.s) { dismiss() }
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)

                Button {
                    Task { await subscriptions.restore() }
                } label: {
                    if subscriptions.isRestoring {
                        ProgressView().tint(Theme.inkSoft)
                    } else {
                        Text(S.Paywall.restore.s)
                    }
                }
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
            }
            .frame(minHeight: 44)
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    private var ctaTitle: String {
        guard let package = selectedPackage else { return S.Paywall.subscribeCTA.s }
        if let intro = package.storeProduct.introductoryDiscount, intro.price == 0 {
            return S.Paywall.trialCTA.s
        }
        return S.Paywall.subscribeCTA.s
    }

    private var legal: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Link(S.Profile.terms.s, destination: SaveatInfo.termsURL)
                Text("·")
                Link(S.Profile.privacy.s, destination: SaveatInfo.privacyURL)
            }
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.sageDeep)
            .multilineTextAlignment(.center)
            .frame(minHeight: 44)

            Text(S.Paywall.renewalTerms.s)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(S.Paywall.estimatesNote.s)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
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
