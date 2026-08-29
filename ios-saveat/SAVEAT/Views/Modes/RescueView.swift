import SwiftUI

/// ♻️ À SAUVER — the products to use first and the meals built around them.
struct RescueView: View {
    @Environment(AppStore.self) private var store

    private var queue: [FoodItem] { store.rescueQueue }
    private var meals: [Meal] {
        Array(store.suggestions(focusItems: Array(queue.prefix(6))).prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if queue.isEmpty {
                    SoftEmptyState(
                        emoji: "🌿",
                        title: "Rien à sauver aujourd'hui",
                        message: "Ton stock est sous contrôle. Continue à scanner tes courses pour garder l'avance."
                    )
                    .saveatCard()
                } else {
                    alertCard
                    rescueList
                    if !meals.isEmpty { mealsSection }
                }

                disclaimer
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 6)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle("À sauver")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var alertCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("🔴").font(.system(size: 15))
                Text("\(store.urgentItems.count) produits à sauver")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            Text("Je peux préparer ton dîner avec ces aliments avant qu'ils ne soient gaspillés.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "eurosign.circle.fill").font(.system(size: 12))
                Text("≈ \(Format.euro(store.potentialSavings)) de nourriture à sauver — estimation")
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
            SectionLabel(text: "Dans l'ordre de priorité")
            VStack(spacing: 0) {
                ForEach(Array(queue.prefix(8).enumerated()), id: \.element.id) { index, item in
                    NavigationLink(value: Route.food(item)) {
                        FoodRow(item: item)
                    }
                    .buttonStyle(SoftPressStyle())

                    if index < min(queue.count, 8) - 1 { Divider().padding(.leading, 74) }
                }
            }
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
            .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
        }
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Repas qui les utilisent")
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
            Text("Les priorités reposent sur les dates que tu as saisies ou lues sur l'emballage. SAVEAT ne peut pas juger si un aliment est encore consommable.")
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
                        title: "Pas encore de repas complet",
                        message: "Il manque quelques bases dans ton stock. Scanne tes courses et je trouverai des repas sans dépenser un euro."
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
        .navigationTitle("Repas à 0 €")
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
                userText: "Propose uniquement des repas réalisables sans acheter quoi que ce soit.",
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
            Text("Repas à 0 €")
                .font(Theme.display(25))
                .foregroundStyle(.white)
            Text("On cuisine uniquement avec ce que tu as déjà.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 11))
                Text("Aucun achat nécessaire.")
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
            Text("Je cherche des repas gratuits dans ton stock…")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 0)
        }
        .saveatCard()
    }

    private var promise: some View {
        Text("En mode Repas à 0 €, SAVEAT ne te proposera jamais d'acheter quoi que ce soit. Les basiques du placard (sel, poivre, huile) sont considérés comme déjà présents.")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.creamDeep, in: .rect(cornerRadius: 16))
    }
}
