import SwiftUI

/// A request handed to the assistant from another screen.
nonisolated struct MealPrompt: Equatable, Sendable {
    var text: String?
    var zeroEuroOnly: Bool = false
    var focusNames: [String] = []
}

/// One line of the conversation.
private struct Bubble: Identifiable, Equatable {
    enum Role { case user, assistant }
    var id: UUID = UUID()
    var role: Role
    var text: String
}

/// 🤖 QU'EST-CE QU'ON MANGE ? — the assistant cooks with the real stock.
struct MealAssistantView: View {
    @Environment(AppStore.self) private var store
    @Environment(SubscriptionStore.self) private var subscriptions
    @Binding var path: NavigationPath
    @Binding var prompt: MealPrompt?

    @State private var showsPaywall = false

    @State private var bubbles: [Bubble] = []
    @State private var meals: [Meal] = []
    @State private var isThinking = false
    @State private var draft = ""
    @State private var servings = 2
    @State private var zeroEuroOnly = false
    @State private var usedAI = true
    @State private var hasLoaded = false

    private let quickAsks: [String] = [
        "Quelque chose de rapide ce soir",
        "Maximum 15 minutes",
        "Sans viande",
        "Riche en protéines",
        "Moins de 500 kcal",
        "Repas économique",
        "Pour les enfants",
        "Quelque chose de réconfortant",
        "Repas léger",
        "Sans lactose"
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if !store.urgentItems.isEmpty { rescueBanner }
                    aiQuotaCard
                    conversation
                    if isThinking { thinkingCard }
                    if !meals.isEmpty { mealsSection }
                    quickAskSection
                }
                .padding(.horizontal, Theme.hMargin)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)

            composer
        }
        .saveatBackground()
        .sheet(isPresented: $showsPaywall) { PaywallSheet(feature: .unlimitedAI) }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            servings = store.profile.householdSize
            await ask(nil)
        }
        .onChange(of: prompt) { _, newValue in
            guard let newValue else { return }
            prompt = nil
            zeroEuroOnly = newValue.zeroEuroOnly
            Task { await ask(newValue.text, focusNames: newValue.focusNames) }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Theme.sageMist).frame(width: 48, height: 48)
                    Text("🤖").font(.system(size: 24))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Qu'est-ce qu'on mange ?")
                        .font(Theme.display(21))
                        .foregroundStyle(Theme.ink)
                    Text("Je cuisine avec tes \(store.totalProducts) produits")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text("Personnes")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                    QuantityStepper(value: $servings, range: 1...12)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Theme.surface, in: .capsule)

                Button {
                    zeroEuroOnly.toggle()
                    Haptics.light()
                    Task { await ask(zeroEuroOnly ? "Uniquement avec ce que j'ai, sans rien acheter" : nil) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: zeroEuroOnly ? "checkmark.circle.fill" : "eurosign.circle")
                            .font(.system(size: 13, weight: .semibold))
                        Text("0 €")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(zeroEuroOnly ? .white : Theme.sageDeep)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(zeroEuroOnly ? Theme.sage : Theme.surface, in: .capsule)
                }
                .buttonStyle(SoftPressStyle())

                Spacer(minLength: 0)
            }
        }
        .padding(.top, 6)
        .onChange(of: servings) { _, newValue in
            // Only re-ask once the first suggestions are on screen.
            guard hasLoaded, !isThinking else { return }
            Task { await ask("Pour \(newValue) personne\(newValue > 1 ? "s" : "")") }
        }
    }

    /// Free tier: a gentle counter, then a lock — never a dead end.
    @ViewBuilder
    private var aiQuotaCard: some View {
        if !subscriptions.isPremium {
            if subscriptions.canAskAI {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.sageDeep)
                    Text("\(subscriptions.remainingAIRequests) suggestion\(subscriptions.remainingAIRequests > 1 ? "s" : "") IA restante\(subscriptions.remainingAIRequests > 1 ? "s" : "") aujourd'hui")
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer(minLength: 0)
                    Button("Premium") {
                        Haptics.light()
                        showsPaywall = true
                    }
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.sageDeep)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.sageMist, in: .capsule)
            } else {
                PremiumLockCard(
                    feature: .unlimitedAI,
                    message: "Tes \(SubscriptionStore.freeDailyAIRequests) suggestions IA du jour sont utilisées. Les idées ci-dessous restent basées sur ton stock."
                ) {
                    Haptics.light()
                    showsPaywall = true
                }
            }
        }
    }

    private var rescueBanner: some View {
        Button {
            Haptics.light()
            Task {
                await ask("Utilise en priorité ce qui va se perdre",
                          focusNames: store.urgentItems.map(\.name))
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("🔴").font(.system(size: 13))
                    Text("\(store.urgentItems.count) produits à sauver")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
                Text(store.urgentItems.prefix(4).map(\.name).joined(separator: " • "))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                Text("Je peux préparer ton dîner avec ces aliments avant qu'ils ne soient gaspillés.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.clay)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.clay.opacity(0.09), in: .rect(cornerRadius: Theme.tileRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .stroke(Theme.clay.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(SoftPressStyle())
    }

    // MARK: Conversation

    private var conversation: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(bubbles.suffix(6)) { bubble in
                HStack {
                    if bubble.role == .user { Spacer(minLength: 40) }
                    Text(bubble.text)
                        .font(.system(size: 15, weight: bubble.role == .assistant ? .semibold : .medium, design: .rounded))
                        .foregroundStyle(bubble.role == .assistant ? Theme.ink : .white)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(
                            bubble.role == .assistant ? AnyShapeStyle(Theme.surface) : AnyShapeStyle(Theme.sage),
                            in: .rect(cornerRadius: 18)
                        )
                        .shadow(color: Theme.ink.opacity(bubble.role == .assistant ? 0.04 : 0), radius: 8, y: 3)
                    if bubble.role == .assistant { Spacer(minLength: 40) }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: bubbles.count)
    }

    private var thinkingCard: some View {
        HStack(spacing: 12) {
            ProgressView().tint(Theme.sageDeep)
            Text("Je regarde ton stock…")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 0)
        }
        .padding(15)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
    }

    // MARK: Meals

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(text: "\(meals.count) repas trouvés")
                Spacer()
                if !usedAI {
                    Text("mode hors ligne")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            ForEach(meals) { meal in
                NavigationLink(value: Route.meal(meal)) {
                    MealCard(meal: meal)
                }
                .buttonStyle(SoftPressStyle())
            }
        }
    }

    private var quickAskSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Dis-moi ce que tu veux")
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(quickAsks, id: \.self) { ask in
                        Button {
                            Task { await self.ask(ask) }
                        } label: {
                            Text(ask)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.sageDeep)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Theme.surface, in: .capsule)
                        }
                        .buttonStyle(SoftPressStyle())
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: Composer

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Écris ta demande…", text: $draft, axis: .vertical)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .lineLimit(1...3)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.surface, in: .capsule)
                .submitLabel(.send)
                .onSubmit { send() }

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(draft.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.inkSoft.opacity(0.5) : Theme.sage, in: .circle)
            }
            .buttonStyle(SoftPressStyle())
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || isThinking)
            .accessibilityLabel("Envoyer")
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.vertical, 10)
        .background(Theme.creamDeep)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        draft = ""
        Task { await ask(text) }
    }

    // MARK: Assistant

    private func ask(_ text: String?, focusNames: [String] = []) async {
        guard !isThinking else { return }

        if let text, !text.isEmpty {
            withAnimation { bubbles.append(Bubble(role: .user, text: text)) }
            Haptics.light()
        }

        // Free tier keeps the curated engine; the AI generation is the premium part.
        let usesAI = subscriptions.canAskAI
        if !usesAI, text != nil {
            showsPaywall = true
        }

        if let people = RequestParser.servings(in: text ?? ""), people != servings {
            servings = people
        }

        isThinking = true

        let request = MealAIService.Request(
            userText: text,
            servings: servings,
            zeroEuroOnly: zeroEuroOnly,
            maxMinutes: RequestParser.maxMinutes(in: text ?? ""),
            focusNames: focusNames,
            history: bubbles.suffix(6).map { "\($0.role == .user ? "Utilisateur" : "SAVEAT") : \($0.text)" }
        )

        let answer: MealAIService.Answer
        if usesAI {
            subscriptions.registerAIRequest()
            answer = await MealAIService.shared.meals(
                inventory: store.inventory,
                profile: store.profile,
                request: request
            )
        } else {
            answer = MealAIService.Answer(message: "", meals: [], isFromAI: false)
        }

        var ranked = MealEngine.rank(
            answer.meals,
            inventory: store.inventory,
            profile: store.profile,
            zeroEuroOnly: zeroEuroOnly,
            maxMinutes: request.maxMinutes
        )

        if ranked.isEmpty {
            ranked = MealEngine.curatedSuggestions(
                inventory: store.inventory,
                profile: store.profile,
                zeroEuroOnly: zeroEuroOnly,
                maxMinutes: request.maxMinutes,
                focusNames: focusNames,
                servings: servings
            )
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
            meals = Array(ranked.prefix(6))
            usedAI = answer.isFromAI
            bubbles.append(Bubble(role: .assistant, text: assistantLine(answer: answer, count: meals.count)))
            isThinking = false
        }
        Haptics.soft()
    }

    private func assistantLine(answer: MealAIService.Answer, count: Int) -> String {
        guard count > 0 else {
            return "Ton stock est un peu court pour cette demande. Scanne tes courses et je te proposerai des repas."
        }
        if zeroEuroOnly {
            return "J'ai trouvé \(count) repas à 0 € avec ton stock. Aucun achat nécessaire."
        }
        return answer.message.isEmpty ? "J'ai trouvé \(count) repas avec ce que tu as." : answer.message
    }
}

/// Reads simple constraints from what the user typed.
nonisolated enum RequestParser {
    nonisolated static func maxMinutes(in text: String) -> Int? {
        let normalized = MealEngine.normalize(text)
        guard normalized.contains("min") || normalized.contains("rapide") || normalized.contains("vite") else { return nil }

        let pattern = #"(\d{1,3})\s*(min|minutes)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
           let range = Range(match.range(at: 1), in: normalized),
           let value = Int(normalized[range]) {
            return value
        }
        return 20
    }

    nonisolated static func servings(in text: String) -> Int? {
        let normalized = MealEngine.normalize(text)
        let pattern = #"pour\s*(\d{1,2})\s*(personne|personnes|pers)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
              let range = Range(match.range(at: 1), in: normalized),
              let value = Int(normalized[range]) else { return nil }
        return min(max(value, 1), 12)
    }
}
