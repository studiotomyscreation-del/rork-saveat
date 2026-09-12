import SwiftUI

/// MON STOCK — everything the household currently owns, split by storage place.
struct InventoryView: View {
    @Environment(AppStore.self) private var store
    @Binding var path: NavigationPath
    let onScan: () -> Void

    @State private var location: StorageLocation = .fridge
    @State private var isAddingItem = false
    @State private var search = ""

    private var items: [FoodItem] {
        let base = store.items(in: location)
        guard !search.isEmpty else { return base }
        let key = MealEngine.normalize(search)
        return base.filter { MealEngine.normalize($0.name).contains(key) }
    }

    private func items(_ status: ConsumptionStatus) -> [FoodItem] {
        items.filter { $0.status == status }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                segmented

                if !store.rescueItems.isEmpty { rescueCard }

                if items.isEmpty {
                    emptyState
                } else {
                    ForEach(ConsumptionStatus.allCases.sorted { $0.order < $1.order }, id: \.self) { status in
                        section(status: status, items: items(status))
                    }
                }

                addManuallyButton
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .searchable(text: $search, prompt: S.Inventory.searchPrompt.s)
        .sheet(isPresented: $isAddingItem) {
            AddFoodSheet(defaultLocation: location)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(S.Inventory.title.s)
                    .font(Theme.display(27))
                    .foregroundStyle(Theme.ink)
                Text(S.Inventory.subtitle.f(store.totalProducts, Format.euro(store.stockValue, decimals: 0)))
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Button(action: onScan) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.sage, in: .circle)
            }
            .buttonStyle(SoftPressStyle())
            .accessibilityLabel(S.Inventory.scanAccessibility.s)
        }
        .padding(.top, 6)
    }

    private var segmented: some View {
        HStack(spacing: 4) {
            ForEach(StorageLocation.allCases) { option in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) { location = option }
                    Haptics.light()
                } label: {
                    HStack(spacing: 5) {
                        Text(option.emoji).font(.system(size: 13))
                        Text(option.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("\(store.count(in: option))")
                            .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(location == option ? Theme.sageDeep : Theme.inkSoft.opacity(0.7))
                    }
                    .foregroundStyle(location == option ? Theme.ink : Theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background {
                        if location == option {
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

    private var rescueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("🟠").font(.system(size: 14))
                Text(store.rescueItems.count > 1
                    ? S.Inventory.rescueCountPlural.f(store.rescueItems.count)
                    : S.Inventory.rescueCount.f(store.rescueItems.count))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            Text(store.rescueItems.prefix(4).map(\.displayName).joined(separator: " • "))
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Button(S.Inventory.findMeal.s) {
                path.append(Route.rescue)
            }
            .buttonStyle(SaveatButtonStyle(tint: Theme.clay))
        }
        .padding(18)
        .background(Theme.clay.opacity(0.09), in: .rect(cornerRadius: Theme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.clay.opacity(0.35), lineWidth: 1.2)
        }
    }

    @ViewBuilder
    private func section(status: ConsumptionStatus, items: [FoodItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    Text(status.dot).font(.system(size: 11))
                    SectionLabel(text: status.title, color: StatusTint.color(for: status))
                }

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        Button {
                            path.append(Route.food(item))
                        } label: {
                            FoodRow(item: item)
                        }
                        .buttonStyle(SoftPressStyle())

                        if index < items.count - 1 {
                            Divider().padding(.leading, 74)
                        }
                    }
                }
                .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
                .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
            }
        }
    }

    private var addManuallyButton: some View {
        Button {
            Haptics.light()
            isAddingItem = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                Text(S.Inventory.addManually.s)
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.sageDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .strokeBorder(Theme.sage.opacity(0.55), style: StrokeStyle(lineWidth: 1.4, dash: [6, 5]))
            }
        }
        .buttonStyle(SoftPressStyle())
    }

    /// Empty state. A brand-new account gets the first-run invitation rather than
    /// a bare "this shelf is empty", which would read like something went wrong.
    private var emptyState: some View {
        let isFirstRun = search.isEmpty && store.hasNoHistory

        return VStack(spacing: 12) {
            SoftEmptyState(
                emoji: isFirstRun ? "🛒" : "🧺",
                title: {
                    if !search.isEmpty { return S.Inventory.noResults.s }
                    return isFirstRun
                        ? S.Inventory.firstRunTitle.s
                        : S.Inventory.emptyTitle.f(location.title)
                }(),
                message: {
                    if !search.isEmpty { return S.Inventory.noResultsMessage.s }
                    return isFirstRun
                        ? S.Inventory.firstRunMessage.s
                        : S.Inventory.emptyMessage.s
                }(),
                actionTitle: search.isEmpty
                    ? (isFirstRun ? S.Inventory.firstRunPrimary.s : S.Home.scanTitle.s)
                    : nil,
                action: search.isEmpty ? onScan : nil
            )

            if isFirstRun {
                Button {
                    Haptics.light()
                    isAddingItem = true
                } label: {
                    Text(S.Inventory.addManually.s)
                        .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.sageDeep)
                }
                .buttonStyle(SoftPressStyle())
                .padding(.bottom, 18)
            }
        }
        .saveatCard()
    }
}

