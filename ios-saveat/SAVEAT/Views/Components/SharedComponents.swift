import SwiftUI

/// Coloured dot expressing the freshness bucket of a food item.
struct FreshnessDot: View {
    let state: FreshnessState
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(Self.color(for: state))
            .frame(width: size, height: size)
    }

    static func color(for state: FreshnessState) -> Color {
        switch state {
        case .fresh: Theme.sage
        case .soon: Theme.terracotta
        case .urgent: Theme.clay
        }
    }
}

/// Rounded emoji medallion used in every food row.
struct FoodBadge: View {
    let emoji: String
    var tint: Color = Theme.sageMist
    var size: CGFloat = 42

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.48))
            .frame(width: size, height: size)
            .background(tint, in: .circle)
    }
}

/// Product photo from the food database, with a graceful emoji placeholder.
struct ProductThumb: View {
    let product: ScannedProduct?
    var fallbackEmoji: String = "🥫"
    var size: CGFloat = 56
    var radius: CGFloat = 14

    var body: some View {
        Theme.sageMist
            .frame(width: size, height: size)
            .overlay {
                if let url = product?.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                        default:
                            Text(product?.emoji ?? fallbackEmoji).font(.system(size: size * 0.42))
                        }
                    }
                } else {
                    Text(product?.emoji ?? fallbackEmoji).font(.system(size: size * 0.42))
                }
            }
            .clipShape(.rect(cornerRadius: radius))
    }
}

/// Soft pill used for metadata (times, counts, tags).
struct SoftPill: View {
    let text: String
    var tint: Color = Theme.sageDeep
    var background: Color = Theme.sageMist
    var icon: String?

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(background, in: .capsule)
    }
}

/// Animated sage progress ring for the weekly goal.
struct ProgressRing: View {
    let fraction: Double
    var lineWidth: CGFloat = 14
    var size: CGFloat = 132

    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.sageMist, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animated)
                .stroke(
                    AngularGradient(colors: [Theme.sage, Theme.sageDeep, Theme.sage], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(Int((fraction * 100).rounded()))")
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.ink)
                + Text(" %")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("de ton objectif")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.1, dampingFraction: 0.85).delay(0.15)) {
                animated = fraction
            }
        }
        .onChange(of: fraction) { _, newValue in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) { animated = newValue }
        }
        .accessibilityElement()
        .accessibilityLabel("Objectif hebdomadaire")
        .accessibilityValue("\(Int(fraction * 100)) pour cent")
    }
}

/// Big animated SAVEAT score dial shown on the product page.
struct ScoreDial: View {
    let score: SaveatScore
    var size: CGFloat = 128

    @State private var animated: Double = 0

    private var tint: Color { ScoreTint.color(for: score.tone) }

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.15), lineWidth: 13)
            Circle()
                .trim(from: 0, to: animated)
                .stroke(tint, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: -2) {
                Text("\(score.value)")
                    .font(.system(size: size * 0.32, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Text("/ 100")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.85).delay(0.1)) {
                animated = Double(score.value) / 100
            }
        }
        .onChange(of: score.value) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                animated = Double(newValue) / 100
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Score SAVEAT")
        .accessibilityValue("\(score.value) sur 100, \(score.label)")
    }
}

/// Compact score chip for lists.
struct ScoreChip: View {
    let value: Int
    var tone: ScoreTone

    var body: some View {
        Text("\(value)")
            .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(ScoreTint.color(for: tone), in: .circle)
    }
}

nonisolated enum ScoreTint {
    static func color(for tone: ScoreTone) -> Color {
        switch tone {
        case .good: Theme.sage
        case .medium: Theme.terracotta
        case .poor: Theme.clay
        case .neutral: Theme.inkSoft
        }
    }
}

/// Thin animated progress bar used in challenges and plans.
struct SoftProgressBar: View {
    let fraction: Double
    var tint: Color = Theme.sage
    var height: CGFloat = 8

    @State private var animated: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.16))
                Capsule()
                    .fill(tint)
                    .frame(width: max(geo.size.width * animated, animated > 0 ? height : 0))
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.1)) { animated = fraction }
        }
        .onChange(of: fraction) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { animated = newValue }
        }
    }
}

