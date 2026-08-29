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
                            title: "Rien à déduire",
                            message: "Ce repas n'utilise aucun produit identifié dans ton stock."
                        )
                        .saveatCard()
                    } else {
                        deductionList
                        summary
                    }

                    Text("Ajuste librement les quantités : ton stock doit refléter ce que tu as vraiment consommé.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Theme.hMargin)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .saveatBackground()
            .navigationTitle("Repas terminé ?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Pas encore") { dismiss() }
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
                Text(meal.name)
                    .font(Theme.title(17))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Je mets ton stock à jour avec ce que tu as utilisé.")
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
                            Text(deduction.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Text("Avant : \(Format.quantity(deduction.before)) \(deduction.unit)")
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
                        Text("Nouveau stock : \(Format.quantity(deduction.after)) \(deduction.unit)")
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
                Text("\(affected.count) produit\(affected.count > 1 ? "s" : "") mis à jour")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(meal.isZeroEuro ? "Repas à 0 € — aucun achat" : "Complément estimé : \(Format.euro(meal.extraCost))")
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
            Button("Oui, mettre mon stock à jour") {
                store.cook(meal, deductions: deductions)
                Haptics.success()
                dismiss()
            }
            .buttonStyle(SaveatButtonStyle())

            Text("Tes économies sont mises à jour automatiquement.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }
}
