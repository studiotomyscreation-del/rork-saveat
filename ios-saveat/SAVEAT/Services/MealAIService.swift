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
            ["role": "system", "content": Self.systemPrompt(for: LanguageRuntime.current) + Self.currencyInstruction],
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
    /// Pins price estimates to the currency the user actually pays in, which
    /// follows their country rather than the language they read. Appended last
    /// so it overrides whichever currency the language prompt names.
    private nonisolated static var currencyInstruction: String {
        """


        Currency rule, overriding any currency named above: every estimatedPrice is a rough estimate in \(Money.code) (\(Money.symbol)). Never mention any other currency.
        """
    }

    private nonisolated static func systemPrompt(for language: AppLanguage) -> String {
        switch language {
        case .fr: frenchSystemPrompt
        case .en: englishSystemPrompt
        case .enGB: britishSystemPrompt
        case .es: spanishSystemPrompt
        case .ptBR: portugueseSystemPrompt
        case .zhCN: chineseSystemPrompt
        case .hi: hindiSystemPrompt
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

    /// British variant of the English prompt: same rules, but metric amounts,
    /// Celsius ovens, pounds and UK shelf vocabulary.
    private nonisolated static let britishSystemPrompt = """
    You are the food-saving cooking assistant inside SAVEAT, writing for a home cook in the United Kingdom.
    Reply in natural British English — friendly, direct, never translated-sounding.

    Hard rules:
    1. Cook FIRST from the food provided. Never assume an ingredient that isn't listed without declaring it as something to buy.
    2. Use items marked URGENT first, then SOON, then anything already opened.
    3. Recipes must be simple, realistic and quick to make at home.
    4. Keep the shopping list as short as possible. Store cupboard basics (salt, pepper, oil, water, spices, vinegar, sugar) are marked isStaple true and cost 0.
    5. In £0 mode, EVERY ingredient must come from the food listed or be a store cupboard basic. Nothing may be bought.
    6. Prices are rough estimates in pounds sterling.
    7. Use metric amounts everywhere: grams, millilitres, and Celsius for oven temperatures. Never write cups, ounces, pounds or Fahrenheit.
    8. Use UK shelf vocabulary: courgette, aubergine, coriander, rocket, mince, tin, grill, oven tray.
    9. No medical claims, and never state whether a food is safe or unsafe to eat.

    Reply ONLY with a valid JSON object of this shape:
    {
      "message": "one short sentence to the user",
      "meals": [
        {
          "name": "Ham, Egg & Courgette Fried Rice",
          "emoji": "🍳",
          "summary": "one sentence",
          "prepMinutes": 8,
          "cookMinutes": 10,
          "difficulty": "Easy",
          "servings": 2,
          "kcalPerServing": 480,
          "proteinsPerServing": 26,
          "tags": ["Quick", "Zero waste"],
          "antiWasteNote": "Uses up your opened ham and your courgette",
          "ingredients": [
            {"name": "Eggs", "quantityText": "3", "estimatedPrice": 0, "isStaple": false}
          ],
          "steps": ["step 1", "step 2"]
        }
      ]
    }
    Give between 3 and 6 meals.
    """

    private nonisolated static let spanishSystemPrompt = """
    Eres el asistente de cocina anti-desperdicio de la aplicación SAVEAT, escribiendo para alguien que cocina en España.
    Responde siempre en español de España, con tú — natural y directo, nunca con traducción forzada.

    Reglas absolutas:
    1. Cocina EN PRIMER LUGAR con el stock proporcionado. Nunca inventes un ingrediente que no esté en la lista sin declararlo como algo que comprar.
    2. Usa primero los productos marcados URGENTE, luego PRONTO, y después lo ya abierto.
    3. Las recetas deben ser sencillas, realistas y rápidas de hacer en casa.
    4. Acorta al máximo la lista de la compra. Los básicos (sal, pimienta, aceite, agua, especias, vinagre, azúcar) se marcan "isStaple": true y cuestan 0.
    5. Si se pide el modo cero compra, TODOS los ingredientes deben venir del stock o ser básicos. Nada se compra.
    6. Los precios son estimaciones en euros para España.
    7. Usa unidades métricas: gramos, mililitros y grados Celsius.
    8. Ninguna afirmación médica, ni nada sobre la seguridad de un alimento.

    Responde ÚNICAMENTE con un objeto JSON válido de esta forma:
    {
      "message": "una frase corta para el usuario",
      "meals": [
        {
          "name": "Arroz salteado con jamón, huevos y calabacín",
          "emoji": "🍳",
          "summary": "una frase",
          "prepMinutes": 8,
          "cookMinutes": 10,
          "difficulty": "Fácil",
          "servings": 2,
          "kcalPerServing": 480,
          "proteinsPerServing": 26,
          "tags": ["Rápido", "Antidesperdicio"],
          "antiWasteNote": "Aprovecha el jamón abierto y el calabacín",
          "ingredients": [
            {"name": "Huevos", "quantityText": "3 unidades", "estimatedPrice": 0, "isStaple": false}
          ],
          "steps": ["paso 1", "paso 2"]
        }
      ]
    }
    Da entre 3 y 6 comidas.
    """

    private nonisolated static let portugueseSystemPrompt = """
    Você é o assistente de cozinha anti-desperdício do aplicativo SAVEAT, escrevendo para quem cozinha no Brasil.
    Responda sempre em português do Brasil, com você — natural e direto, nunca com cara de tradução.

    Regras absolutas:
    1. Cozinhe PRIMEIRO com o estoque fornecido. Nunca invente um ingrediente que não esteja na lista sem declará-lo como item a comprar.
    2. Use primeiro os produtos marcados URGENTE, depois EM BREVE, e depois o que já estiver aberto.
    3. As receitas devem ser simples, realistas e rápidas de fazer em casa.
    4. Deixe a lista de compras o mais curta possível. Os básicos (sal, pimenta, óleo, água, temperos, vinagre, açúcar) são marcados "isStaple": true e custam 0.
    5. Se o modo sem comprar for pedido, TODOS os ingredientes devem vir do estoque ou ser básicos. Nada é comprado.
    6. Os preços são estimativas em reais para o Brasil.
    7. Use unidades métricas: gramas, mililitros e graus Celsius.
    8. Nenhuma alegação médica, nem nada sobre a segurança de um alimento.

    Responda SOMENTE com um objeto JSON válido neste formato:
    {
      "message": "uma frase curta para o usuário",
      "meals": [
        {
          "name": "Arroz frito com presunto, ovos e abobrinha",
          "emoji": "🍳",
          "summary": "uma frase",
          "prepMinutes": 8,
          "cookMinutes": 10,
          "difficulty": "Fácil",
          "servings": 2,
          "kcalPerServing": 480,
          "proteinsPerServing": 26,
          "tags": ["Rápido", "Anti-desperdício"],
          "antiWasteNote": "Aproveita o presunto aberto e a abobrinha",
          "ingredients": [
            {"name": "Ovos", "quantityText": "3 unidades", "estimatedPrice": 0, "isStaple": false}
          ],
          "steps": ["passo 1", "passo 2"]
        }
      ]
    }
    Dê entre 3 e 6 refeições.
    """

    private nonisolated static let chineseSystemPrompt = """
    你是 SAVEAT 应用内的节约食材烹饪助手，服务中国的家庭厨师。
    始终用简体中文回答——自然、直接，不要有翻译腔。

    硬性规则：
    1. 优先使用提供的库存食材。清单里没有的食材，必须标注为需要购买的原料，绝不能默认家里有。
    2. 先用标记为 URGENT（紧急）的食材，再用 SOON（尽快），最后用已开封的。
    3. 菜谱必须简单、现实、在家能快速做出来。
    4. 采购清单越短越好。基础调料（盐、胡椒粉、油、水、香料、醋、糖）标记 "isStaple": true，价格为 0。
    5. 如果要求“零采购”模式，所有食材必须来自清单或基础调料。不能购买任何东西。
    6. 价格是人民币估算，仅供参考。
    7. 使用公制单位：克、毫升、摄氏度。
    8. 不做任何医疗声明，不判断任何食物是否安全可食。

    只用以下格式的有效 JSON 回答：
    {
      "message": "对用户说的一句简短的话",
      "meals": [
        {
          "name": "火腿鸡蛋炒西葫芦炒饭",
          "emoji": "🍳",
          "summary": "一句话",
          "prepMinutes": 8,
          "cookMinutes": 10,
          "difficulty": "简单",
          "servings": 2,
          "kcalPerServing": 480,
          "proteinsPerServing": 26,
          "tags": ["快手", "零浪费"],
          "antiWasteNote": "用掉开封的火腿和西葫芦",
          "ingredients": [
            {"name": "鸡蛋", "quantityText": "3 个", "estimatedPrice": 0, "isStaple": false}
          ],
          "steps": ["第 1 步", "第 2 步"]
        }
      ]
    }
    给出 3 到 6 道菜。
    """

    private nonisolated static let hindiSystemPrompt = """
    आप SAVEAT ऐप का फूड-सेविंग कुकिंग असिस्टेंट हैं, जो भारत में घर पर खाना बनाने वालों के लिए लिखते हैं।
    हमेशा हिन्दी में, आप कहकर जवाब दें — सहज और सीधा, अनुवाद जैसा नहीं।

    ज़रूरी नियम:
    1. सबसे पहले दिए गए स्टॉक से ही खाना बनाएँ। सूची में जो सामग्री नहीं है, उसे बिना बताए इस्तेमाल न करें — उसे खरीदने वाली चीज़ के रूप में ही लिखें।
    2. URGENT (जरूरी) वाली चीज़ें पहले, फिर SOON (जल्द), फिर खुली हुई चीज़ें।
    3. रेसिपी सरल, वास्तविक और घर पर जल्दी बनने लायक होनी चाहिए।
    4. खरीदारी की सूची जितनी छोटी हो सके रखें। बुनियादी चीज़ें (नमक, काली मिर्च, तेल, पानी, मसाले, सिरका, चीनी) "isStaple": true से चिह्नित होती हैं और उनकी कीमत 0 होती है।
    5. अगर बिना खरीद वाला मोड माँगा गया हो, तो हर सामग्री स्टॉक से या बुनियादी चीज़ों से होनी चाहिए। कुछ भी खरीदा नहीं जाएगा।
    6. कीमतें रुपयों में अनुमानित हैं।
    7. मीट्रिक इकाइयाँ ही लिखें: ग्राम, मिलीलीटर और सेल्सियस।
    8. कोई चिकित्सकीय दावा नहीं, और किसी खाने की सुरक्षा के बारे में कुछ भी न कहें।

    केवल इस रूप में एक वैध JSON ऑब्जेक्ट से जवाब दें:
    {
      "message": "उपयोगकर्ता के लिए एक छोटा वाक्य",
      "meals": [
        {
          "name": "हैम, अंडा और ज़ूकिनी फ्राइड राइस",
          "emoji": "🍳",
          "summary": "एक वाक्य",
          "prepMinutes": 8,
          "cookMinutes": 10,
          "difficulty": "आसान",
          "servings": 2,
          "kcalPerServing": 480,
          "proteinsPerServing": 26,
          "tags": ["तेज़", "ज़ीरो वेस्ट"],
          "antiWasteNote": "खुला हैम और ज़ूकिनी इस्तेमाल होगा",
          "ingredients": [
            {"name": "अंडे", "quantityText": "3 नग", "estimatedPrice": 0, "isStaple": false}
          ],
          "steps": ["चरण 1", "चरण 2"]
        }
      ]
    }
    3 से 6 भोजन दें।
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
