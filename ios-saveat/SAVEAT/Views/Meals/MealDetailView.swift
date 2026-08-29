import SwiftUI

/// Full recipe sheet: what you already have, what is missing, cost and steps.
struct MealDetailView: View {
    @Environment(AppStore.self) private var store

    let meal: Meal

    @State private var showsCookSheet = false

    /// Always re-resolved against the live stock so availability stays honest.
    private var resolved: Meal { store.resolve(meal) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                facts
                availabilityCard
                ingredientsCard
                if !resolved.missingIngredients.isEmpty { missingCard }
                stepsCard
                nutritionCard
            }
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) { cookBar }
        .sheet(isPresented: $showsCookSheet) {
            CookConfirmView(meal: resolved)
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
        }
    }

    // MARK: Hero

    @ViewBuilder
    private var hero: some View {
        if let imageName = meal.imageName, UIImage(named: imageName) != nil {
            Theme.sageMist
                .frame(height: 210)
                .overlay {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                }
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    Text(meal.emoji)
                        .font(.system(size: 30))
                        .padding(12)
                        .background(.white.opacity(0.92), in: .circle)
                        .padding(16)
                }
        } else {
            HStack(spacing: 14) {
                Text(meal.emoji).font(.system(size: 40))
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(Theme.title(20))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if !meal.summary.isEmpty {
                        Text(meal.summary)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(Theme.sageMist)
        }
    }

    // MARK: Facts

    private var facts: some View {
        HStack(spacing: 10) {
            fact(value: "\(meal.prepMinutes) min", label: "préparation")
            fact(value: "\(meal.cookMinutes) min", label: "cuisson")
            fact(value: meal.difficulty, label: "difficulté")
            fact(value: "\(meal.servings)", label: meal.servings > 1 ? "personnes" : "personne")
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.top, 14)
    }

    private func fact(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface, in: .rect(cornerRadius: 16))
    }

    // MARK: Availability

    private var availabilityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(resolved.isZeroEuro ? "Tu as tout ce qu'il faut" : resolved.availabilityText)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(resolved.isZeroEuro ? Theme.sageDeep : Theme.ink)
                    Text(resolved.isZeroEuro
                         ? "Aucun achat nécessaire."
                         : "Coût supplémentaire estimé pour compléter.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                VStack(spacing: 0) {
                    Text(resolved.isZeroEuro ? "0 €" : Format.euro(resolved.extraCost))
                        .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(resolved.isZeroEuro ? Theme.sageDeep : Theme.terracotta)
                    Text("à dépenser")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            if let note = resolved.antiWasteNote, !note.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill").font(.system(size: 11))
                    Text(note)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Theme.sageDeep)
            }
        }
        .saveatCard()
        .padding(.horizontal, Theme.hMargin)
    }

    // MARK: Ingredients

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Ingrédients")

            VStack(spacing: 0) {
                ForEach(Array(resolved.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                    HStack(spacing: 12) {
                        Image(systemName: ingredient.isFree ? "checkmark.circle.fill" : "cart.badge.plus")
                            .font(.system(size: 18))
                            .foregroundStyle(ingredient.isFree ? Theme.sage : Theme.terracotta)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(ingredient.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            Text(subtitle(for: ingredient))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(ingredient.isFree ? Theme.sageDeep : Theme.terracotta)
                        }

                        Spacer(minLength: 4)

                        if !ingredient.isFree {
                            Text("~\(Format.euro(ingredient.estimatedPrice))")
                                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(Theme.terracotta)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if index < resolved.ingredients.count - 1 {
                        Divider().padding(.leading, 50)
                    }
                }
            }
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
            .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
        }
        .padding(.horizontal, Theme.hMargin)
    }

    private func subtitle(for ingredient: MealIngredient) -> String {
        let quantity = ingredient.quantityText.isEmpty ? "" : "\(ingredient.quantityText) • "
        if ingredient.isStaple { return "\(quantity)basique du placard" }
        if ingredient.inStock { return "\(quantity)dans ton stock" }
        return "\(quantity)à acheter"
    }

    // MARK: Missing

    private var missingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Il te manque \(resolved.missingIngredients.count) ingrédient\(resolved.missingIngredients.count > 1 ? "s" : "")")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)

            Text(resolved.missingIngredients.map(\.name).joined(separator: " • "))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                store.addToShoppingList(MealEngine.shoppingList(for: [resolved]))
                Haptics.success()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cart.badge.plus")
                    Text("Ajouter à ma liste de courses")
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.terracotta)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.terracotta.opacity(0.14), in: .capsule)
            }
            .buttonStyle(SoftPressStyle())
        }
        .saveatCard()
        .padding(.horizontal, Theme.hMargin)
    }

    // MARK: Steps

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Préparation")

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(resolved.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Theme.sage, in: .circle)
                        Text(step)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .saveatCard()
        .padding(.horizontal, Theme.hMargin)
    }

    // MARK: Nutrition

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Repères nutritionnels")
            HStack(spacing: 10) {
                nutrient("\(resolved.kcalPerServing)", "kcal / personne")
                nutrient("\(resolved.proteinsPerServing) g", "protéines")
                nutrient(Format.euro(resolved.extraCostPerServing), "coût / personne")
            }
            Text("Valeurs approximatives, calculées à partir de moyennes.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
        .saveatCard()
        .padding(.horizontal, Theme.hMargin)
    }

    private func nutrient(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.creamDeep, in: .rect(cornerRadius: 14))
    }

    // MARK: Cook bar

    private var cookBar: some View {
        VStack(spacing: 0) {
            Button {
                Haptics.soft()
                showsCookSheet = true
            } label: {
                Text("Cuisiner")
            }
            .buttonStyle(SaveatButtonStyle())
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 12)
            .padding(.bottom, 10)
        }
        .background(.ultraThinMaterial)
    }
}
