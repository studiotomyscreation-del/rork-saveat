import SwiftUI

/// Full recipe sheet — SAVEAT V2 design: photo hero, real-time availability
/// and savings, then tabbed sections (Overview / Ingredients / Steps / Tips /
/// Nutrition) instead of one long scroll.
struct MealDetailView: View {
    @Environment(AppStore.self) private var store

    let meal: Meal

    @State private var showsCookSheet = false
    @State private var selectedTab: DetailTab = .overview

    private enum DetailTab: CaseIterable, Hashable {
        case overview, ingredients, steps, tips, nutrition

        var title: String {
            switch self {
            case .overview: S.Meals.tabOverview.s
            case .ingredients: S.Meals.tabIngredients.s
            case .steps: S.Meals.tabSteps.s
            case .tips: S.Meals.tabTips.s
            case .nutrition: S.Meals.tabNutrition.s
            }
        }
    }

    /// Always re-resolved against the live stock so availability stays honest.
    private var resolved: Meal { store.resolve(meal) }

    private var coverageFraction: Double {
        guard !resolved.ingredients.isEmpty else { return 0 }
        return Double(resolved.availableIngredients.count) / Double(resolved.ingredients.count)
    }

    /// Only shown when this meal is actually compatible with the household's
    /// own diet — real `MealEngine` logic, never a guessed label. Omnivore
    /// and flexitarian aren't restrictions, so they never earn a badge.
    private var compatibleDietBadge: DietPreference? {
        let diet = store.profile.diet
        guard diet != .omnivore, diet != .flexitarian else { return nil }
        return MealEngine.isCompatible(resolved, with: store.profile) ? diet : nil
    }

