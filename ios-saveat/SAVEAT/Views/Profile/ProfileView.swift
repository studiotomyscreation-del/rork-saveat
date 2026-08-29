import SwiftUI

/// Profile hub: household summary, impact shortcut, challenges, settings.
struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(SubscriptionStore.self) private var subscriptions
    @Binding var path: NavigationPath

    @State private var showsPaywall = false
    @State private var showsCustomerCenter = false
    @State private var isRunningSelfTest = false
    @State private var selfTestSummary: String?

    private var impact: ImpactSummary { store.lifetimeImpact }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                subscriptionCard
                testStoreDiagnostics
                savingsCard
                menuSection
                promise
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .sheet(isPresented: $showsPaywall) { PaywallSheet() }
        .sheet(isPresented: $showsCustomerCenter) { ManageSubscriptionSheet() }
        .task { await subscriptions.refreshCustomerInfo() }
    }

    // MARK: Premium

    /// Developer-only card: shown in Debug builds (to verify the App Store offering,
    /// prices and entitlement while testing) and, in TestFlight / App Store builds,
    /// only when RevenueCat failed to configure. Invisible to real users otherwise.
    @ViewBuilder
    private var testStoreDiagnostics: some View {
        let isTestStore = subscriptions.environment.isTestStore
        let hasIssue = PurchasesBootstrap.configurationIssue != nil

        // Temporary: also shown in TestFlight when the offering exposes no package,
        // so the exact StoreKit/RevenueCat reason is reachable on a real device.
        if PurchasesBootstrap.showsDiagnostics || subscriptions.packages.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: hasIssue ? "exclamationmark.triangle.fill" : "testtube.2")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.terracotta)
                    Text(hasIssue ? "ACHATS INDISPONIBLES" : "DIAGNOSTIC REVENUECAT")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(Theme.terracotta)
                    Spacer(minLength: 0)
                }

                ForEach(subscriptions.diagnostics, id: \.0) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Text(line.0)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                        Spacer(minLength: 8)
                        Text(line.1)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let selfTestSummary {
                    Text(selfTestSummary)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                Button {
                    Task { await subscriptions.runStoreKitProbe() }
                } label: {
                    if subscriptions.isProbingStoreKit {
                        ProgressView().tint(Theme.inkSoft)
                    } else {
                        Text("Diagnostic StoreKit")
                    }
                }
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.terracotta)
                .disabled(subscriptions.isProbingStoreKit)
                .frame(minHeight: 44)

                if let report = subscriptions.storeKitReport {
                    Text(report)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.creamDeep, in: .rect(cornerRadius: 12))
                } else if let detail = subscriptions.lastOfferingsErrorDetail {
                    Text(detail)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }

                if !hasIssue {
                    HStack(spacing: 14) {
                        Button("Recharger") {
                            Task {
                                await subscriptions.loadOfferings()
                                await subscriptions.refreshCustomerInfo()
                            }
                        }
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.sageDeep)

                        Button("Ouvrir le paywall") {
                            showsPaywall = true
                        }
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.sageDeep)

                        // Test Store only: this self-test drives its own purchase sheet.
                        if isTestStore {
                            Button {
                                Task {
                                    isRunningSelfTest = true
                                    selfTestSummary = await SubscriptionSelfTest.run(store: subscriptions)
                                    isRunningSelfTest = false
                                }
                            } label: {
                                if isRunningSelfTest {
                                    ProgressView().tint(Theme.inkSoft)
                                } else {
                                    Text("Auto-test")
                                }
                            }
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.sageDeep)
                            .disabled(isRunningSelfTest)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: 44)
                }
            }
            .saveatCard(padding: 16)
        }
    }

    @ViewBuilder
    private var subscriptionCard: some View {
        if subscriptions.isPremium {
            premiumStatusCard
        } else {
            upsellCard
        }
    }

    private var premiumStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: subscriptions.status.needsAttention ? "exclamationmark.circle.fill" : "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(subscriptions.status.needsAttention ? Theme.clay : Theme.sageDeep)
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscriptions.status.headline)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(subscriptions.status.detail)
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Button("Gérer mon abonnement") {
                Haptics.light()
                showsCustomerCenter = true
            }
            .buttonStyle(SaveatButtonStyle(tint: Theme.sageDeep, isProminent: false))
        }
        .saveatCard()
    }

    private var upsellCard: some View {
        Button {
            Haptics.soft()
            showsPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("SAVEAT PREMIUM")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Text("Fais économiser encore plus à ton frigo.")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Text("Scans illimités • IA cuisine illimitée • mode 0 € • fin de mois")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text("Voir les offres")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.sageDeep)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(.white, in: .capsule)
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                LinearGradient(colors: [Theme.sageDeep, Theme.ink],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .rect(cornerRadius: Theme.cardRadius)
            )
            .shadow(color: Theme.ink.opacity(0.22), radius: 14, y: 5)
            .contentShape(.rect)
        }
        .buttonStyle(SoftPressStyle())
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Theme.sageMist).frame(width: 62, height: 62)
                Text(store.profile.goal.emoji).font(.system(size: 26))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Mon foyer")
                    .font(Theme.title(19))
                    .foregroundStyle(Theme.ink)
                Text(store.profile.householdText)
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.inkSoft)
                SoftPill(text: store.profile.goal.title, tint: Theme.sageDeep, background: Theme.sageMist)
            }
            Spacer(minLength: 0)
        }
        .saveatCard()
        .padding(.top, 8)
    }

    private var savingsCard: some View {
        Button {
            path.append(Route.impact)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text("Depuis mon inscription")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.85))
                HStack(alignment: .firstTextBaseline) {
                    Text(Format.euro(impact.moneySaved))
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Text("économisés • \(impact.savedItems) produits sauvés — estimations")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                LinearGradient(colors: [Theme.sage, Theme.sageDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .rect(cornerRadius: Theme.cardRadius)
            )
            .shadow(color: Theme.sageDeep.opacity(0.22), radius: 14, y: 5)
        }
        .buttonStyle(SoftPressStyle())
    }

    private var menuSection: some View {
        VStack(spacing: 0) {
            menuRow(emoji: "🏅", title: "Défis Zéro Gaspi",
                    subtitle: "\(store.challenges.filter(\.isDone).count) missions accomplies",
                    route: .challenges)
            Divider().padding(.leading, 66)
            menuRow(emoji: "🛒", title: "Courses intelligentes",
                    subtitle: "\(store.shoppingList.count) articles à acheter",
                    route: .shopping)
            Divider().padding(.leading, 66)
            menuRow(emoji: "💶", title: "Fin de mois",
                    subtitle: "Optimise ton budget alimentaire",
                    route: .endOfMonth)
            Divider().padding(.leading, 66)
            menuRow(emoji: "⚙️", title: "Préférences du foyer",
                    subtitle: "Régime, allergies, budget",
                    route: .settings)
        }
        .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
    }

    private func menuRow(emoji: String, title: String, subtitle: String, route: Route) -> some View {
        Button {
            path.append(route)
        } label: {
            HStack(spacing: 14) {
                FoodBadge(emoji: emoji, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(.rect)
        }
        .buttonStyle(SoftPressStyle())
    }

    private var promise: some View {
        VStack(spacing: 6) {
            Text("SAVEAT")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(4)
                .foregroundStyle(Theme.sageDeep)
            Text("Scanne tes courses. Cuisine ton stock. Jette moins.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

/// Household preferences, editable after onboarding.
struct SettingsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Adultes").font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                        QuantityStepper(value: $store.profile.adults, range: 1...10)
                    }
                    .padding(16)
                    Divider()
                    HStack {
                        Text("Enfants").font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                        QuantityStepper(value: $store.profile.children, range: 0...10)
                    }
                    .padding(16)
                    Divider()
                    HStack {
                        Text("Objectif").font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                        Picker("", selection: $store.profile.goal) {
                            ForEach(HouseholdGoal.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.menu).tint(Theme.sageDeep)
                    }
                    .padding(16)
                    Divider()
                    HStack {
                        Text("Régime").font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                        Picker("", selection: $store.profile.diet) {
                            ForEach(DietPreference.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.menu).tint(Theme.sageDeep)
                    }
                    .padding(16)
                }
                .foregroundStyle(Theme.ink)
                .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: "Budget courses hebdomadaire")
                    Text(Format.euro(store.profile.weeklyBudget, decimals: 0))
                        .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.sageDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.sageMist, in: .rect(cornerRadius: 18))
                    Slider(value: $store.profile.weeklyBudget, in: 20...250, step: 5)
                        .tint(Theme.sage)
                }
                .saveatCard()

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: "Allergies")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                        ForEach(Allergen.allCases) { allergen in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    if store.profile.allergens.contains(allergen) {
                                        store.profile.allergens.remove(allergen)
                                    } else {
                                        store.profile.allergens.insert(allergen)
                                    }
                                }
                                Haptics.light()
                            } label: {
                                Text(allergen.title)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(store.profile.allergens.contains(allergen) ? .white : Theme.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(store.profile.allergens.contains(allergen) ? Theme.sage : Theme.creamDeep,
                                                in: .capsule)
                            }
                            .buttonStyle(SoftPressStyle())
                        }
                    }
                }
                .saveatCard()

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: "Je ne mange pas")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                        ForEach(DislikeCatalog.all, id: \.self) { food in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    if store.profile.dislikes.contains(food) {
                                        store.profile.dislikes.remove(food)
                                    } else {
                                        store.profile.dislikes.insert(food)
                                    }
                                }
                                Haptics.light()
                            } label: {
                                Text(food)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(store.profile.dislikes.contains(food) ? .white : Theme.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(store.profile.dislikes.contains(food) ? Theme.sage : Theme.creamDeep,
                                                in: .capsule)
                            }
                            .buttonStyle(SoftPressStyle())
                        }
                    }
                }
                .saveatCard()

                Button("Refaire l'introduction") {
                    store.resetOnboarding()
                    Haptics.light()
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle("Préférences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
