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
            ["role": "system", "content": Self.systemPrompt(for: LanguageRuntime.current)],
            ["role": "user", "content": userPrompt(inventory: inventory, profile: profile, request: request)]
        ]
        if !request.history.isEmpty {
            let recap = Prompt.history.s + "\n" + request.history.suffix(6).joined(separator: "\n")
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

    /// System prompt in the reader's language.
    ///
    /// Both versions carry the same rules; only the language, the measurements
    /// and the currency of the estimates change, so a US cook gets cups, ounces
    /// and Fahrenheit rather than a converted French recipe.
    private nonisolated static func systemPrompt(for language: AppLanguage) -> String {
        switch language {
        case .fr: frenchSystemPrompt
        case .en: englishSystemPrompt
        }
    }

    private nonisolated static let frenchSystemPrompt = """
    Tu es l'assistant cuisine anti-gaspillage de l'application française SAVEAT.
    Tu tutoies l'utilisateur et tu réponds toujours en français.

    Règles absolues :
    1. Tu cuisines EN PRIORITÉ avec le stock fourni. N'invente jamais un aliment absent du stock sans le déclarer comme ingrédient à acheter.
    2. Tu utilises d'abord les produits marqués URGENT, puis BIENTOT, puis les produits entamés.
    3. Les recettes doivent être simples, réalistes et rapides à faire chez soi.
    4. Tu limites au maximum les ingrédients à acheter. Les basiques (sel, poivre, huile, eau, épices, vinaigre, sucre) sont marqués "isStaple": true et coûtent 0.
    5. Si le mode "zéro euro" est demandé, TOUS les ingrédients doivent venir du stock ou être des basiques. Aucun achat.
    6. Les prix sont des estimations en euros pour la France.
    7. Les quantités sont en grammes, millilitres et degrés Celsius.
    8. Aucune allégation médicale, aucune affirmation sur la sécurité sanitaire d'un aliment.

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

    private nonisolated static let englishSystemPrompt = """
    You are the food-saving cooking assistant inside SAVEAT, writing for a home cook in the United States.
    Reply in natural American English — friendly, direct, never translated-sounding.

    Hard rules:
    1. Cook FIRST from the food provided. Never assume an ingredient that isn't listed without declaring it as something to buy.
    2. Use items marked URGENT first, then SOON, then anything already opened.
    3. Recipes must be simple, realistic and quick to make at home.
    4. Keep the shopping list as short as possible. Pantry basics (salt, pepper, oil, water, spices, vinegar, sugar) are marked isStaple true and cost 0.
    5. In $0 mode, EVERY ingredient must come from the food listed or be a pantry basic. Nothing may be bought.
    6. Prices are rough estimates in US dollars.
    7. Use US measurements everywhere: cups, tablespoons, teaspoons, ounces, pounds, fluid ounces, and Fahrenheit for oven temperatures. Never write grams, milliliters or Celsius.
    8. No medical claims, and never state whether a food is safe or unsafe to eat.

    Reply ONLY with a valid JSON object of this shape:
    {
      "message": "one short sentence to the user",
      "meals": [
        {
          "name": "Ham, Egg & Zucchini Fried Rice",
          "emoji": "🍳",
          "summary": "one sentence",
          "prepMinutes": 8,
          "cookMinutes": 10,
          "difficulty": "Easy",
          "servings": 2,
          "kcalPerServing": 480,
          "proteinsPerServing": 26,
          "tags": ["Quick", "Zero waste"],
          "antiWasteNote": "Uses up your opened ham and your zucchini",
          "ingredients": [
            {"name": "Eggs", "quantityText": "3", "estimatedPrice": 0, "isStaple": false}
          ],
          "steps": ["step 1", "step 2"]
        }
      ]
    }
    Give between 3 and 6 meals.
    """

    /// Wording used to describe the household stock and constraints to the model.
    private nonisolated enum Prompt {
        static let history = Loc(
            fr: "Historique de la conversation :",
            en: "Conversation so far:"
        )
        static let stockHeader = Loc(
            fr: "Stock actuel du foyer :",
            en: "What this household has right now:"
        )
        static let emptyStock = Loc(fr: "- (stock vide)", en: "- (nothing logged yet)")
        static let constraintsHeader = Loc(fr: "Contraintes :", en: "Constraints:")
        static let userAsk = Loc(fr: "Demande de l'utilisateur : %@", en: "User's request: %@")
        static let defaultAsk = Loc(
            fr: "Qu'est-ce qu'on mange avec ce que j'ai ?",
            en: "What can I cook with what I have?"
        )
        static let opened = Loc(fr: ", entamé", en: ", already opened")
        static let daysLeft = Loc(fr: ", à consommer sous %d j", en: ", use within %d days")
        static let household = Loc(fr: "Foyer : %@.", en: "Household: %@.")
        static let goal = Loc(fr: "Objectif : %@.", en: "Goal: %@.")
        static let diet = Loc(fr: "Régime : %@.", en: "Diet: %@.")
        static let servings = Loc(fr: "Portions demandées : %d.", en: "Servings requested: %d.")
        static let allergies = Loc(
            fr: "Allergies à exclure absolument : %@.",
            en: "Allergies that must be excluded entirely: %@."
        )
        static let dislikes = Loc(fr: "N'aime pas : %@.", en: "Dislikes: %@.")
        static let zeroCost = Loc(
            fr: "MODE REPAS À 0 € : aucun achat autorisé, uniquement le stock et les basiques.",
            en: "$0 MEAL MODE: nothing may be bought — only what's listed plus pantry basics."
        )
        static let maxTime = Loc(
            fr: "Temps total maximum : %d minutes.",
            en: "Maximum total time: %d minutes."
        )
        static let focus = Loc(
            fr: "À sauver en priorité : %@.",
            en: "Use these up first: %@."
        )
        static let foundZeroCost = Loc(
            fr: "J'ai trouvé %d repas à 0 € avec ton stock.",
            en: "Found %d meals you can make without buying anything."
        )
        static let found = Loc(
            fr: "J'ai trouvé %d repas avec ce que tu as.",
            en: "Found %d meals from what you already have."
        )
        static let emptyAnswer = Loc(
            fr: "Ton stock est un peu court pour l'instant. Scanne tes courses et je te proposerai des repas.",
            en: "There isn't much to work with yet. Scan your groceries and I'll come back with meals."
        )
    }

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
                let opened = item.isOpened ? Prompt.opened.s : ""
                let deadline = item.daysLeft.map { Prompt.daysLeft.f($0) } ?? ""
                let unit = FoodUnits.display(item.unit, quantity: item.quantity)
                return "- \(item.displayName) : \(item.quantityText) \(unit), \(item.location.shortTitle), \(urgency)\(opened)\(deadline)"
            }
            .joined(separator: "\n")

        var constraints: [String] = [
            Prompt.household.f(profile.householdText),
            Prompt.goal.f(profile.goal.title),
            Prompt.diet.f(profile.diet.title),
            Prompt.servings.f(request.servings)
        ]
        if !profile.allergens.isEmpty {
            constraints.append(Prompt.allergies.f(profile.allergens.map(\.title).joined(separator: ", ")))
        }
        if !profile.dislikes.isEmpty {
            // Exclusions are stored in French; send them in the reader's language
            // so the model matches them against the recipe it is writing.
            let list = profile.dislikes.sorted().map(DislikeCatalog.display).joined(separator: ", ")
            constraints.append(Prompt.dislikes.f(list))
        }
        if request.zeroEuroOnly {
            constraints.append(Prompt.zeroCost.s)
        }
        if let minutes = request.maxMinutes {
            constraints.append(Prompt.maxTime.f(minutes))
        }
        if !request.focusNames.isEmpty {
            let list = request.focusNames.map(FoodNames.display).joined(separator: ", ")
            constraints.append(Prompt.focus.f(list))
        }

        let ask = request.userText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let question = (ask?.isEmpty == false) ? ask! : Prompt.defaultAsk.s

        return """
        \(Prompt.stockHeader.s)
        \(stock.isEmpty ? Prompt.emptyStock.s : stock)

        \(Prompt.constraintsHeader.s)
        \(constraints.map { "- \($0)" }.joined(separator: "\n"))

        \(Prompt.userAsk.f(question))
        """
    }

    private nonisolated func defaultMessage(count: Int, request: Request) -> String {
        request.zeroEuroOnly
            ? Prompt.foundZeroCost.f(count)
            : Prompt.found.f(count)
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
            ? Prompt.emptyAnswer.s
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