/// One row of the stock lists.
struct FoodRow: View {
    let item: FoodItem
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            ProductThumb(product: item.product, fallbackEmoji: item.emoji, size: 46, radius: 13)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.stockLine)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                    if item.isOpened {
                        Text("• entamé")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.terracotta)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(item.deadlineText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(FreshnessDot.color(for: item.freshness))
                if let score = item.product?.score, score.hasEnoughData {
                    Text("SAVEAT \(score.value)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft.opacity(0.6))
            }
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 16)
        .contentShape(.rect)
    }
}

/// Compact stepper used for whole counts.
struct QuantityStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...99

    var body: some View {
        HStack(spacing: 0) {
            stepButton(symbol: "minus", enabled: value > range.lowerBound) {
                value = max(value - 1, range.lowerBound)
            }
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.ink)
                .frame(minWidth: 28)
            stepButton(symbol: "plus", enabled: value < range.upperBound) {
                value = min(value + 1, range.upperBound)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background(Theme.sageMist, in: .capsule)
    }

    private func stepButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.light()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(enabled ? Theme.sageDeep : Theme.inkSoft.opacity(0.4))
                .frame(width: 30, height: 30)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Stepper for stock quantities that can be halved (opened packs).
struct StockStepper: View {
    @Binding var value: Double
    var step: Double = 0.5
    var range: ClosedRange<Double> = 0...99

    var body: some View {
        HStack(spacing: 0) {
            stepButton(symbol: "minus", enabled: value > range.lowerBound) {
                value = max(((value - step) * 100).rounded() / 100, range.lowerBound)
            }
            Text(Format.quantity(value))
                .font(.system(size: 16, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.ink)
                .frame(minWidth: 34)
                .contentTransition(.numericText())
            stepButton(symbol: "plus", enabled: value < range.upperBound) {
                value = min(((value + step) * 100).rounded() / 100, range.upperBound)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background(Theme.sageMist, in: .capsule)
    }

    private func stepButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.light()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(enabled ? Theme.sageDeep : Theme.inkSoft.opacity(0.4))
                .frame(width: 30, height: 30)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Meal suggestion card used by the assistant, rescue mode and zero-euro mode.
struct MealCard: View {
    let meal: Meal
    var isCompact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isCompact, let imageName = meal.imageName, UIImage(named: imageName) != nil {
                Theme.sageMist
                    .frame(height: 148)
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Text(meal.emoji).font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(meal.name)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        Text("\(meal.timeText) • \(meal.difficulty) • \(meal.servings) personne\(meal.servings > 1 ? "s" : "")")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    if meal.isZeroEuro {
                        SoftPill(text: "Tu as tout ce qu'il faut", tint: Theme.sageDeep, background: Theme.sageMist, icon: "checkmark.seal.fill")
                    } else {
                        SoftPill(text: meal.availabilityText, tint: Theme.terracotta, background: Theme.terracotta.opacity(0.14))
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(meal.isZeroEuro ? "0 €" : "+ \(Format.euro(meal.extraCost))")
                            .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(meal.isZeroEuro ? Theme.sageDeep : Theme.terracotta)
                        Text(meal.isZeroEuro ? "à dépenser" : "estimé")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }

                if let note = meal.antiWasteNote, !note.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill").font(.system(size: 10))
                        Text(note)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(Theme.sageDeep)
                }
            }
            .padding(16)
        }
        .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
        .clipShape(.rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.ink.opacity(0.05), radius: 12, y: 4)
    }
}

/// Empty-state block reused across the app.
struct SoftEmptyState: View {
    let emoji: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji).font(.system(size: 40))
            Text(title)
                .font(Theme.title(18))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SaveatButtonStyle())
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
    }
}

/// Lightweight haptics helper.
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func rigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

/// Floating confirmation banner.
struct BannerView: View {
    let message: BannerMessage

    private var background: Color {
        switch message.tone {
        case .success: Theme.sageDeep
        case .info: Theme.ink.opacity(0.9)
        case .warning: Theme.clay
        }
    }

    private var symbol: String {
        switch message.tone {
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
            Text(message.text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(background, in: .rect(cornerRadius: 18))
        .shadow(color: Theme.ink.opacity(0.18), radius: 14, y: 6)
        .padding(.horizontal, Theme.hMargin)
    }
}
