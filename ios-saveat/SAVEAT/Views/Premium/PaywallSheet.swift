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
        .alert("Oups", isPresented: alertBinding(for: \.errorMessage)) {
            Button("OK") { subscriptions.errorMessage = nil }
        } message: {
            Text(subscriptions.errorMessage ?? "")
        }
        .alert("Achat en attente", isPresented: alertBinding(for: \.pendingMessage)) {
            Button("OK") { subscriptions.pendingMessage = nil }
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
        .accessibilityLabel("Fermer")
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Text("SAVEAT PREMIUM")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(Theme.sageDeep)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Theme.sageMist, in: .capsule)

            Text("Fais économiser encore plus à ton frigo.")
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
                Text("Scanne sans limite, cuisine avec l'IA et suis tes économies mois après mois.")
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
        case .unlimitedScans: "Tu as atteint tes scans gratuits du jour. Passe en illimité pour finir tes courses."
        case .unlimitedAI: "Tu as utilisé tes suggestions IA du jour. Débloque l'IA cuisine illimitée."
        case .zeroEuroMode: "Le mode 0 € trouve des repas complets sans rien acheter."
        case .endOfMonth: "Le mode fin de mois étire ton budget jusqu'au dernier jour."
        case .savingsStats: "Suis précisément l'argent que tu ne jettes plus."
        }
    }

    private let perks: [(String, String, String)] = [
        ("barcode.viewfinder", "Scans illimités", "Scanne toutes tes courses d'un coup, sans compteur."),
        ("sparkles", "IA cuisine illimitée", "Des recettes générées à partir de ton stock réel."),
        ("eurosign.circle.fill", "Mode 0 €", "Des repas complets sans dépenser un centime."),
        ("calendar.badge.clock", "Mode fin de mois", "Un plan repas qui tient jusqu'au dernier jour."),
        ("chart.line.uptrend.xyaxis", "Stats d'économies", "Estimation de ce que tu ne jettes plus."),
        ("bell.badge.fill", "Alertes produits à sauver", "Prévenu avant que ça se perde.")
    ]

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
                            Text("⭐ Meilleure offre")
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

                Text(package.storeProduct.localizedPriceString)
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
        .accessibilityLabel("\(planTitle(package)), \(package.storeProduct.localizedPriceString)")
    }

    private func planTitle(_ package: Package) -> String {
        switch package.packageType {
        case .annual: "Annuel"
        case .monthly: "Mensuel"
        case .lifetime: "À vie"
        case .weekly: "Hebdomadaire"
        default: package.storeProduct.localizedTitle
        }
    }

    private func planSubtitle(_ package: Package) -> String? {
        if let intro = package.storeProduct.introductoryDiscount, intro.price == 0 {
            let unit = periodText(intro.subscriptionPeriod)
            return "\(intro.subscriptionPeriod.value) \(unit) offert\(intro.subscriptionPeriod.value > 1 ? "s" : "") puis \(package.storeProduct.localizedPriceString)"
        }
        if let monthly = subscriptions.monthlyEquivalent(for: package) {
            return "\(monthly) • facturé une fois par an"
        }
        if package.packageType == .lifetime {
            return "Paiement unique, accès définitif"
        }
        if package.packageType == .monthly {
            return "Sans engagement, résiliable à tout moment"
        }
        return nil
    }

    private func periodText(_ period: SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: period.value > 1 ? "jours" : "jour"
        case .week: period.value > 1 ? "semaines" : "semaine"
        case .month: "mois"
        case .year: period.value > 1 ? "ans" : "an"
        }
    }

    private var unavailableCard: some View {
        VStack(spacing: 12) {
            Text("😕").font(.system(size: 34))
            Text("Offres indisponibles")
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
                    Text("Réessayer")
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
                Button("Continuer gratuitement") { dismiss() }
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)

                Button {
                    Task { await subscriptions.restore() }
                } label: {
                    if subscriptions.isRestoring {
                        ProgressView().tint(Theme.inkSoft)
                    } else {
                        Text("Restaurer mes achats")
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
        guard let package = selectedPackage else { return "Passer à SAVEAT Premium" }
        if let intro = package.storeProduct.introductoryDiscount, intro.price == 0 {
            return "Commencer l'essai gratuit"
        }
        return "Passer à SAVEAT Premium"
    }

    private var legal: some View {
        VStack(spacing: 6) {
            Text("Paiement via ton compte Apple. L'abonnement se renouvelle automatiquement sauf résiliation au moins 24 h avant la fin de la période. Tu peux gérer ou résilier à tout moment dans les réglages de l'App Store.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Toutes les économies affichées dans SAVEAT sont des estimations.")
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
