import SwiftUI

/// "Repas terminé ?" — deducts what was really used, with manual corrections.
struct CookConfirmView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let meal: Meal

    @State private var deductions: [StockDeduction] = []
    @State private var hasLoaded = false

    private var affected: [StockDeduction] { deductions.filter { $0.used > 0 } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    intro

                    if deductions.isEmpty {
                        SoftEmptyState(
                            emoji: "🍽️",
                            title: S.Meals.nothingToDeduct.s,
                            message: S.Meals.nothingToDeductMessage.s
                        )
                        .saveatCard()
                    } else {
                        deductionList
                        summary
                    }

                    Text(S.Meals.adjustNote.s)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Theme.hMargin)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .saveatBackground()
            .navigationTitle(S.Meals.cookNavTitle.s)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(S.Meals.notYet.s) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { confirmBar }
            .task {
                guard !hasLoaded else { return }
                hasLoaded = true
                deductions = MealEngine.deductions(for: meal, inventory: store.inventory)
            }
        }
    }

    private var intro: some View {
        HStack(spacing: 14) {
            Text(meal.emoji).font(.system(size: 32))
            VStack(alignment: .leading, spacing: 3) {
                Text(meal.displayName)
                    .font(Theme.title(17))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(S.Meals.cookIntro.s)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .saveatCard()
        .padding(.top, 6)
    }

    private var deductionList: some View {
        VStack(spacing: 0) {
            ForEach($deductions) { $deduction in
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        FoodBadge(emoji: deduction.emoji, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(FoodNames.display(deduction.name))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Text(S.Meals.before.f(
                                Format.quantity(deduction.before),
                                FoodUnits.display(deduction.unit, quantity: deduction.before)
                            ))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.inkSoft)
                        }

                        Spacer(minLength: 4)

                        StockStepper(value: $deduction.used, range: 0...deduction.before)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.sageDeep)
                        Text(S.Meals.after.f(
                            Format.quantity(deduction.after),
                            FoodUnits.display(deduction.unit, quantity: deduction.after)
                        ))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(deduction.after <= 0 ? Theme.clay : Theme.sageDeep)
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)

                if deduction.id != deductions.last?.id { Divider().padding(.leading, 68) }
            }
        }
        .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
    }

    private var summary: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(affected.count > 1
                    ? S.Meals.itemsUpdatedPlural.f(affected.count)
                    : S.Meals.itemsUpdated.f(affected.count))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(meal.isZeroEuro
                    ? S.Meals.zeroCostSummary.f(Units.zeroCostLabel)
                    : S.Meals.extraSummary.f(Format.euro(meal.extraCost)))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Text(meal.isZeroEuro ? "🥘" : "🛒").font(.system(size: 26))
        }
        .padding(16)
        .background(Theme.sageMist, in: .rect(cornerRadius: Theme.tileRadius))
    }

    private var confirmBar: some View {
        VStack(spacing: 6) {
            Button(S.Meals.confirmCook.s) {
                store.cook(meal, deductions: deductions)
                Haptics.success()
                dismiss()
            }
            .buttonStyle(SaveatButtonStyle())

            Text(S.Meals.savingsNote.s)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }
}
