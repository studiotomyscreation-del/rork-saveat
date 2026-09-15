import SwiftUI

/// Category + search-radius filters for the SAVEAT Local map, presented as a sheet.
struct MapFiltersView: View {
    /// Only categories actually present on the map today — see
    /// `AntiWasteMapViewModel.availableCategories`.
    let categories: [AntiWasteCategory]
    @Binding var selectedCategory: AntiWasteCategory?
    @Binding var radiusKm: Double
    var onDone: () -> Void

    private static let radii: [Double] = [1, 5, 10, 25, 50]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: S.Map.categoriesSectionLabel.s)
                        VStack(spacing: 8) {
                            categoryRow(nil, title: S.Intro.mapFilterAll.s, icon: "square.grid.2x2.fill")
                            ForEach(categories) { category in
                                categoryRow(category, title: category.title, icon: category.icon)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: S.Map.radiusSectionLabel.s)
                        HStack(spacing: 8) {
                            ForEach(Self.radii, id: \.self) { radius in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { radiusKm = radius }
                                    Haptics.light()
                                } label: {
                                    Text("\(Int(radius)) km")
                                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(radiusKm == radius ? SaveatColors.textOnDark : SaveatColors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(minHeight: 40)
                                        .background(
                                            radiusKm == radius ? SaveatColors.brand : SaveatColors.surface,
                                            in: .capsule
                                        )
                                }
                                .buttonStyle(SoftPressStyle())
                            }
                        }
                    }
                }
                .padding(Theme.hMargin)
            }
            .background(SaveatColors.background.ignoresSafeArea())
            .navigationTitle(S.Map.filtersButton.s)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(S.Common.done.s, action: onDone)
                }
            }
        }
    }

    private func categoryRow(_ category: AntiWasteCategory?, title: String, icon: String) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selectedCategory = category }
            Haptics.light()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(category?.tint ?? SaveatColors.forestDeep)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaveatColors.textPrimary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19))
                    .foregroundStyle(isSelected ? SaveatColors.brand : SaveatColors.textSecondary.opacity(0.4))
            }
            .padding(14)
            .background(SaveatColors.surface, in: .rect(cornerRadius: Theme.tileRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .stroke(isSelected ? SaveatColors.brand : .clear, lineWidth: 1.6)
            }
        }
        .buttonStyle(SoftPressStyle())
    }
}

#Preview {
    MapFiltersView(
        categories: AntiWasteCategory.visibleCases,
        selectedCategory: .constant(nil),
        radiusKm: .constant(10),
        onDone: {}
    )
}
