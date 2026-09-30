import SwiftUI

/// The "Alternatives" card on a product sheet — real, already-known
/// products only (see `AlternativeEngine`), ranked by `SaveatScore`.
/// Always rendered, even with zero results: an explicit empty state,
/// never a hidden section pretending nothing was checked.
struct AlternativesSectionView: View {
    let alternatives: [AlternativeEngine.Alternative]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: S.Alternatives.sectionTitle.s)
            Text(S.Alternatives.subtitle.s)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)

            if alternatives.isEmpty {
                Text(S.Alternatives.emptyState.s)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 10) {
                    ForEach(alternatives) { alternative in
                        NavigationLink(value: Route.product(alternative.product)) {
                            row(for: alternative)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .saveatCard()
    }

    private func row(for alternative: AlternativeEngine.Alternative) -> some View {
        HStack(spacing: 12) {
            ProductThumb(product: alternative.product, size: 48, radius: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(alternative.product.displayTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                if !alternative.product.subtitle.isEmpty {
                    Text(alternative.product.subtitle)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(spacing: 2) {
                Text("\(alternative.score.value)")
                    .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(ScoreTint.color(for: alternative.score.tone))
                Text(alternative.score.label)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(10)
        .background(Theme.creamDeep, in: .rect(cornerRadius: 14))
    }
}