    private let missingTint = SaveatBadgeTone.promo.foreground
    private let missingBackground = SaveatBadgeTone.promo.background

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                facts
                tabBar
                tabContent
                    .padding(.horizontal, Theme.hMargin)
            }
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(SaveatColors.background.ignoresSafeArea())
        .navigationTitle(meal.displayName)
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
            SaveatColors.brandSoft
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
                .overlay(alignment: .topTrailing) {
                    if let compatibleDietBadge {
                        SaveatBadge(text: S.Meals.compatibleWithDiet.f(compatibleDietBadge.title), tone: .brand, icon: "checkmark.seal.fill")
                            .padding(16)
                    }
                }
        } else {
            HStack(alignment: .top, spacing: 14) {
                Text(meal.emoji).font(.system(size: 40))
                VStack(alignment: .leading, spacing: 6) {
                    Text(meal.displayName)
                        .font(SaveatTypography.title(20))
                        .foregroundStyle(SaveatColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !meal.summary.isEmpty {
                        Text(meal.displaySummary)
                            .font(SaveatTypography.caption(13))
                            .foregroundStyle(SaveatColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let compatibleDietBadge {
                        SaveatBadge(text: S.Meals.compatibleWithDiet.f(compatibleDietBadge.title), tone: .brand, icon: "checkmark.seal.fill")
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(SaveatColors.brandSoft)
        }
    }

    // MARK: Facts

    private var facts: some View {
        HStack(spacing: 10) {
            fact(value: "\(meal.prepMinutes) min", label: S.Meals.prepLabel.s)
            fact(value: "\(meal.cookMinutes) min", label: S.Meals.cookLabel.s)
            fact(value: meal.displayDifficulty, label: S.Meals.difficultyLabel.s)
            fact(
                value: "\(meal.servings)",
                label: meal.servings > 1 ? S.Meals.servingsLabelPlural.s : S.Meals.servingsLabel.s
            )
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.top, 14)
    }

    private func fact(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(SaveatTypography.headline(15))
                .foregroundStyle(SaveatColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(SaveatTypography.caption(10))
                .foregroundStyle(SaveatColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(SaveatColors.surface, in: .rect(cornerRadius: 16))
    }

    // MARK: Tabs

    private var tabBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    pillTab(tab)
                }
            }
            .padding(.horizontal, Theme.hMargin)
        }
        .scrollIndicators(.hidden)
    }

    private func pillTab(_ tab: DetailTab) -> some View {
        Button {
            Haptics.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selectedTab = tab }
        } label: {
            Text(tab.title)
                .font(SaveatTypography.caption(12.5))
                .foregroundStyle(selectedTab == tab ? SaveatColors.textOnDark : SaveatColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(selectedTab == tab ? SaveatColors.brand : SaveatColors.surface, in: .capsule)
        }
        .buttonStyle(SoftPressStyle())
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview: overviewTab
        case .ingredients: ingredientsTab
        case .steps: stepsTab
        case .tips: tipsTab
        case .nutrition: nutritionTab
        }
    }

    // MARK: Overview

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            SaveatCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        coverageRing
                        VStack(alignment: .leading, spacing: 3) {
                            Text(resolved.isZeroEuro ? S.Meals.haveEverything.s : resolved.availabilityText)
                                .font(SaveatTypography.headline(15))
                                .foregroundStyle(SaveatColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(resolved.isZeroEuro ? S.Meals.noPurchase.s : S.Meals.extraCostNote.s)
                                .font(SaveatTypography.caption(12))
                                .foregroundStyle(SaveatColors.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }

                    if resolved.potentialSavings > 0 {
                        HStack(spacing: 10) {
                            Image(systemName: "leaf.circle.fill")
                                .foregroundStyle(SaveatColors.brand)
                            Text(S.Meals.savingsCardTitle.s)
                                .font(SaveatTypography.caption(12))
                                .foregroundStyle(SaveatColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text(Format.euro(resolved.potentialSavings))
                                .font(SaveatTypography.headline(16))
                                .foregroundStyle(SaveatColors.forestDeep)
                        }
                        .padding(12)
                        .background(SaveatColors.brandSoft, in: .rect(cornerRadius: 14))
                    }
                }
            }

            haveMissGrid
        }
    }

    private var coverageRing: some View {
        ZStack {
            Circle().stroke(SaveatColors.brandSoft, lineWidth: 7)
            Circle()
                .trim(from: 0, to: coverageFraction)
                .stroke(SaveatColors.brand, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((coverageFraction * 100).rounded()))%")
                .font(SaveatTypography.headline(14.5))
                .foregroundStyle(SaveatColors.forestDeep)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 64, height: 64)
    }

    private var haveMissGrid: some View {
        HStack(alignment: .top, spacing: 10) {
            haveMissColumn(
                title: S.Meals.chipHaveCount.f(resolved.availableIngredients.count),
                items: resolved.availableIngredients,
                tint: SaveatColors.brand,
                background: SaveatColors.brandSoft
            )
            if !resolved.missingIngredients.isEmpty {
                haveMissColumn(
                    title: S.Meals.chipMissingCount.f(resolved.missingIngredients.count),
                    items: resolved.missingIngredients,
                    tint: missingTint,
                    background: missingBackground
                )
            }
        }
    }

    private func haveMissColumn(title: String, items: [MealIngredient], tint: Color, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(SaveatTypography.caption(11.5))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items) { ingredient in
                    HStack(spacing: 6) {
                        Circle().fill(tint).frame(width: 6, height: 6)
                        Text(ingredient.displayName)
                            .font(SaveatTypography.caption(12.5))
                            .foregroundStyle(SaveatColors.textPrimary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(background, in: .rect(cornerRadius: 16))
    }

    // MARK: Ingredients

    private var ingredientsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            SaveatCard {
                VStack(spacing: 0) {
                    ForEach(Array(resolved.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                        HStack(spacing: 12) {
                            Image(systemName: ingredient.isFree ? "checkmark.circle.fill" : "cart.badge.plus")
                                .font(.system(size: 18))
                                .foregroundStyle(ingredient.isFree ? SaveatColors.brand : missingTint)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(ingredient.displayName)
                                    .font(SaveatTypography.headline(14.5))
                                    .foregroundStyle(SaveatColors.textPrimary)
                                Text(subtitle(for: ingredient))
                                    .font(SaveatTypography.caption(11.5))
                                    .foregroundStyle(ingredient.isFree ? SaveatColors.brand : missingTint)
                            }

                            Spacer(minLength: 4)

                            if !ingredient.isFree {
                                Text("~\(Format.euro(ingredient.estimatedPrice))")
                                    .font(SaveatTypography.caption(12.5))
                                    .foregroundStyle(missingTint)
                            }
                        }
                        .padding(.vertical, 10)

                        if index < resolved.ingredients.count - 1 {
                            Divider()
                        }
                    }
                }
            }

            if !resolved.missingIngredients.isEmpty {
                Button {
                    store.addToShoppingList(MealEngine.shoppingList(for: [resolved]))
                    Haptics.success()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.badge.plus")
                        Text(S.Meals.addToList.s)
                    }
                    .font(SaveatTypography.headline(15))
                    .foregroundStyle(SaveatColors.textOnDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SaveatColors.brand, in: .capsule)
                }
                .buttonStyle(SoftPressStyle())
            }
        }
    }

    private func subtitle(for ingredient: MealIngredient) -> String {
        let quantity = ingredient.quantityText.isEmpty ? "" : "\(ingredient.displayQuantity) • "
        if ingredient.isStaple { return "\(quantity)\(S.Meals.staple.s)" }
        if ingredient.inStock { return "\(quantity)\(S.Meals.inStock.s)" }
        return "\(quantity)\(S.Meals.toBuy.s)"
    }

    // MARK: Steps

    private var stepsTab: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(resolved.displaySteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(SaveatTypography.caption(13))
                            .foregroundStyle(SaveatColors.textOnDark)
                            .frame(width: 26, height: 26)
                            .background(SaveatColors.brand, in: .circle)
                        Text(step)
                            .font(SaveatTypography.body(15))
                            .foregroundStyle(SaveatColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: Tips

    private var tipsTab: some View {
        SaveatCard {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(SaveatColors.brand)
                let note = resolved.displayNote ?? ""
                Text(note.isEmpty ? S.Meals.noTip.s : note)
                    .font(SaveatTypography.body(14.5))
                    .foregroundStyle(SaveatColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Nutrition

    private var nutritionTab: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    nutrient("\(resolved.kcalPerServing)", S.Meals.kcalPerServing.s)
                    nutrient(Units.weight(grams: Double(resolved.proteinsPerServing)), S.Meals.proteins.s)
                    nutrient(Format.euro(resolved.extraCostPerServing), S.Meals.costPerServing.s)
                }
                Text(S.Meals.nutritionNote.s)
                    .font(SaveatTypography.caption(11))
                    .foregroundStyle(SaveatColors.textSecondary)
            }
        }
    }

    private func nutrient(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(SaveatTypography.headline(16))
                .foregroundStyle(SaveatColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(SaveatTypography.caption(10))
                .foregroundStyle(SaveatColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(SaveatColors.background, in: .rect(cornerRadius: 14))
    }

    // MARK: Cook bar

    private var cookBar: some View {
        SaveatPrimaryButton(title: S.Meals.cook.s) {
            showsCookSheet = true
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationStack {
        MealDetailView(meal: MockData.curatedMeals.first!)
            .environment(AppStore())
    }
}
