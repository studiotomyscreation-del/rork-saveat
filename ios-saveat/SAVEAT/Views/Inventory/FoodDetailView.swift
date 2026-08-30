import SwiftUI

/// One stock item: quantity, storage, date, product sheet and meal ideas.
struct FoodDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: FoodItem

    @State private var draft: FoodItem
    @State private var hasDate: Bool
    @State private var date: Date
    @State private var dateKind: DateKind
    @State private var showsDeleteConfirm = false
    @State private var showsDiscardConfirm = false

    init(item: FoodItem) {
        self.item = item
        _draft = State(initialValue: item)
        _hasDate = State(initialValue: item.bestBefore != nil)
        _date = State(initialValue: item.bestBefore ?? Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now)
        _dateKind = State(initialValue: item.dateType)
    }

    private var live: FoodItem {
        store.inventory.first { $0.id == item.id } ?? item
    }

    private var meals: [Meal] {
        Array(store.suggestions(focusItems: [live]).prefix(3))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                if let notice = live.safetyNotice {
                    SafetyNotice(kind: live.dateType)
                        .accessibilityLabel(notice)
                }
                if live.status != .keep { saveActionsCard }
                if let product = draft.product { productCard(product) }
                quantityCard
                dateCard
                if !meals.isEmpty { mealsSection }
                deleteButton
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle(live.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog("Retirer ce produit de ton stock ?", isPresented: $showsDeleteConfirm, titleVisibility: .visible) {
            Button("Retirer", role: .destructive) {
                store.remove(item)
                Haptics.success()
                dismiss()
            }
            Button("Annuler", role: .cancel) {}
        }
        .confirmationDialog("Jeter ce produit ?", isPresented: $showsDiscardConfirm, titleVisibility: .visible) {
            Button("Jeté", role: .destructive) {
                store.markDiscarded(live)
                dismiss()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Il sera retiré de ton stock et ne comptera pas comme produit sauvé.")
        }
    }

    // MARK: Saved / thrown away

    /// Offered as soon as a product is at risk, so the stock stays truthful.
    private var saveActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                StatusPill(status: live.status)
                Spacer(minLength: 0)
            }

            Text(live.status.detail)
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            SaveOrDiscardButtons(
                onSaved: {
                    store.markSaved(live)
                    dismiss()
                },
                onDiscarded: { showsDiscardConfirm = true }
            )

            Text("« Sauvé » met ton stock à jour et arrête les rappels de ce produit.")
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .saveatCard()
    }

    // MARK: Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ProductThumb(product: draft.product, fallbackEmoji: draft.emoji, size: 76, radius: 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(draft.name)
                    .font(Theme.title(19))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let brand = draft.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
                HStack(spacing: 6) {
                    SoftPill(text: "\(draft.location.emoji) \(draft.location.title)")
                    SoftPill(
                        text: live.deadlineText,
                        tint: StatusTint.color(for: live.status),
                        background: StatusTint.color(for: live.status).opacity(0.14)
                    )
                }
                StatusPill(status: live.status)
            }
            Spacer(minLength: 0)
        }
        .saveatCard()
        .padding(.top, 6)
    }

    // MARK: Product sheet

    private func productCard(_ product: ScannedProduct) -> some View {
        NavigationLink(value: Route.product(product)) {
            HStack(spacing: 14) {
                ScoreChip(value: product.score.value, tone: product.score.tone)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Score SAVEAT — \(product.score.label)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text("Nutrition, additifs, transformation")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft.opacity(0.6))
            }
            .saveatCard(padding: 15)
        }
        .buttonStyle(SoftPressStyle())
    }

    // MARK: Quantity & storage

    private var quantityCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Quantité restante")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                Spacer()
                StockStepper(value: $draft.quantity, range: 0...99)
            }

            Divider()

            HStack {
                Text("Rangement")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                Spacer()
                Picker("", selection: $draft.location) {
                    ForEach(StorageLocation.allCases) { Text("\($0.emoji) \($0.title)").tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Theme.sageDeep)
            }

            Divider()

            Toggle(isOn: $draft.isOpened) {
                Text("Produit entamé")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
            }
            .tint(Theme.sage)
        }
        .foregroundStyle(Theme.ink)
        .saveatCard()
        .onChange(of: draft) { _, newValue in
            var updated = newValue
            updated.bestBefore = hasDate ? date : nil
            updated.dateKind = dateKind
            store.update(updated)
        }
    }

    // MARK: Date

    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Date de consommation")

            Toggle(isOn: $hasDate) {
                Text(hasDate ? "Date renseignée" : "Sans date")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }
            .tint(Theme.sage)

            if hasDate {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "fr_FR"))

                Divider()

                Text("Type de date")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                DateKindPicker(kind: $dateKind)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle").font(.system(size: 12))
                Text("Les dates proviennent de l'emballage ou de toi. SAVEAT ne peut pas déterminer si un aliment est encore bon à partir d'une photo.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.inkSoft)
        }
        .saveatCard()
        .onChange(of: hasDate) { _, _ in save() }
        .onChange(of: date) { _, _ in save() }
        .onChange(of: dateKind) { _, _ in save() }
    }

    private func save() {
        var updated = draft
        updated.bestBefore = hasDate ? date : nil
        updated.dateKind = dateKind
        draft = updated
        store.update(updated)
    }

    // MARK: Meals

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Cuisiner avec ce produit")
            ForEach(meals) { meal in
                NavigationLink(value: Route.meal(meal)) {
                    MealCard(meal: meal, isCompact: true)
                }
                .buttonStyle(SoftPressStyle())
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            Haptics.warning()
            showsDeleteConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                Text("Retirer de mon stock")
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.clay)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.clay.opacity(0.1), in: .rect(cornerRadius: Theme.pillRadius))
        }
        .buttonStyle(SoftPressStyle())
    }
}
