import SwiftUI

/// Short, tap-first onboarding: household, goal, diet, allergies, dislikes, budget.
struct OnboardingView: View {
    @Environment(AppStore.self) private var store

    @State private var step: Int = 0
    @State private var adults: Int = 2
    @State private var children: Int = 0
    @State private var goal: HouseholdGoal = .reduceWaste
    @State private var diet: DietPreference = .omnivore
    @State private var dietTags: Set<DietTag> = []
    @State private var allergens: Set<Allergen> = []
    @State private var dislikes: Set<String> = []
    @State private var budget: Double = 80

    private let stepCount = 5

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $step) {
                householdStep.tag(0)
                goalStep.tag(1)
                dietStep.tag(2)
                dislikesStep.tag(3)
                budgetStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: step)

            footer
        }
        .saveatBackground()
    }

    // MARK: Chrome

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Text("SAVEAT")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Theme.sageDeep)
                Spacer()
                if step > 0 {
                    Button(S.Onboarding.back.s) { withAnimation { step -= 1 } }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            HStack(spacing: 6) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? Theme.sage : Theme.sageMist)
                        .frame(height: 5)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
                }
            }
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button(step == stepCount - 1 ? S.Onboarding.start.s : S.Onboarding.cont.s) {
                Haptics.soft()
                if step == stepCount - 1 {
                    finish()
                } else {
                    withAnimation { step += 1 }
                }
            }
            .buttonStyle(SaveatButtonStyle())

            Text(S.Onboarding.editLater.s)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.bottom, 12)
    }

    private func finish() {
        var profile = store.profile
        profile.adults = adults
        profile.children = children
        profile.goal = goal
        profile.diet = diet
        profile.dietTags = dietTags
        profile.allergens = allergens
        profile.dislikes = dislikes
        profile.weeklyBudget = budget
        profile.hasCompletedOnboarding = true
        profile.joinedAt = .now
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            store.profile = profile
        }
        Haptics.success()
    }

    // MARK: Steps

    private func stepShell<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(Theme.display(27))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(Theme.body(15))
                        .foregroundStyle(Theme.inkSoft)
                }
                content()
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var householdStep: some View {
        stepShell(title: S.Onboarding.householdTitle.s,
                  subtitle: S.Onboarding.householdSubtitle.s) {
            VStack(spacing: 14) {
                counterCard(emoji: "🧑", label: S.Settings.adults.s, value: $adults, range: 1...10)
                counterCard(emoji: "🧒", label: S.Settings.children.s, value: $children, range: 0...10)
            }

            HStack(spacing: 10) {
                Image(systemName: "fork.knife")
                    .foregroundStyle(Theme.sageDeep)
                Text(adults + children > 1
                    ? S.Onboarding.seatsPlural.f(adults + children)
                    : S.Onboarding.seats.f(adults + children))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(14)
            .background(Theme.sageMist, in: .rect(cornerRadius: 18))
        }
    }

    private func counterCard(emoji: String, label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 14) {
            FoodBadge(emoji: emoji, size: 46)
            Text(label)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Spacer()
            QuantityStepper(value: value, range: range)
        }
        .saveatCard()
    }

    private var goalStep: some View {
        stepShell(title: S.Onboarding.goalTitle.s,
                  subtitle: S.Onboarding.goalSubtitle.s) {
            VStack(spacing: 12) {
                ForEach(HouseholdGoal.allCases) { option in
                    selectableRow(
                        emoji: option.emoji,
                        title: option.title,
                        isSelected: goal == option
                    ) {
                        goal = option
                    }
                }
            }
        }
    }

    private var dietStep: some View {
        stepShell(title: S.Onboarding.dietTitle.s,
                  subtitle: S.Onboarding.dietSubtitle.s) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 10) {
                    ForEach(DietPreference.allCases) { option in
                        selectableRow(
                            emoji: nil,
                            title: option.title,
                            isSelected: diet == option
                        ) {
                            diet = option
                        }
                    }
                }

                SectionLabel(text: S.Diet.preferencesTitle.s)
                chipCloud(items: DietTag.allCases.map(\.title)) { title in
                    guard let tag = DietTag.allCases.first(where: { $0.title == title }) else { return }
                    if dietTags.contains(tag) { dietTags.remove(tag) } else { dietTags.insert(tag) }
                    Haptics.light()
                } isSelected: { title in
                    guard let tag = DietTag.allCases.first(where: { $0.title == title }) else { return false }
                    return dietTags.contains(tag)
                }

                SectionLabel(text: S.Settings.allergies.s)
                chipCloud(items: Allergen.allCases.map(\.title)) { title in
                    guard let allergen = Allergen.allCases.first(where: { $0.title == title }) else { return }
                    if allergens.contains(allergen) { allergens.remove(allergen) } else { allergens.insert(allergen) }
                    Haptics.light()
                } isSelected: { title in
                    guard let allergen = Allergen.allCases.first(where: { $0.title == title }) else { return false }
                    return allergens.contains(allergen)
                }
            }
        }
    }

    private var dislikesStep: some View {
        stepShell(title: S.Onboarding.dislikesTitle.s,
                  subtitle: S.Onboarding.dislikesSubtitle.s) {
            // Chips show the translated label but keep storing the French key,
            // so an exclusion set on one language still applies on the other.
            chipCloud(
                items: DislikeCatalog.all,
                label: DislikeCatalog.display
            ) { key in
                if dislikes.contains(key) { dislikes.remove(key) } else { dislikes.insert(key) }
                Haptics.light()
            } isSelected: { dislikes.contains($0) }
        }
    }

    private var budgetStep: some View {
        stepShell(title: S.Onboarding.budgetTitle.s,
                  subtitle: S.Onboarding.budgetSubtitle.s) {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(Format.euro(budget, decimals: 0))
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.sageDeep)
                        .contentTransition(.numericText())
                    Text(adults + children > 1
                        ? S.Onboarding.perWeekForPlural.f(adults + children)
                        : S.Onboarding.perWeekFor.f(adults + children))
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(Theme.sageMist, in: .rect(cornerRadius: Theme.cardRadius))

                Slider(value: $budget, in: 20...250, step: 5)
                    .tint(Theme.sage)
                    .onChange(of: budget) { _, _ in Haptics.light() }

                HStack {
                    Text(Format.euro(20, decimals: 0)).font(Theme.body(12)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(Format.euro(250, decimals: 0)).font(Theme.body(12)).foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    // MARK: Reusable pieces

    private func selectableRow(emoji: String?, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { action() }
            Haptics.light()
        } label: {
            HStack(spacing: 14) {
                if let emoji {
                    FoodBadge(emoji: emoji, tint: isSelected ? Theme.sage.opacity(0.25) : Theme.sageMist, size: 40)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Theme.sage : Theme.inkSoft.opacity(0.3))
            }
            .padding(16)
            .background(Theme.surface, in: .rect(cornerRadius: Theme.tileRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .stroke(isSelected ? Theme.sage : .clear, lineWidth: 1.8)
            }
        }
        .buttonStyle(SoftPressStyle())
    }

    private func chipCloud(
        items: [String],
        label: @escaping (String) -> String = { $0 },
        onTap: @escaping (String) -> Void,
        isSelected: @escaping (String) -> Bool
    ) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { onTap(item) }
                } label: {
                    Text(label(item))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected(item) ? .white : Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected(item) ? Theme.sage : Theme.surface, in: .capsule)
                }
                .buttonStyle(SoftPressStyle())
            }
        }
    }
}