/// Manual entry for produce and market goods without a barcode.
struct AddFoodSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let defaultLocation: StorageLocation

    @State private var name = ""
    @State private var emoji = "🥕"
    @State private var quantity: Double = 1
    @State private var unit = "pièce"
    @State private var category: FoodCategory = .produce
    @State private var location: StorageLocation
    @State private var hasDate = true
    @State private var bestBefore = Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now
    @State private var dateKind: DateKind = .unknown
    @State private var value: Double = 2

    private let emojis = ["🥕", "🍅", "🥬", "🍎", "🥚", "🧀", "🥩", "🍞", "🍝", "🥫", "🥛", "🐟", "🫘", "🥦"]

    init(defaultLocation: StorageLocation) {
        self.defaultLocation = defaultLocation
        _location = State(initialValue: defaultLocation)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: S.AddFood.productSection.s)
                        TextField(S.AddFood.namePlaceholder.s, text: $name)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .padding(15)
                            .background(Theme.creamDeep, in: .rect(cornerRadius: 16))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
                            ForEach(emojis, id: \.self) { option in
                                Button {
                                    emoji = option
                                    Haptics.light()
                                } label: {
                                    Text(option)
                                        .font(.system(size: 22))
                                        .frame(width: 46, height: 46)
                                        .background(emoji == option ? Theme.sage.opacity(0.25) : Theme.creamDeep, in: .circle)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .saveatCard()

                    VStack(spacing: 14) {
                        HStack {
                            Text(S.AddFood.quantity.s).font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            StockStepper(value: $quantity, range: 0.5...99)
                        }
                        Divider()
                        HStack {
                            Text(S.AddFood.unit.s).font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            TextField(S.AddFood.unitPlaceholder.s, text: $unit)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .frame(width: 120)
                        }
                        Divider()
                        HStack {
                            Text(S.AddFood.storage.s).font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            Picker("", selection: $location) {
                                ForEach(StorageLocation.allCases) { Text("\($0.emoji) \($0.title)").tag($0) }
                            }
                            .pickerStyle(.menu).tint(Theme.sageDeep)
                        }
                        Divider()
                        HStack {
                            Text(S.AddFood.aisle.s).font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            Picker("", selection: $category) {
                                ForEach(FoodCategory.allCases) { Text($0.title).tag($0) }
                            }
                            .pickerStyle(.menu).tint(Theme.sageDeep)
                        }
                    }
                    .foregroundStyle(Theme.ink)
                    .saveatCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: S.AddFood.dateSection.s)

                        Toggle(isOn: $hasDate) {
                            Text(hasDate ? S.AddFood.hasDate.s : S.Common.noDate.s)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.ink)
                        }
                        .tint(Theme.sage)

                        if hasDate {
                            DatePicker("", selection: $bestBefore, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()

                            Divider()

                            Text(S.AddFood.dateType.s)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            DateKindPicker(kind: $dateKind)
                        }

                        Text(S.AddFood.dateNote.s)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .saveatCard()

                    Button(S.AddFood.addToStock.s) {
                        let item = FoodItem(
                            name: name.trimmingCharacters(in: .whitespaces),
                            emoji: emoji,
                            quantity: quantity,
                            unit: unit.isEmpty ? "pièce" : unit,
                            category: category,
                            location: location,
                            bestBefore: hasDate ? bestBefore : nil,
                            dateKind: hasDate ? dateKind : .unknown,
                            estimatedValue: value
                        )
                        store.add([item])
                        Haptics.success()
                        dismiss()
                    }
                    .buttonStyle(SaveatButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, Theme.hMargin)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .saveatBackground()
            .navigationTitle(S.AddFood.navTitle.s)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(S.Common.cancel.s) { dismiss() }
                }
            }
        }
    }
}
