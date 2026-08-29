import SwiftUI

/// 💶 FIN DE MOIS — how far the remaining money goes, starting from the stock.
struct EndOfMonthView: View {
    @Environment(AppStore.self) private var store

    @State private var budget: Double = 35
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 6, to: .now) ?? .now
    @State private var people: Int = 2
    @State private var plan: BudgetPlan?

    private var days: Int {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.startOfDay(for: endDate)
        return max(Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1, 1)
    }

    /// Meals the current stock can already cover without spending anything.
    private var freeMeals: Int {
        let zeroEuro = MealEngine.curatedSuggestions(
            inventory: store.inventory,
            profile: store.profile,
            zeroEuroOnly: true
        )
        guard !zeroEuro.isEmpty else { return 0 }
        let servingsAvailable = zeroEuro.reduce(0) { $0 + $1.servings }
        return max(servingsAvailable / max(people, 1), zeroEuro.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                questionsCard
                Button(plan == nil ? "Calculer mon plan" : "Recalculer") {
                    Haptics.soft()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        plan = MealEngine.budgetPlan(
                            budget: budget,
                            days: days,
                            people: people,
                            inventory: store.inventory,
                            profile: store.profile
                        )
                    }
                }
                .buttonStyle(SaveatButtonStyle())

                if let plan {
                    goodNewsCard(plan)
                    breakdownCard(plan)
                    if !plan.shoppingList.isEmpty { shoppingCard(plan) }
                    mealPlanCard(plan)
                }

                disclaimer
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 6)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle("Fin de mois")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { people = store.profile.householdSize }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💶").font(.system(size: 30))
            Text("Il te reste peu, on fait durer.")
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink)
            Text("SAVEAT part de ton stock actuel avant de dépenser le moindre euro.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.sageMist, in: .rect(cornerRadius: Theme.cardRadius))
    }

    private var questionsCard: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Il me reste")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(Format.euro(budget, decimals: 0))
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.sageDeep)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.creamDeep, in: .rect(cornerRadius: 18))
                Slider(value: $budget, in: 5...200, step: 5)
                    .tint(Theme.sage)
            }

            Divider()

            HStack {
                Text("Jusqu'au")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
                DatePicker("", selection: $endDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "fr_FR"))
            }

            Divider()

            HStack {
                Text("Pour")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
                QuantityStepper(value: $people, range: 1...12)
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar").font(.system(size: 11))
                Text("\(days) jour\(days > 1 ? "s" : "") • \(days * 2) repas à couvrir")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Theme.sageDeep)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .saveatCard()
    }

    private func goodNewsCard(_ plan: BudgetPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bonne nouvelle")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.85))
            Text("Avec ton stock actuel, tu peux déjà préparer")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(max(plan.stockOnlyMeals, freeMeals))")
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text("repas")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [Theme.sage, Theme.sageDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: Theme.cardRadius)
        )
        .shadow(color: Theme.sageDeep.opacity(0.25), radius: 14, y: 5)
    }

    private func breakdownCard(_ plan: BudgetPlan) -> some View {
        VStack(spacing: 14) {
            row(label: "Courses nécessaires estimées",
                value: Format.euro(plan.groceriesCost),
                tint: Theme.terracotta)
            Divider()
            row(label: "Budget restant",
                value: Format.euro(plan.remaining),
                tint: plan.remaining >= 0 ? Theme.sageDeep : Theme.clay)

            if plan.remaining < 0 {
                Text("Le plan dépasse ton budget : j'ai déjà retiré les articles les plus chers. Ajuste les repas ou la période.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.clay)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SoftProgressBar(
                fraction: plan.budget > 0 ? min(plan.groceriesCost / plan.budget, 1) : 0,
                tint: plan.remaining >= 0 ? Theme.sage : Theme.clay
            )
        }
        .saveatCard()
    }

    private func row(label: String, value: String, tint: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(tint)
        }
    }

    private func shoppingCard(_ plan: BudgetPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Le strict nécessaire")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.shoppingList) { item in
                    HStack(spacing: 10) {
                        Text(item.category.emoji)
                        Text(item.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Spacer(minLength: 4)
                        Text("~\(Format.euro(item.estimatedPrice))")
                            .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.terracotta)
                    }
                }
            }

            Button {
                store.addToShoppingList(plan.shoppingList)
                Haptics.success()
            } label: {
                Text("Ajouter à ma liste de courses")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.sageDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.sageMist, in: .capsule)
            }
            .buttonStyle(SoftPressStyle())
        }
        .saveatCard()
    }

    private func mealPlanCard(_ plan: BudgetPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Ton plan de repas")

            VStack(spacing: 0) {
                ForEach(Array(plan.meals.prefix(10).enumerated()), id: \.element.id) { index, meal in
                    HStack(spacing: 12) {
                        VStack(spacing: 1) {
                            Text("J\(meal.dayIndex + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.sageDeep)
                            Text(meal.slot == "Déjeuner" ? "midi" : "soir")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .frame(width: 34)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.recipeName)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Text(meal.usesOnlyStock ? "0 € — uniquement ton stock" : "~\(Format.euro(meal.estimatedCost)) de complément")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(meal.usesOnlyStock ? Theme.sageDeep : Theme.terracotta)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)

                    if index < min(plan.meals.count, 10) - 1 { Divider().padding(.leading, 60) }
                }
            }
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
            .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
        }
    }

    private var disclaimer: some View {
        Text("Tous les montants sont des estimations basées sur des prix moyens français. Ils t'aident à décider, ils ne remplacent pas tes tickets de caisse.")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.creamDeep, in: .rect(cornerRadius: 16))
    }
}
