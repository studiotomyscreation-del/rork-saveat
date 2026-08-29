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

    private var urgent: [FoodItem] { items.filter { $0.freshness == .urgent } }
    private var soon: [FoodItem] { items.filter { $0.freshness == .soon } }
    private var fresh: [FoodItem] { items.filter { $0.freshness == .fresh } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                segmented

                if !store.urgentItems.isEmpty { rescueCard }

                if items.isEmpty {
                    emptyState
                } else {
                    section(title: "À utiliser en priorité", state: .urgent, items: urgent)
                    section(title: "À consommer bientôt", state: .soon, items: soon)
                    section(title: "OK", state: .fresh, items: fresh)
                }

                addManuallyButton
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .searchable(text: $search, prompt: "Chercher un produit")
        .sheet(isPresented: $isAddingItem) {
            AddFoodSheet(defaultLocation: location)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mon stock")
                    .font(Theme.display(27))
                    .foregroundStyle(Theme.ink)
                Text("\(store.totalProducts) produits • valeur estimée \(Format.euro(store.stockValue, decimals: 0))")
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
            .accessibilityLabel("Scanner mes courses")
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
                Text("🔴").font(.system(size: 14))
                Text("\(store.urgentItems.count) produit\(store.urgentItems.count > 1 ? "s" : "") à sauver")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            Text(store.urgentItems.prefix(4).map(\.name).joined(separator: " • "))
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Button("Trouver un repas") {
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
    private func section(title: String, state: FreshnessState, items: [FoodItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    Text(state.dot).font(.system(size: 11))
                    SectionLabel(text: title, color: FreshnessDot.color(for: state))
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
                Text("Ajouter un produit manuellement")
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

    private var emptyState: some View {
        SoftEmptyState(
            emoji: "🧺",
            title: search.isEmpty ? "\(location.title) : rien pour l'instant" : "Aucun résultat",
            message: search.isEmpty
                ? "Scanne tes courses en rentrant : chaque code-barres remplit ton stock automatiquement."
                : "Essaie un autre nom de produit.",
            actionTitle: search.isEmpty ? "Scanner mes courses" : nil,
            action: search.isEmpty ? onScan : nil
        )
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
                        SectionLabel(text: "Produit")
                        TextField("Nom du produit", text: $name)
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
                            Text("Quantité").font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            StockStepper(value: $quantity, range: 0.5...99)
                        }
                        Divider()
                        HStack {
                            Text("Unité").font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            TextField("pièce", text: $unit)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .frame(width: 120)
                        }
                        Divider()
                        HStack {
                            Text("Rangement").font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            Picker("", selection: $location) {
                                ForEach(StorageLocation.allCases) { Text("\($0.emoji) \($0.title)").tag($0) }
                            }
                            .pickerStyle(.menu).tint(Theme.sageDeep)
                        }
                        Divider()
                        HStack {
                            Text("Rayon").font(.system(size: 15, weight: .medium, design: .rounded))
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
                        Toggle(isOn: $hasDate) {
                            Text("Date à consommer de préférence")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.ink)
                        }
                        .tint(Theme.sage)

                        if hasDate {
                            DatePicker("", selection: $bestBefore, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "fr_FR"))
                        }

                        Text("La date vient de l'emballage ou de toi. SAVEAT ne devine jamais la fraîcheur d'un aliment.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .saveatCard()

                    Button("Ajouter à mon stock") {
                        let item = FoodItem(
                            name: name.trimmingCharacters(in: .whitespaces),
                            emoji: emoji,
                            quantity: quantity,
                            unit: unit.isEmpty ? "pièce" : unit,
                            category: category,
                            location: location,
                            bestBefore: hasDate ? bestBefore : nil,
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
            .navigationTitle("Nouveau produit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }
}
