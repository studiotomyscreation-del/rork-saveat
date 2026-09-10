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
                Button(plan == nil ? S.EndOfMonth.calculate.s : S.EndOfMonth.recalculate.s) {
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
        .navigationTitle(S.EndOfMonth.navTitle.s)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { people = store.profile.householdSize }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💶").font(.system(size: 30))
            Text(S.EndOfMonth.introTitle.s)
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink)
            Text(S.EndOfMonth.introBody.s)
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
                Text(S.EndOfMonth.iHaveLeft.s)
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
                Text(S.EndOfMonth.until.s)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
                DatePicker("", selection: $endDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            Divider()

            HStack {
                Text(S.EndOfMonth.forPeople.s)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
                QuantityStepper(value: $people, range: 1...12)
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar").font(.system(size: 11))
                Text(days > 1
                    ? S.EndOfMonth.daysToCoverPlural.f(days, days * 2)
                    : S.EndOfMonth.daysToCover.f(days, days * 2))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Theme.sageDeep)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .saveatCard()
    }

    private func goodNewsCard(_ plan: BudgetPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(S.EndOfMonth.goodNews.s)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.85))
            Text(S.EndOfMonth.alreadyCook.s)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(max(plan.stockOnlyMeals, freeMeals))")
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text(S.EndOfMonth.mealsWord.s)
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
            row(label: S.EndOfMonth.groceriesNeeded.s,
                value: Format.euro(plan.groceriesCost),
                tint: Theme.terracotta)
            Divider()
            row(label: S.EndOfMonth.budgetLeft.s,
                value: Format.euro(plan.remaining),
                tint: plan.remaining >= 0 ? Theme.sageDeep : Theme.clay)

            if plan.remaining < 0 {
                Text(S.EndOfMonth.overBudget.s)
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
            SectionLabel(text: S.EndOfMonth.essentials.s)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.shoppingList) { item in
                    HStack(spacing: 10) {
                        Text(item.category.emoji)
                        Text(FoodNames.display(item.name))
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
                Text(S.Meals.addToList.s)
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
            SectionLabel(text: S.EndOfMonth.mealPlan.s)

            VStack(spacing: 0) {
                ForEach(Array(plan.meals.prefix(10).enumerated()), id: \.element.id) { index, meal in
                    HStack(spacing: 12) {
                        VStack(spacing: 1) {
                            Text(S.EndOfMonth.dayPrefix.f(meal.dayIndex + 1))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.sageDeep)
                            Text(meal.slot == "Déjeuner" ? S.EndOfMonth.lunchShort.s : S.EndOfMonth.dinnerShort.s)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .frame(width: 34)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(SeedCopy.display(meal.recipeName))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Text(meal.usesOnlyStock
                                ? S.EndOfMonth.stockOnly.f(Units.zeroCostLabel)
                                : S.EndOfMonth.extraCost.f(Format.euro(meal.estimatedCost)))
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
        Text(S.EndOfMonth.disclaimer.s)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.creamDeep, in: .rect(cornerRadius: 16))
    }
}
