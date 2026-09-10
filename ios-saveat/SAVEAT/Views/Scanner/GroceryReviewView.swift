import SwiftUI

/// Last step of a shopping session: check storage places and add the dates.
struct GroceryReviewView: View {
    @Binding var entries: [ScanEntry]
    let onBack: () -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var editingEntry: ScanEntry?

    private var total: Double { entries.reduce(0) { $0 + $1.estimatedValue } }
    private var withoutDate: Int { entries.filter { $0.bestBefore == nil }.count }

    private var grouped: [(location: StorageLocation, items: [ScanEntry])] {
        StorageLocation.allCases.compactMap { location in
            let items = entries.filter { $0.location == location }
            return items.isEmpty ? nil : (location, items)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if entries.isEmpty {
                Spacer()
                SoftEmptyState(
                    emoji: "🛒",
                    title: S.Scan.nothingScannedTitle.s,
                    message: S.Scan.nothingScannedMessage.s
                )
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard
                        ForEach(grouped, id: \.location) { group in
                            locationSection(group.location, items: group.items)
                        }
                        Text(S.Scan.reviewDateNote.s)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, Theme.hMargin)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            }

            footer
        }
        .saveatBackground()
        .sheet(item: $editingEntry) { entry in
            ScanEntryEditor(entry: entry) { updated in
                if let index = entries.firstIndex(where: { $0.id == updated.id }) {
                    entries[index] = updated
                }
            }
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.sageDeep)
                    .frame(width: 38, height: 38)
                    .background(Theme.surface, in: .circle)
            }
            .buttonStyle(SoftPressStyle())
            .accessibilityLabel(S.Scan.resumeScan.s)

            Text(S.Scan.reviewTitle.s)
                .font(Theme.title(19))
                .foregroundStyle(Theme.ink)

            Spacer()

            Button(S.Common.cancel.s, action: onCancel)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(S.Scan.itemsCount.f(entries.count))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(S.Scan.runLogged.f(Format.euro(total)))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.sageDeep)
            }
            Spacer()
            if withoutDate > 0 {
                VStack(spacing: 2) {
                    Text("\(withoutDate)")
                        .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.terracotta)
                    Text(S.Scan.withoutDate.s)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.terracotta.opacity(0.14), in: .rect(cornerRadius: 14))
            }
        }
        .saveatCard()
    }

    private func locationSection(_ location: StorageLocation, items: [ScanEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(location.emoji)
                SectionLabel(text: location.title)
            }

            VStack(spacing: 0) {
                ForEach(items) { entry in
                    Button {
                        editingEntry = entry
                        Haptics.light()
                    } label: {
                        HStack(spacing: 12) {
                            ProductThumb(product: entry.product, size: 46, radius: 13)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.product.displayTitle)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Text("\(Format.quantity(entry.quantity)) × \(FoodUnits.display(entry.product.unit, quantity: entry.quantity))")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(Theme.inkSoft)
                            }

                            Spacer(minLength: 4)

                            if let date = entry.bestBefore {
                                VStack(alignment: .trailing, spacing: 3) {
                                    Text(Self.dateText(date))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Theme.sageDeep)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Theme.sageMist, in: .capsule)
                                    if entry.dateKind != .unknown {
                                        Text(entry.dateKind.badge)
                                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Theme.inkSoft)
                                    }
                                }
                            } else {
                                Text(S.Scan.addDate.s)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.terracotta)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(Theme.terracotta.opacity(0.15), in: .capsule)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .contentShape(.rect)
                    }
                    .buttonStyle(SoftPressStyle())

                    if entry.id != items.last?.id { Divider().padding(.leading, 72) }
                }
            }
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
            .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button(S.Scan.addToStock.s, action: onConfirm)
                .buttonStyle(SaveatButtonStyle())
                .disabled(entries.isEmpty)
                .opacity(entries.isEmpty ? 0.5 : 1)

            Text(S.Scan.addToStockNote.s)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.bottom, 18)
        .padding(.top, 8)
        .background(Theme.cream)
    }

    /// Compact date in the reader's own order: 12/09/26 in France, 9/12/26 in the US.
    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageRuntime.current.locale
        formatter.setLocalizedDateFormatFromTemplate("ddMMyy")
        return formatter.string(from: date)
    }
}

/// Editor for a scanned line: quantity, storage place and best-before date.
struct ScanEntryEditor: View {
    @Environment(\.dismiss) private var dismiss

    let entry: ScanEntry
    let onSave: (ScanEntry) -> Void

    @State private var draft: ScanEntry
    @State private var hasDate: Bool
    @State private var date: Date
    @State private var dateKind: DateKind
    @State private var showsDateCapture = false

    init(entry: ScanEntry, onSave: @escaping (ScanEntry) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _draft = State(initialValue: entry)
        _hasDate = State(initialValue: entry.bestBefore != nil)
        _date = State(initialValue: entry.bestBefore ?? Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now)
        _dateKind = State(initialValue: entry.dateKind)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        ProductThumb(product: draft.product, size: 66, radius: 18)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(draft.product.displayTitle)
                                .font(Theme.title(17))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if !draft.product.subtitle.isEmpty {
                                Text(draft.product.subtitle)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                        Spacer(minLength: 0)
                        ScoreChip(value: draft.product.score.value, tone: draft.product.score.tone)
                    }
                    .saveatCard()

                    // Direct route to the full nutrition read of the product just scanned.
                    NavigationLink(value: draft.product) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.doc.horizontal")
                            Text(S.Scan.seeNutrition.s)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.sageDeep)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Theme.sageMist, in: .capsule)
                    }
                    .buttonStyle(SoftPressStyle())

                    VStack(spacing: 14) {
                        HStack {
                            Text(S.AddFood.quantity.s).font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            StockStepper(value: $draft.quantity, step: 1, range: 1...50)
                        }
                        Divider()
                        HStack {
                            Text(S.AddFood.storage.s).font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            Picker("", selection: $draft.location) {
                                ForEach(StorageLocation.allCases) { Text("\($0.emoji) \($0.title)").tag($0) }
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
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()

                            Divider()

                            Text(S.AddFood.dateType.s)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            DateKindPicker(kind: $dateKind)
                        }

                        Button {
                            showsDateCapture = true
                            Haptics.light()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.viewfinder")
                                Text(S.Scan.photographDate.s)
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.sageDeep)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.sageMist, in: .capsule)
                        }
                        .buttonStyle(SoftPressStyle())

                        Text(S.Scan.editorDateNote.s)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .saveatCard()
                }
                .padding(.horizontal, Theme.hMargin)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .saveatBackground()
            .navigationDestination(for: ScannedProduct.self) { product in
                ProductDetailView(product: product)
            }
            .navigationTitle(S.Scan.editorTitle.s)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(S.Common.cancel.s) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(S.Common.save.s) {
                        var updated = draft
                        updated.bestBefore = hasDate ? date : nil
                        updated.dateKind = hasDate ? dateKind : .unknown
                        onSave(updated)
                        Haptics.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .fullScreenCover(isPresented: $showsDateCapture) {
                ExpiryDateCaptureView { detected in
                    date = detected
                    hasDate = true
                }
            }
        }
    }
}
