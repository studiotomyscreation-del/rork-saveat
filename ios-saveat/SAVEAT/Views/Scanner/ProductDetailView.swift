import SwiftUI

/// Transparent product sheet: SAVEAT score, why, nutrition, ingredients, allergens.
struct ProductDetailView: View {
    let product: ScannedProduct

    @State private var showsMethodology = false

    private var score: SaveatScore { product.score }
    private var analysis: NutritionAnalysis { product.nutritionAnalysis }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                identity
                scoreCard
                nutritionAnalysisCard
                if !score.criteria.isEmpty { criteriaCard }
                whyCard
                if !product.nutriments.isEmpty { nutritionCard }
                if !product.allergens.isEmpty { allergensCard }
                if let ingredients = product.ingredientsText, !ingredients.isEmpty { ingredientsCard(ingredients) }
                disclaimer
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 4)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle("Fiche produit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: Identity

    private var identity: some View {
        HStack(spacing: 16) {
            ProductThumb(product: product, size: 88, radius: 22)

            VStack(alignment: .leading, spacing: 5) {
                Text(product.displayTitle)
                    .font(Theme.title(19))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !product.subtitle.isEmpty {
                    Text(product.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
                Text(product.isDemoData ? "Fiche de démonstration" : "Base de données ouverte")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.sageDeep)
            }
            Spacer(minLength: 0)
        }
        .saveatCard()
    }

    // MARK: Score

    private var scoreCard: some View {
        VStack(spacing: 14) {
            SectionLabel(text: "Score SAVEAT")

            ScoreDial(score: score, size: 138)

            Text(score.label)
                .font(Theme.title(20))
                .foregroundStyle(ScoreTint.color(for: score.tone))

            if !score.hasEnoughData {
                Text("Données partielles pour ce produit — le score reste indicatif.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                if let grade = product.nutriScore?.uppercased(), !grade.isEmpty {
                    SoftPill(text: "Nutri-Score \(grade)")
                }
                if let nova = product.nova {
                    SoftPill(text: "NOVA \(nova)", tint: Theme.terracotta, background: Theme.terracotta.opacity(0.15))
                }
                SoftPill(
                    text: "\(product.additives.count) additif\(product.additives.count > 1 ? "s" : "")",
                    tint: product.additives.isEmpty ? Theme.sageDeep : Theme.clay,
                    background: (product.additives.isEmpty ? Theme.sage : Theme.clay).opacity(0.14)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .saveatCard(padding: 20)
    }

    // MARK: Nutritional analysis

    /// Plain-language read of the product, built only from published data.
    /// Anything the database does not provide is stated as unavailable.
    private var nutritionAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Analyse nutritionnelle")

            nutriScoreRow
            appreciationRow

            if !analysis.positives.isEmpty {
                pointsBlock(
                    title: "Points positifs",
                    color: Theme.sageDeep,
                    points: analysis.positives
                )
            }

            if !analysis.watchOuts.isEmpty {
                pointsBlock(
                    title: "Points à surveiller",
                    color: Theme.clay,
                    points: analysis.watchOuts
                )
            }

            additivesBlock

            Divider()

            Text(analysis.explanation)
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .saveatCard()
    }

    /// Official Nutri-Score scale — the published letter is highlighted, and the
    /// absence of a grade is stated explicitly instead of being guessed.
    @ViewBuilder
    private var nutriScoreRow: some View {
        if let grade = analysis.grade {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(NutriScoreGrade.allCases, id: \.self) { candidate in
                        let isCurrent = candidate == grade
                        Text(candidate.letter)
                            .font(.system(size: isCurrent ? 19 : 14, weight: .bold, design: .rounded))
                            .foregroundStyle(isCurrent ? .white : nutriScoreColor(candidate).opacity(0.55))
                            .frame(maxWidth: .infinity)
                            .frame(height: isCurrent ? 44 : 36)
                            .background(
                                nutriScoreColor(candidate).opacity(isCurrent ? 1 : 0.16),
                                in: .rect(cornerRadius: 12)
                            )
                    }
                }
                Text("Nutri-Score officiel \(grade.letter)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityElement()
            .accessibilityLabel("Nutri-Score officiel")
            .accessibilityValue(grade.letter)
        } else {
            HStack(spacing: 8) {
                Text("Nutri-Score")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Text(NutritionAnalysis.unavailableText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.creamDeep, in: .rect(cornerRadius: 14))
        }
    }

    /// Official Nutri-Score colours, kept close to the public scale.
    private func nutriScoreColor(_ grade: NutriScoreGrade) -> Color {
        switch grade {
        case .a: Color(red: 0.016, green: 0.502, blue: 0.278)
        case .b: Color(red: 0.502, green: 0.741, blue: 0.212)
        case .c: Color(red: 0.976, green: 0.788, blue: 0.086)
        case .d: Color(red: 0.929, green: 0.541, blue: 0.145)
        case .e: Color(red: 0.879, green: 0.204, blue: 0.161)
        }
    }

    private var appreciationRow: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text("Appréciation")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 8)
                if let verdict = analysis.verdict {
                    Text(verdict.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(ScoreTint.color(for: verdict.tone))
                        .multilineTextAlignment(.trailing)
                } else {
                    Text(NutritionAnalysis.unavailableText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Text(analysis.basis.caption)
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func pointsBlock(title: String, color: Color, points: [NutritionPoint]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title, color: color)
            ForEach(points) { point in
                HStack(alignment: .top, spacing: 9) {
                    Text(point.emoji).font(.system(size: 14))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(point.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(point.detail)
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var additivesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Additifs", color: analysis.additives.codes.isEmpty ? Theme.sageDeep : Theme.terracotta)

            Text(analysis.additives.summary)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            if analysis.additives.isKnown, !analysis.additives.codes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(analysis.additives.codes, id: \.self) { code in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Theme.terracotta).frame(width: 5, height: 5).padding(.top, 6)
                            Text(analysis.additives.describe(code))
                                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: Criteria

    private var criteriaCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(score.criteria.enumerated()), id: \.element.id) { index, criterion in
                HStack(spacing: 14) {
                    Text(criterion.emoji).font(.system(size: 20))
                        .frame(width: 38, height: 38)
                        .background(ScoreTint.color(for: criterion.tone).opacity(0.14), in: .circle)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(criterion.title)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                        Text(criterion.verdict)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(criterion.detail)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 4)

                    Text(criterion.pointsText)
                        .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(criterion.points >= 0 ? Theme.sageDeep : Theme.clay)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)

                if index < score.criteria.count - 1 {
                    Divider().padding(.leading, 68)
                }
            }
        }
        .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
    }

    // MARK: Why

    private var whyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { showsMethodology.toggle() }
                Haptics.light()
            } label: {
                HStack {
                    Text("Pourquoi cette note ?")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.sageDeep)
                        .rotationEffect(.degrees(showsMethodology ? 0 : -90))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if showsMethodology {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(SaveatScore.methodology, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Theme.sage).frame(width: 5, height: 5).padding(.top, 6)
                            Text(line)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .saveatCard()
    }

    // MARK: Nutrition

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Valeurs pour 100 g")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                nutrient("Énergie", product.nutriments.energyKcal.map { "\(Int($0)) kcal" })
                nutrient("Protéines", product.nutriments.proteins.map(Format.grams))
                nutrient("Glucides — sucres", product.nutriments.sugars.map(Format.grams))
                nutrient("Matières grasses", product.nutriments.fat.map(Format.grams))
                nutrient("dont saturées", product.nutriments.saturatedFat.map(Format.grams))
                nutrient("Sel", product.nutriments.salt.map(Format.grams))
                nutrient("Fibres", product.nutriments.fiber.map(Format.grams))
            }
        }
        .saveatCard()
    }

    @ViewBuilder
    private func nutrient(_ label: String, _ value: String?) -> some View {
        if let value {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(value)
                    .font(.system(size: 17, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Theme.creamDeep, in: .rect(cornerRadius: 14))
        }
    }

    // MARK: Allergens & ingredients

    private var allergensCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Allergènes déclarés", color: Theme.clay)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(product.allergens, id: \.self) { allergen in
                    Text(allergen.capitalized)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.clay)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Theme.clay.opacity(0.12), in: .capsule)
                }
            }
        }
        .saveatCard()
    }

    private func ingredientsCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Ingrédients")
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .saveatCard()
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle").font(.system(size: 12))
            Text("Informations issues de bases de données publiques et de l'étiquetage. Le score SAVEAT est une aide à la lecture, pas un avis médical. Réfère-toi toujours à l'emballage.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.inkSoft)
        .padding(14)
        .background(Theme.creamDeep, in: .rect(cornerRadius: 16))
    }
}
