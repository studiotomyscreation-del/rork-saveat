import SwiftUI

/// 🛒 CE QU'IL ME RESTE / CE QU'IL ME MANQUE — the smart shopping mode.
struct ShoppingListView: View {
    @Environment(AppStore.self) private var store

    @State private var tab: Tab = .missing

    private enum Tab: String, CaseIterable, Identifiable {
        case stock, missing
        var id: String { rawValue }
        var title: String {
            switch self {
            case .stock: S.Shopping.stockTab.s
            case .missing: S.Shopping.missingTab.s
            }
        }
    }

    private var grouped: [(category: FoodCategory, items: [ShoppingItem])] {
        FoodCategory.allCases.compactMap { category in
            let items = store.shoppingList.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    private var total: Double {
        store.shoppingList.filter { !$0.isChecked }.reduce(0) { $0 + $1.estimatedPrice }
    }

    private var suggestions: [Meal] {
        Array(store.suggestions().filter { !$0.isZeroEuro }.prefix(3))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                segmented

                switch tab {
                case .stock:
                    stockSummary
                    stockSections
                case .missing:
                    totalCard
                    if store.shoppingList.isEmpty {
                        SoftEmptyState(
                            emoji: "🛒",
                            title: S.Shopping.emptyTitle.s,
                            message: S.Shopping.emptyMessage.s
                        )
                        .saveatCard()
                    } else {
                        ForEach(grouped, id: \.category) { group in
                            categorySection(group.category, items: group.items)
                        }
                        if store.shoppingList.contains(where: \.isChecked) {
                            Button(S.Shopping.clearChecked.s) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    store.clearCheckedShoppingItems()
                                }
                                Haptics.light()
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    if !suggestions.isEmpty { suggestionSection }
                }

                Text(S.Shopping.priceNote.s)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 6)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle(S.Shopping.navTitle.s)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var segmented: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases) { option in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) { tab = option }
                    Haptics.light()
                } label: {
                    Text(option.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(tab == option ? Theme.ink : Theme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background {
                            if tab == option {
                                Capsule()
                                    .fill(Theme.surface)
                                    .shadow(color: Theme.ink.opacity(0.08), radius: 6, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.sageMist, in: .capsule)
    }

    // MARK: What I still have

    private var stockSummary: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(S.Shopping.itemsCount.f(store.totalProducts))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(S.Shopping.estimatedValue.f(Format.euro(store.stockValue, decimals: 0)))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Text("🧺").font(.system(size: 30))
        }
        .saveatCard()
    }

    private var stockSections: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(StorageLocation.allCases) { location in
                let items = store.items(in: location)
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text(location.emoji)
                            SectionLabel(text: S.Shopping.locationCount.f(location.title, items.count))
                        }
                        Text(items.map { "\($0.displayName) (\($0.quantityText))" }.joined(separator: " • "))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
                    .background(Theme.surface, in: .rect(cornerRadius: Theme.tileRadius))
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Text("⚠️").font(.system(size: 13))
                Text(S.Shopping.duplicateWarning.s)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.terracotta)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.terracotta.opacity(0.12), in: .rect(cornerRadius: 16))
        }
    }

    // MARK: What I'm missing

    private var totalCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(S.Shopping.estimatedTotal.s)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                Text(Format.euro(total))
                    .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(S.Shopping.weeklyBudget.s)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                Text(Format.euro(store.profile.weeklyBudget, decimals: 0))
                    .font(Theme.numeric(18))
                    .foregroundStyle(Theme.sageDeep)
            }
        }
        .saveatCard()
    }

    private func categorySection(_ category: FoodCategory, items: [ShoppingItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(category.emoji)
                SectionLabel(text: category.title)
            }

            VStack(spacing: 0) {
                ForEach(items) { item in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            store.toggleShoppingItem(item)
                        }
                        Haptics.light()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 21))
                                .foregroundStyle(item.isChecked ? Theme.sage : Theme.inkSoft.opacity(0.35))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(FoodNames.display(item.name))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(item.isChecked ? Theme.inkSoft : Theme.ink)
                                    .strikethrough(item.isChecked, color: Theme.inkSoft)
                                if let reason = item.reason {
                                    Text(S.Shopping.reasonPrefix.f(SeedCopy.display(reason)))
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(Theme.inkSoft)
                                        .lineLimit(1)
                                }
                            }

                            Spacer(minLength: 4)

                            Text("~\(Format.euro(item.estimatedPrice))")
                                .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(item.isChecked ? Theme.inkSoft : Theme.terracotta)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .contentShape(.rect)
                    }
                    .buttonStyle(SoftPressStyle())

                    if item.id != items.last?.id { Divider().padding(.leading, 50) }
                }
            }
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
            .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
        }
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: S.Shopping.suggestionSection.s)
            ForEach(suggestions) { meal in
                NavigationLink(value: Route.meal(meal)) {
                    MealCard(meal: meal, isCompact: true)
                }
                .buttonStyle(SoftPressStyle())
            }
        }
    }
}
