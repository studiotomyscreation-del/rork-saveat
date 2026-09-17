import SwiftUI

/// "Ma semaine" — the real screen the Home Chef card's "Préparer ma semaine"
/// opens (Phase 7 of the Chef/semaine roadmap). Reads and writes
/// `AppStore.currentWeeklyPlan` (Phase 2) and drives `WeeklyPlanGenerator`
/// (Phase 3-4); nothing here recomputes what those already do.
///
/// Free: one generation, capped to 3 days — a genuine shorter plan, not a
/// disguised full week. Premium: 5 or 7 days and unlimited regeneration.
struct WeeklyPlanView: View {
    @Environment(AppStore.self) private var store
    @Environment(SubscriptionStore.self) private var subscriptions

    @State private var numberOfDays = 7
    @State private var isGenerating = false
    @State private var showsPaywall = false

    private var canFullWeek: Bool { subscriptions.canUse(.weeklyPlanning) }
    private var effectiveDays: Int { canFullWeek ? numberOfDays : 3 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let plan = store.currentWeeklyPlan, !plan.days.isEmpty {
                    planContent(plan)
                } else {
                    setupContent
                }
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 8)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(SaveatColors.background.ignoresSafeArea())
        .navigationTitle(S.Week.navTitle.s)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsPaywall) { PaywallSheet(feature: .weeklyPlanning) }
    }

    // MARK: Setup (no plan yet)

    private var setupContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(S.Week.setupTitle.s)
                    .font(SaveatTypography.title(22))
                    .foregroundStyle(SaveatColors.textPrimary)
                Text(S.Week.setupSubtitle.s)
                    .font(SaveatTypography.body(14.5))
                    .foregroundStyle(SaveatColors.textSecondary)
            }

            if canFullWeek {
                HStack(spacing: 10) {
                    dayOption(5)
                    dayOption(7)
                }
            } else {
                SaveatBadge(text: S.Week.freePreviewBadge.f(3), tone: .neutral)
            }

            SaveatPrimaryButton(
                title: isGenerating ? S.Week.generatingCTA.s : S.Week.generateCTA.s,
                isEnabled: !isGenerating,
                action: generate
            )

            if !canFullWeek {
                Button {
                    showsPaywall = true
                } label: {
                    Text(S.Week.unlockFullWeekCTA.s)
                        .font(SaveatTypography.caption(13))
                        .foregroundStyle(SaveatColors.brand)
                }
            }
        }
    }

    private func dayOption(_ value: Int) -> some View {
        let isSelected = numberOfDays == value
        return Button {
            Haptics.light()
            numberOfDays = value
        } label: {
            Text(value == 5 ? S.Intro.foyerDays5.s : S.Intro.foyerDays7.s)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : SaveatColors.forestDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? SaveatColors.brand : SaveatColors.brandSoft, in: .capsule)
        }
        .buttonStyle(.plain)
    }

    // MARK: Plan content

    private func planContent(_ plan: WeeklyMealPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(plan.days) { day in
                if let recipe = day.recipe {
                    NavigationLink(value: Route.meal(recipe)) {
                        dayRow(day: day, recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }

            NavigationLink(value: Route.shopping) {
                HStack(spacing: 10) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SaveatColors.brand)
                    Text(S.Week.viewShoppingListCTA.f(plan.shoppingList.count))
                        .font(SaveatTypography.headline(14))
                        .foregroundStyle(SaveatColors.textPrimary)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SaveatColors.textSecondary.opacity(0.6))
                }
                .padding(14)
                .background(SaveatColors.surface, in: .rect(cornerRadius: Theme.tileRadius))
            }
            .buttonStyle(.plain)

            if canFullWeek {
                SaveatSecondaryButton(
                    title: isGenerating ? S.Week.generatingCTA.s : S.Week.regenerateCTA.s,
                    action: generate
                )
                .disabled(isGenerating)
                .padding(.top, 4)
            }
        }
    }

    private func dayRow(day: MealPlanDay, recipe: Meal) -> some View {
        HStack(spacing: 12) {
            Text(recipe.emoji).font(.system(size: 26))
            VStack(alignment: .leading, spacing: 3) {
                Text(day.date.formatted(.dateTime.weekday(.wide)).capitalized)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.4)
                    .foregroundStyle(SaveatColors.brand)
                Text(recipe.displayName)
                    .font(SaveatTypography.headline(15))
                    .foregroundStyle(SaveatColors.textPrimary)
                Text(recipe.timeText)
                    .font(SaveatTypography.caption(12))
                    .foregroundStyle(SaveatColors.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SaveatColors.textSecondary.opacity(0.6))
        }
        .padding(14)
        .background(SaveatColors.surface, in: .rect(cornerRadius: Theme.tileRadius))
    }

    private func generate() {
        isGenerating = true
        Task {
            let plan = await WeeklyPlanGenerator.shared.generateWeek(
                startDate: .now,
                numberOfDays: effectiveDays,
                servings: store.profile.householdSize,
                preferences: [],
                inventory: store.inventory,
                profile: store.profile
            )
            store.currentWeeklyPlan = plan
            store.addToShoppingList(plan.shoppingList)
            isGenerating = false
        }
    }
}

#Preview {
    NavigationStack {
        WeeklyPlanView()
            .environment(AppStore())
            .environment(SubscriptionStore())
    }
}
