import SwiftUI

/// ♻️ À SAUVER — the products to use first and the meals built around them.
///
/// Order follows the priority levels: 🟠 first, then 🟡. Products whose date is
/// reached get their own section with a cautious notice instead of a recipe.
struct RescueView: View {
    @Environment(AppStore.self) private var store

    @State private var discardCandidate: FoodItem?

    private var queue: [FoodItem] { store.rescueQueue }
    private var reached: [FoodItem] { store.reachedItems }

    private var meals: [Meal] {
        Array(store.suggestions(focusItems: Array(queue.prefix(6))).prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if queue.isEmpty && reached.isEmpty {
                    SoftEmptyState(
                        emoji: "🌿",
                        title: S.Rescue.emptyTitle.s,
                        message: S.Rescue.emptyMessage.s
                    )
                    .saveatCard()
                } else {
                    if !queue.isEmpty {
                        alertCard
                        rescueList
                    }
                    if !reached.isEmpty { reachedSection }
                    if !queue.isEmpty, !meals.isEmpty { mealsSection }
                }

                disclaimer
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 6)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle(S.Rescue.navTitle.s)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog(
            S.FoodDetail.discardConfirmTitle.s,
            isPresented: Binding(
                get: { discardCandidate != nil },
                set: { if !$0 { discardCandidate = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(S.Rescue.markDiscarded.s, role: .destructive) {
                if let item = discardCandidate { store.markDiscarded(item) }
                discardCandidate = nil
            }
            Button(S.Common.cancel.s, role: .cancel) { discardCandidate = nil }
        } message: {
            Text(S.FoodDetail.discardConfirmMessage.s)
        }
    }

    private var alertCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("🟠").font(.system(size: 15))
                Text(queue.count > 1 ? S.Rescue.countPlural.f(queue.count) : S.Rescue.count.f(queue.count))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            Text(S.Rescue.intro.s)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "tag.circle.fill").font(.system(size: 12))
                Text(S.Rescue.potentialSavings.f(Format.euro(store.potentialSavings)))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Theme.sageDeep)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.clay.opacity(0.09), in: .rect(cornerRadius: Theme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.clay.opacity(0.35), lineWidth: 1.2)
        }
    }

    private var rescueList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: S.Rescue.priorityOrder.s)

            VStack(spacing: 12) {
                ForEach(queue.prefix(8)) { item in
                    VStack(spacing: 0) {
                        NavigationLink(value: Route.food(item)) {
                            RescueRow(item: item)
                        }
                        .buttonStyle(SoftPressStyle())

                        Divider().padding(.horizontal, 16)

                        SaveOrDiscardButtons(
                            onSaved: { store.markSaved(item) },
                            onDiscarded: { discardCandidate = item }
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
                    .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
                }
            }
        }
    }

    /// Products whose date is reached: informed, never encouraged.
    private var reachedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Text("🔴").font(.system(size: 11))
                SectionLabel(text: S.Rescue.reachedSection.s, color: Theme.alert)
            }

            VStack(spacing: 12) {
                ForEach(reached.prefix(6)) { item in
                    VStack(spacing: 0) {
                        NavigationLink(value: Route.food(item)) {
                            RescueRow(item: item)
                        }
                        .buttonStyle(SoftPressStyle())

                        SafetyNotice(kind: item.dateType)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)

                        Divider().padding(.horizontal, 16)

                        SaveOrDiscardButtons(
                            onSaved: { store.markSaved(item) },
                            onDiscarded: { discardCandidate = item }
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
                    .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
                }
            }
        }
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: S.Rescue.mealsSection.s)
            ForEach(meals) { meal in
                NavigationLink(value: Route.meal(meal)) {
                    MealCard(meal: meal)
                }
                .buttonStyle(SoftPressStyle())
            }
        }
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle").font(.system(size: 12))
            Text(S.Rescue.disclaimer.s)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.inkSoft)
        .padding(14)
        .background(Theme.creamDeep, in: .rect(cornerRadius: 16))
    }
}

/// 💰 REPAS À 0 € — strictly no purchase allowed.
struct ZeroEuroView: View {
    @Environment(AppStore.self) private var store

    @State private var meals: [Meal] = []
    @State private var isLoading = true
    @State private var hasLoaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero

                if isLoading {
                    loadingCard
                } else if meals.isEmpty {
                    SoftEmptyState(
                        emoji: "🥣",
                        title: S.ZeroCost.emptyTitle.s,
                        message: S.ZeroCost.emptyMessage.s
                    )
                    .saveatCard()
                } else {
                    ForEach(meals) { meal in
                        NavigationLink(value: Route.meal(meal)) {
                            MealCard(meal: meal)
                        }
                        .buttonStyle(SoftPressStyle())
                    }
                }

                promise
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 6)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle(S.ZeroCost.navTitle.s)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            await load()
        }
    }

    private func load() async {
        let answer = await MealAIService.shared.meals(
            inventory: store.inventory,
            profile: store.profile,
            request: MealAIService.Request(
                userText: S.ZeroCost.prompt.s,
                servings: store.profile.householdSize,
                zeroEuroOnly: true
            )
        )

        var ranked = MealEngine.rank(
            answer.meals,
            inventory: store.inventory,
            profile: store.profile,
            zeroEuroOnly: true
        )
        if ranked.isEmpty {
            ranked = MealEngine.curatedSuggestions(
                inventory: store.inventory,
                profile: store.profile,
                zeroEuroOnly: true,
                servings: store.profile.householdSize
            )
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
            meals = Array(ranked.prefix(6))
            isLoading = false
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("💰")
                .font(.system(size: 32))
            Text(S.ZeroCost.heroTitle.s)
                .font(Theme.display(25))
                .foregroundStyle(.white)
            Text(S.ZeroCost.heroSubtitle.s)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 11))
                Text(S.ZeroCost.noPurchase.s)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.18), in: .capsule)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [Theme.sage, Theme.sageDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: Theme.cardRadius)
        )
        .shadow(color: Theme.sageDeep.opacity(0.25), radius: 14, y: 5)
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView().tint(Theme.sageDeep)
            Text(S.ZeroCost.loading.s)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 0)
        }
        .saveatCard()
    }

    private var promise: some View {
        Text(S.ZeroCost.promise.s)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.creamDeep, in: .rect(cornerRadius: 16))
    }
}
