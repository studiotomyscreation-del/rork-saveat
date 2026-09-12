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
                SaveatLocalCard()
                legalSection
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

    /// Developer-only card: shown only while something looks wrong with the
    /// purchase stack (configuration issue or no package exposed), so the exact
    /// StoreKit/RevenueCat reason is never invisible. Hidden once the offering
    /// loads, keeping everyday screens — screenshots included — clean.
    @ViewBuilder
    private var testStoreDiagnostics: some View {
        let isTestStore = subscriptions.environment.isTestStore
        let hasIssue = PurchasesBootstrap.configurationIssue != nil

        if hasIssue || subscriptions.packages.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: hasIssue ? "exclamationmark.triangle.fill" : "testtube.2")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.terracotta)
                    Text(hasIssue ? S.Diagnostics.purchasesUnavailable.s : S.Diagnostics.revenueCat.s)
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
                        Text(S.Diagnostics.storeKitProbe.s)
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
                        Button(S.Diagnostics.reload.s) {
                            Task {
                                await subscriptions.loadOfferings()
                                await subscriptions.refreshCustomerInfo()
                            }
                        }
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.sageDeep)

                        Button(S.Diagnostics.openPaywall.s) {
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
                                    Text(S.Diagnostics.selfTest.s)
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

            Button(S.Profile.manageSubscription.s) {
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
                    Text(S.Profile.premiumBadge.s)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Text(S.Profile.upsellTitle.s)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Text(S.Profile.upsellFeatures.s)
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text(S.Profile.seeOffers.s)
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
            BrandMark(size: 62)

            VStack(alignment: .leading, spacing: 3) {
                Text(S.Profile.household.s)
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
                Text(S.Profile.sinceJoining.s)
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
                Text(S.Profile.savedSummary.f(impact.savedItems))
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

    /// Follows the wallet the user actually pays with, not the language.
    private static var budgetEmoji: String {
        switch Money.code {
        case "EUR": "💶"
        case "GBP": "💷"
        case "CNY", "JPY": "💴"
        default: "💵"
        }
    }

    private var menuSection: some View {
        VStack(spacing: 0) {
            menuRow(emoji: "🏅", title: S.Profile.challenges.s,
                    subtitle: S.Profile.challengesSubtitle.f(store.challenges.filter(\.isDone).count),
                    route: .challenges)
            Divider().padding(.leading, 66)
            menuRow(emoji: "🛒", title: S.Shopping.navTitle.s,
                    subtitle: S.Profile.shoppingSubtitle.f(store.shoppingList.count),
                    route: .shopping)
            Divider().padding(.leading, 66)
            menuRow(emoji: Self.budgetEmoji, title: S.EndOfMonth.navTitle.s,
                    subtitle: S.Home.endOfMonthSubtitle.s,
                    route: .endOfMonth)
            Divider().padding(.leading, 66)
            menuRow(emoji: "🔔", title: S.Profile.reminders.s,
                    subtitle: remindersSubtitle,
                    route: .reminders)
            Divider().padding(.leading, 66)
            menuRow(emoji: "⚙️", title: S.Profile.preferences.s,
                    subtitle: S.Profile.preferencesSubtitle.s,
                    route: .settings)
        }
        .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
    }

    private var remindersSubtitle: String {
        let settings = store.profile.reminderSettings
        guard settings.isEnabled, settings.hasAnyOffset else { return S.Profile.remindersOff.s }
        return S.Profile.remindersOn.s
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

    /// Legal, support and version info required by App Store review.
    /// Deliberately discreet: same row rhythm as the menu above, no extra branding.
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: S.Profile.information.s)

            VStack(spacing: 0) {
                legalRow(title: S.Profile.terms.s, url: SaveatInfo.termsURL)
                Divider().padding(.leading, 16)
                legalRow(title: S.Profile.privacy.s, url: SaveatInfo.privacyURL)
                Divider().padding(.leading, 16)
                legalRow(title: S.Profile.support.s, url: SaveatInfo.supportURL)
                Divider().padding(.leading, 16)
                HStack {
                    Text(S.Profile.version.s)
                        .font(.system(size: 14.5, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                    Text(SaveatInfo.versionText)
                        .font(.system(size: 13.5, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
            .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
        }
    }

    private func legalRow(title: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Text(title)
                    .font(.system(size: 14.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(minHeight: 44)
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
            Text(S.Profile.tagline.s)
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
    @Environment(LanguageStore.self) private var languages

    var body: some View {
        @Bindable var store = store

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                languageCard

                VStack(spacing: 0) {
                    HStack {
                        Text(S.Settings.adults.s).font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                        QuantityStepper(value: $store.profile.adults, range: 1...10)
                    }
                    .padding(16)
                    Divider()
                    HStack {
                        Text(S.Settings.children.s).font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                        QuantityStepper(value: $store.profile.children, range: 0...10)
                    }
                    .padding(16)
                    Divider()
                    HStack {
                        Text(S.Settings.goal.s).font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                        Picker("", selection: $store.profile.goal) {
                            ForEach(HouseholdGoal.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.menu).tint(Theme.sageDeep)
                    }
                    .padding(16)
                    Divider()
                    HStack {
                        Text(S.Settings.diet.s).font(.system(size: 15, weight: .medium, design: .rounded))
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

                dietTagsCard

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: S.Settings.weeklyBudget.s)
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
                    SectionLabel(text: S.Settings.allergies.s)
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
                    SectionLabel(text: S.Settings.dislikes.s)
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
                                Text(DislikeCatalog.display(food))
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

                Button(S.Settings.replayOnboarding.s) {
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
        .navigationTitle(S.Settings.navTitle.s)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    /// Extra eating preferences that stack on top of the main diet.
    ///
    /// Nothing is ever removed from the stock because of these — they only steer
    /// what the assistant suggests, which the notice states plainly.
    private var dietTagsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: S.Diet.preferencesTitle.s)

            VStack(spacing: 0) {
                ForEach(Array(DietTag.allCases.enumerated()), id: \.element.id) { index, tag in
                    Toggle(isOn: Binding(
                        get: { store.profile.hasTag(tag) },
                        set: { isOn in
                            var tags = store.profile.dietTags
                            if isOn { tags.insert(tag) } else { tags.remove(tag) }
                            store.profile.dietTags = tags
                            Haptics.light()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tag.title)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            Text(tag.detail)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .tint(Theme.sage)
                    .padding(.vertical, 4)

                    if index < DietTag.allCases.count - 1 { Divider() }
                }
            }

            Text(S.Diet.keepsStockNotice.s)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .saveatCard()
    }

    /// Language switcher.
    ///
    /// Picking a language only swaps wording and formatting: the stock, dates,
    /// history and subscription are untouched, which is why the note says so.
    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: S.Settings.language.s)

            HStack(spacing: 8) {
                ForEach(AppLanguage.allCases) { option in
                    Button {
                        guard languages.language != option else { return }
                        Haptics.light()
                        languages.select(option)
                    } label: {
                        HStack(spacing: 7) {
                            Text(option.flag).font(.system(size: 15))
                            Text(option.displayName)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(languages.language == option ? .white : Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 46)
                        .background(
                            languages.language == option ? Theme.sage : Theme.creamDeep,
                            in: .capsule
                        )
                    }
                    .buttonStyle(SoftPressStyle())
                    .accessibilityLabel(option.displayName)
                    .accessibilityAddTraits(languages.language == option ? .isSelected : [])
                }
            }

            Text(S.Settings.languageNote.s)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .saveatCard()
    }
}
