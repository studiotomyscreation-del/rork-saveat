import SwiftUI

/// Short, tap-first onboarding: household, goal, diet, allergies, dislikes, budget.
struct OnboardingView: View {
    @Environment(AppStore.self) private var store

    @State private var step: Int = 0
    @State private var adults: Int = 2
    @State private var children: Int = 0
    @State private var goal: HouseholdGoal = .reduceWaste
    @State private var diet: DietPreference = .omnivore
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
                    Button("Retour") { withAnimation { step -= 1 } }
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
            Button(step == stepCount - 1 ? "C'est parti" : "Continuer") {
                Haptics.soft()
                if step == stepCount - 1 {
                    finish()
                } else {
                    withAnimation { step += 1 }
                }
            }
            .buttonStyle(SaveatButtonStyle())

            Text("Tu pourras tout modifier plus tard dans ton profil.")
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
        stepShell(title: "Vous êtes combien à la maison ?",
                  subtitle: "On adapte les quantités et les portions à ton foyer.") {
            VStack(spacing: 14) {
                counterCard(emoji: "🧑", label: "Adultes", value: $adults, range: 1...10)
                counterCard(emoji: "🧒", label: "Enfants", value: $children, range: 0...10)
            }

            HStack(spacing: 10) {
                Image(systemName: "fork.knife")
                    .foregroundStyle(Theme.sageDeep)
                Text("\(adults + children) couvert\(adults + children > 1 ? "s" : "") par repas")
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
        stepShell(title: "Ton objectif principal ?",
                  subtitle: "SAVEAT met en avant ce qui compte le plus pour toi.") {
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
        stepShell(title: "Comment manges-tu ?",
                  subtitle: "On écarte automatiquement les recettes qui ne te conviennent pas.") {
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

                SectionLabel(text: "Allergies")
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
        stepShell(title: "Ce que tu ne manges pas",
                  subtitle: "Touche simplement les aliments à éviter. Aucun texte à saisir.") {
            chipCloud(items: DislikeCatalog.all) { title in
                if dislikes.contains(title) { dislikes.remove(title) } else { dislikes.insert(title) }
                Haptics.light()
            } isSelected: { dislikes.contains($0) }
        }
    }

    private var budgetStep: some View {
        stepShell(title: "Ton budget courses par semaine ?",
                  subtitle: "Une estimation suffit — elle nous sert à calculer tes économies.") {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(Format.euro(budget, decimals: 0))
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.sageDeep)
                        .contentTransition(.numericText())
                    Text("par semaine pour \(adults + children) personne\(adults + children > 1 ? "s" : "")")
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
                    Text("20 €").font(Theme.body(12)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text("250 €").font(Theme.body(12)).foregroundStyle(Theme.inkSoft)
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
        onTap: @escaping (String) -> Void,
        isSelected: @escaping (String) -> Bool
    ) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { onTap(item) }
                } label: {
                    Text(item)
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
