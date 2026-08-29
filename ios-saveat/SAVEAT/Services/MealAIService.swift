import Foundation

/// Talks to the Rork Toolkit AI proxy to invent meals from the household stock.
///
/// The model only ever receives the inventory summary and the household
/// preferences. Every answer is re-checked against the real stock by
/// `MealEngine` before it reaches the UI.
nonisolated struct MealAIService: Sendable {
    nonisolated static let shared = MealAIService()

    private static let model = "google/gemini-3-flash"
    private static let fallbackModels = ["openai/gpt-4.1-mini", "anthropic/claude-haiku-4.5"]

    nonisolated struct Answer: Sendable {
        var message: String
        var meals: [Meal]
        var isFromAI: Bool
    }

    /// Constraints coming from the conversation ("sans viande", "moins de 20 min"…).
    nonisolated struct Request: Sendable {
        var userText: String?
        var servings: Int
        var zeroEuroOnly: Bool
        var maxMinutes: Int?
        var focusNames: [String]
        var history: [String]

        nonisolated init(
            userText: String? = nil,
            servings: Int = 2,
            zeroEuroOnly: Bool = false,
            maxMinutes: Int? = nil,
            focusNames: [String] = [],
            history: [String] = []
        ) {
            self.userText = userText
            self.servings = servings
            self.zeroEuroOnly = zeroEuroOnly
            self.maxMinutes = maxMinutes
            self.focusNames = focusNames
            self.history = history
        }
    }

    private var toolkitURL: String {
        let value = Config.EXPO_PUBLIC_TOOLKIT_URL
        return value.isEmpty ? "https://toolkit.rork.com" : value
    }

    /// Generates meals. Never throws: falls back to the curated engine so the
    /// screen always shows something useful.
    nonisolated func meals(
        inventory: [FoodItem],
        profile: UserProfile,
        request: Request
    ) async -> Answer {
        do {
            let payload = try await callModel(inventory: inventory, profile: profile, request: request)
            let meals = payload.meals.map { $0.toMeal() }
            guard !meals.isEmpty else { return localAnswer(inventory: inventory, profile: profile, request: request) }
            return Answer(
                message: payload.message ?? defaultMessage(count: meals.count, request: request),
                meals: meals,
                isFromAI: true
            )
        } catch {
            #if DEBUG
            print("[SAVEAT] Assistant indisponible, bascule sur le moteur local: \(error.localizedDescription)")
            #endif
            return localAnswer(inventory: inventory, profile: profile, request: request)
        }
    }

    // MARK: - Network

    private nonisolated func callModel(
        inventory: [FoodItem],
        profile: UserProfile,
        request: Request
    ) async throws -> MealAIPayload {
        guard let url = URL(string: "\(toolkitURL)/v2/vercel/v1/chat/completions") else {
            throw URLError(.badURL)
        }

        var messages: [[String: Any]] = [
            ["role": "system", "content": Self.systemPrompt],
            ["role": "user", "content": userPrompt(inventory: inventory, profile: profile, request: request)]
        ]
        if !request.history.isEmpty {
            let recap = "Historique de la conversation :\n" + request.history.suffix(6).joined(separator: "\n")
            messages.insert(["role": "user", "content": recap], at: 1)
        }

        let body: [String: Any] = [
            "model": Self.model,
            "messages": messages,
            "temperature": 0.7,
            "response_format": ["type": "json_object"],
            "providerOptions": ["gateway": ["models": Self.fallbackModels]]
        ]

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 45
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let key = Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY
        if !key.isEmpty {
            urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let completion = try JSONDecoder().decode(ChatCompletion.self, from: data)
        guard let content = completion.choices.first?.message.content, !content.isEmpty else {
            throw URLError(.cannotParseResponse)
        }

        let json = Self.extractJSON(from: content)
        guard let jsonData = json.data(using: .utf8) else { throw URLError(.cannotParseResponse) }
        return try JSONDecoder().decode(MealAIPayload.self, from: jsonData)
    }

    /// Models sometimes wrap JSON in prose or code fences — keep only the object.
    nonisolated static func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}"), start < end else {
            return trimmed
        }
        return String(trimmed[start...end])
    }

    // MARK: - Prompts

    private nonisolated static let systemPrompt = """
    Tu es l'assistant cuisine anti-gaspillage de l'application française SAVEAT.
    Tu tutoies l'utilisateur et tu réponds toujours en français.

    Règles absolues :
    1. Tu cuisines EN PRIORITÉ avec le stock fourni. N'invente jamais un aliment absent du stock sans le déclarer comme ingrédient à acheter.
    2. Tu utilises d'abord les produits marqués URGENT, puis BIENTOT, puis les produits entamés.
    3. Les recettes doivent être simples, réalistes et rapides à faire chez soi.
    4. Tu limites au maximum les ingrédients à acheter. Les basiques (sel, poivre, huile, eau, épices, vinaigre, sucre) sont marqués "isStaple": true et coûtent 0.
    5. Si le mode "zéro euro" est demandé, TOUS les ingrédients doivent venir du stock ou être des basiques. Aucun achat.
    6. Les prix sont des estimations en euros pour la France.
    7. Aucune allégation médicale, aucune affirmation sur la sécurité sanitaire d'un aliment.

    Réponds UNIQUEMENT avec un objet JSON valide de cette forme :
    {
      "message": "une phrase courte adressée à l'utilisateur",
      "meals": [
        {
          "name": "Riz sauté jambon, œufs & courgettes",
          "emoji": "🍳",
          "summary": "une phrase",
          "prepMinutes": 8,
          "cookMinutes": 10,
          "difficulty": "Facile",
          "servings": 2,
          "kcalPerServing": 480,
          "proteinsPerServing": 26,
          "tags": ["Express", "Anti-gaspi"],
          "antiWasteNote": "Utilise ton jambon ouvert et tes courgettes",
          "ingredients": [
            {"name": "Œufs", "quantityText": "3 pièces", "estimatedPrice": 0, "isStaple": false}
          ],
          "steps": ["étape 1", "étape 2"]
        }
      ]
    }
    Donne entre 3 et 6 repas.
    """

    private nonisolated func userPrompt(
        inventory: [FoodItem],
        profile: UserProfile,
        request: Request
    ) -> String {
        let stock = inventory
            .sorted { $0.freshness.order < $1.freshness.order }
            .prefix(45)
            .map { item -> String in
                let urgency: String
                switch item.freshness {
                case .urgent: urgency = "URGENT"
                case .soon: urgency = "BIENTOT"
                case .fresh: urgency = "OK"
                }
                let opened = item.isOpened ? ", entamé" : ""
                let deadline = item.daysLeft.map { ", à consommer sous \($0) j" } ?? ""
                return "- \(item.name) : \(item.quantityText) \(item.unit), \(item.location.shortTitle), \(urgency)\(opened)\(deadline)"
            }
            .joined(separator: "\n")

        var constraints: [String] = [
            "Foyer : \(profile.householdText).",
            "Objectif : \(profile.goal.title).",
            "Régime : \(profile.diet.title).",
            "Portions demandées : \(request.servings)."
        ]
        if !profile.allergens.isEmpty {
            constraints.append("Allergies à exclure absolument : \(profile.allergens.map(\.title).joined(separator: ", ")).")
        }
        if !profile.dislikes.isEmpty {
            constraints.append("N'aime pas : \(profile.dislikes.sorted().joined(separator: ", ")).")
        }
        if request.zeroEuroOnly {
            constraints.append("MODE REPAS À 0 € : aucun achat autorisé, uniquement le stock et les basiques.")
        }
        if let minutes = request.maxMinutes {
            constraints.append("Temps total maximum : \(minutes) minutes.")
        }
        if !request.focusNames.isEmpty {
            constraints.append("À sauver en priorité : \(request.focusNames.joined(separator: ", ")).")
        }

        let ask = request.userText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let question = (ask?.isEmpty == false) ? ask! : "Qu'est-ce qu'on mange avec ce que j'ai ?"

        return """
        Stock actuel du foyer :
        \(stock.isEmpty ? "- (stock vide)" : stock)

        Contraintes :
        \(constraints.map { "- \($0)" }.joined(separator: "\n"))

        Demande de l'utilisateur : \(question)
        """
    }

    private nonisolated func defaultMessage(count: Int, request: Request) -> String {
        request.zeroEuroOnly
            ? "J'ai trouvé \(count) repas à 0 € avec ton stock."
            : "J'ai trouvé \(count) repas avec ce que tu as."
    }

    // MARK: - Offline fallback

    private nonisolated func localAnswer(
        inventory: [FoodItem],
        profile: UserProfile,
        request: Request
    ) -> Answer {
        let meals = MealEngine.curatedSuggestions(
            inventory: inventory,
            profile: profile,
            zeroEuroOnly: request.zeroEuroOnly,
            maxMinutes: request.maxMinutes,
            focusNames: request.focusNames,
            servings: request.servings
        )
        let message = meals.isEmpty
            ? "Ton stock est un peu court pour l'instant. Scanne tes courses et je te proposerai des repas."
            : defaultMessage(count: meals.count, request: request)
        return Answer(message: message, meals: meals, isFromAI: false)
    }
}

// MARK: - OpenAI-compatible response

private nonisolated struct ChatCompletion: Decodable, Sendable {
    nonisolated struct Choice: Decodable, Sendable {
        nonisolated struct Message: Decodable, Sendable {
            var content: String?
        }
        var message: Message
    }
    var choices: [Choice]
}
