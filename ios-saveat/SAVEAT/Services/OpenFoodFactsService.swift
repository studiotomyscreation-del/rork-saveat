import Foundation

nonisolated enum ProductLookupError: LocalizedError, Sendable {
    case notFound
    case network

    nonisolated var errorDescription: String? {
        switch self {
        case .notFound: "Produit introuvable dans la base."
        case .network: "Connexion impossible pour l'instant."
        }
    }
}

/// Looks up grocery barcodes in the public Open Food Facts database.
///
/// Falls back to a bundled demo catalogue so the scanning flow always works,
/// including offline and on the simulator.
nonisolated struct OpenFoodFactsService: Sendable {
    nonisolated static let shared = OpenFoodFactsService()

    private static let fields = [
        "code", "product_name", "product_name_fr", "brands", "image_front_url", "image_url",
        "quantity", "ingredients_text_fr", "ingredients_text", "allergens_tags", "additives_tags",
        "nutriscore_grade", "nova_group", "nutriments", "categories_tags"
    ].joined(separator: ",")

    /// Online lookup first, bundled catalogue as a safety net.
    nonisolated func product(barcode: String) async -> Result<ScannedProduct, ProductLookupError> {
        if let local = DemoCatalogue.product(for: barcode) {
            return .success(local)
        }

        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=\(Self.fields)") else {
            return .failure(.notFound)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("SAVEAT/1.0 (iOS; anti-gaspillage)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .failure(.network) }
            guard http.statusCode == 200 else {
                return .failure(http.statusCode == 404 ? .notFound : .network)
            }
            let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
            guard decoded.status == 1, let payload = decoded.product else { return .failure(.notFound) }
            return .success(payload.toProduct(barcode: barcode))
        } catch is DecodingError {
            return .failure(.notFound)
        } catch {
            return .failure(.network)
        }
    }
}

// MARK: - Open Food Facts payload

private nonisolated struct OFFResponse: Decodable, Sendable {
    var status: Int
    var product: OFFProduct?
}

private nonisolated struct OFFProduct: Decodable, Sendable {
    var productName: String?
    var productNameFR: String?
    var brands: String?
    var imageFrontURL: String?
    var imageURL: String?
    var quantity: String?
    var ingredientsTextFR: String?
    var ingredientsText: String?
    var allergensTags: [String]?
    var additivesTags: [String]?
    var nutriscoreGrade: String?
    var novaGroup: Int?
    var nutriments: OFFNutriments?
    var categoriesTags: [String]?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameFR = "product_name_fr"
        case brands
        case imageFrontURL = "image_front_url"
        case imageURL = "image_url"
        case quantity
        case ingredientsTextFR = "ingredients_text_fr"
        case ingredientsText = "ingredients_text"
        case allergensTags = "allergens_tags"
        case additivesTags = "additives_tags"
        case nutriscoreGrade = "nutriscore_grade"
        case novaGroup = "nova_group"
        case nutriments
        case categoriesTags = "categories_tags"
    }

    nonisolated func toProduct(barcode: String) -> ScannedProduct {
        let rawName = [productNameFR, productName].compactMap { $0 }.first { !$0.isEmpty } ?? "Produit \(barcode.suffix(4))"
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = categoriesTags ?? []
        let profile = ProductHeuristics.profile(name: name, tags: tags)

        return ScannedProduct(
            barcode: barcode,
            name: name,
            brand: brands?.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) },
            imageURLString: imageFrontURL ?? imageURL,
            packagingText: quantity,
            ingredientsText: [ingredientsTextFR, ingredientsText].compactMap { $0 }.first { !$0.isEmpty },
            allergens: (allergensTags ?? []).map { ProductHeuristics.cleanTag($0) },
            additives: (additivesTags ?? []).map { ProductHeuristics.cleanTag($0) },
            // A missing key means "not documented"; an empty array means "none".
            additivesKnown: additivesTags != nil,
            nutriScore: nutriscoreGrade,
            nova: novaGroup,
            nutriments: Nutriments(
                energyKcal: nutriments?.energyKcal100g,
                sugars: nutriments?.sugars100g,
                salt: nutriments?.salt100g,
                saturatedFat: nutriments?.saturatedFat100g,
                fat: nutriments?.fat100g,
                proteins: nutriments?.proteins100g,
                fiber: nutriments?.fiber100g
            ),
            suggestedLocation: profile.location,
            suggestedCategory: profile.category,
            emoji: profile.emoji,
            unit: profile.unit,
            estimatedPrice: profile.price,
            defaultShelfLifeDays: profile.shelfLifeDays
        )
    }
}

private nonisolated struct OFFNutriments: Decodable, Sendable {
    var energyKcal100g: Double?
    var sugars100g: Double?
    var salt100g: Double?
    var saturatedFat100g: Double?
    var fat100g: Double?
    var proteins100g: Double?
    var fiber100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case sugars100g = "sugars_100g"
        case salt100g = "salt_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case fat100g = "fat_100g"
        case proteins100g = "proteins_100g"
        case fiber100g = "fiber_100g"
    }
}

// MARK: - Heuristics

/// Guesses where a product lives at home and how it should look in the app.
nonisolated enum ProductHeuristics {
    nonisolated struct Profile: Sendable {
        var location: StorageLocation
        var category: FoodCategory
        var emoji: String
        var unit: String
        var price: Double
        var shelfLifeDays: Int?
    }

    nonisolated static func cleanTag(_ tag: String) -> String {
        tag.split(separator: ":").last.map(String.init) ?? tag
    }

    nonisolated static func profile(name: String, tags: [String]) -> Profile {
        let haystack = (name + " " + tags.joined(separator: " "))
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))

        func has(_ keys: [String]) -> Bool {
            keys.contains { haystack.contains($0) }
        }

        if has(["surgel", "frozen", "glace", "ice-cream"]) {
            return Profile(location: .freezer, category: .frozen, emoji: "🧊", unit: "sachet", price: 3.20, shelfLifeDays: 180)
        }
        if has(["yaourt", "yogurt", "yoghurt"]) {
            return Profile(location: .fridge, category: .dairy, emoji: "🥣", unit: "pack", price: 2.30, shelfLifeDays: 21)
        }
        if has(["lait", "milk"]) {
            return Profile(location: .fridge, category: .dairy, emoji: "🥛", unit: "bouteille", price: 1.15, shelfLifeDays: 7)
        }
        if has(["fromage", "cheese", "emmental", "comte", "mozzarella"]) {
            return Profile(location: .fridge, category: .dairy, emoji: "🧀", unit: "paquet", price: 2.60, shelfLifeDays: 20)
        }
        if has(["beurre", "butter", "creme", "cream"]) {
            return Profile(location: .fridge, category: .dairy, emoji: "🧈", unit: "paquet", price: 2.40, shelfLifeDays: 30)
        }
        if has(["jambon", "ham", "charcuterie", "lardon", "saucisse"]) {
            return Profile(location: .fridge, category: .protein, emoji: "🥓", unit: "paquet", price: 2.90, shelfLifeDays: 8)
        }
        if has(["oeuf", "œuf", "egg"]) {
            return Profile(location: .fridge, category: .protein, emoji: "🥚", unit: "boîte", price: 3.20, shelfLifeDays: 21)
        }
        if has(["poulet", "boeuf", "porc", "dinde", "viande", "steak", "meat"]) {
            return Profile(location: .fridge, category: .protein, emoji: "🍗", unit: "barquette", price: 6.50, shelfLifeDays: 4)
        }
        if has(["thon", "sardine", "maquereau", "saumon", "poisson", "fish", "tuna"]) {
            return Profile(location: .pantry, category: .protein, emoji: "🐟", unit: "boîte", price: 2.10, shelfLifeDays: 720)
        }
        if has(["pate", "spaghetti", "penne", "coquillette", "pasta", "nouille"]) {
            return Profile(location: .pantry, category: .grocery, emoji: "🍝", unit: "paquet", price: 1.30, shelfLifeDays: 540)
        }
        if has(["riz", "rice", "quinoa", "semoule", "boulgour"]) {
            return Profile(location: .pantry, category: .grocery, emoji: "🍚", unit: "paquet", price: 2.40, shelfLifeDays: 540)
        }
        if has(["sauce", "tomate pel", "coulis", "passata", "ketchup"]) {
            return Profile(location: .pantry, category: .grocery, emoji: "🥫", unit: "pot", price: 1.60, shelfLifeDays: 400)
        }
        if has(["conserve", "haricot", "lentille", "pois chiche", "mais"]) {
            return Profile(location: .pantry, category: .grocery, emoji: "🥫", unit: "boîte", price: 1.20, shelfLifeDays: 720)
        }
        if has(["pain", "bread", "brioche", "biscotte"]) {
            return Profile(location: .pantry, category: .grocery, emoji: "🍞", unit: "paquet", price: 1.50, shelfLifeDays: 5)
        }
        if has(["legume", "salade", "tomate", "carotte", "courgette", "vegetable", "fruit", "pomme", "banane"]) {
            return Profile(location: .fridge, category: .produce, emoji: "🥗", unit: "sachet", price: 2.20, shelfLifeDays: 6)
        }
        if has(["biscuit", "chocolat", "gateau", "bonbon", "snack", "chips"]) {
            return Profile(location: .pantry, category: .grocery, emoji: "🍫", unit: "paquet", price: 2.30, shelfLifeDays: 200)
        }
        if has(["jus", "soda", "boisson", "eau", "juice", "drink"]) {
            return Profile(location: .pantry, category: .grocery, emoji: "🧃", unit: "bouteille", price: 1.80, shelfLifeDays: 200)
        }
        if has(["cafe", "the ", "infusion", "coffee"]) {
            return Profile(location: .pantry, category: .grocery, emoji: "☕️", unit: "paquet", price: 4.20, shelfLifeDays: 400)
        }

        return Profile(location: .pantry, category: .grocery, emoji: "🥫", unit: "unité", price: 2.20, shelfLifeDays: 180)
    }
}

// MARK: - Demo catalogue

/// Realistic French groceries used for the demo chips and offline scanning.
nonisolated enum DemoCatalogue {
    nonisolated static func product(for barcode: String) -> ScannedProduct? {
        all.first { $0.barcode == barcode }
    }

    nonisolated static let all: [ScannedProduct] = [
        ScannedProduct(
            barcode: "DEMO-PATES",
            name: "Coquillettes",
            brand: "Panzani",
            packagingText: "500 g",
            ingredientsText: "Semoule de blé dur de qualité supérieure.",
            allergens: ["gluten"],
            additives: [],
            additivesKnown: true,
            nutriScore: "a",
            nova: 1,
            nutriments: Nutriments(energyKcal: 356, sugars: 3.2, salt: 0.01, saturatedFat: 0.4, fat: 1.5, proteins: 12, fiber: 3.2),
            suggestedLocation: .pantry, suggestedCategory: .grocery, emoji: "🍝", unit: "paquet",
            estimatedPrice: 1.35, defaultShelfLifeDays: 540, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-RIZ",
            name: "Riz long grain",
            brand: "Taureau Ailé",
            packagingText: "1 kg",
            ingredientsText: "Riz long grain étuvé.",
            allergens: [],
            additives: [],
            additivesKnown: true,
            nutriScore: "a",
            nova: 1,
            nutriments: Nutriments(energyKcal: 349, sugars: 0.5, salt: 0.01, saturatedFat: 0.2, fat: 0.9, proteins: 7.5, fiber: 1.4),
            suggestedLocation: .pantry, suggestedCategory: .grocery, emoji: "🍚", unit: "paquet",
            estimatedPrice: 2.85, defaultShelfLifeDays: 540, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-SAUCE",
            name: "Sauce tomate basilic",
            brand: "Panzani",
            packagingText: "400 g",
            ingredientsText: "Tomates (85 %), oignons, basilic, huile de tournesol, sel, sucre.",
            allergens: [],
            additives: ["e330"],
            additivesKnown: true,
            nutriScore: "b",
            nova: 3,
            nutriments: Nutriments(energyKcal: 62, sugars: 5.8, salt: 0.85, saturatedFat: 0.3, fat: 2.4, proteins: 1.4, fiber: 1.6),
            suggestedLocation: .pantry, suggestedCategory: .grocery, emoji: "🥫", unit: "pot",
            estimatedPrice: 1.75, defaultShelfLifeDays: 420, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-YAOURT",
            name: "Yaourts nature",
            brand: "Danone",
            packagingText: "8 × 125 g",
            ingredientsText: "Lait entier, ferments lactiques.",
            allergens: ["milk"],
            additives: [],
            additivesKnown: true,
            nutriScore: "b",
            nova: 1,
            nutriments: Nutriments(energyKcal: 61, sugars: 4.9, salt: 0.13, saturatedFat: 2.1, fat: 3.2, proteins: 3.8, fiber: 0),
            suggestedLocation: .fridge, suggestedCategory: .dairy, emoji: "🥣", unit: "pack",
            estimatedPrice: 2.40, defaultShelfLifeDays: 24, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-JAMBON",
            name: "Jambon blanc découenné",
            brand: "Herta",
            packagingText: "4 tranches",
            ingredientsText: "Jambon de porc, sel, sirop de glucose, arômes naturels, conservateur.",
            allergens: [],
            additives: ["e250", "e316"],
            additivesKnown: true,
            nutriScore: "c",
            nova: 4,
            nutriments: Nutriments(energyKcal: 111, sugars: 0.8, salt: 2.1, saturatedFat: 1.1, fat: 3.1, proteins: 19.5, fiber: 0),
            suggestedLocation: .fridge, suggestedCategory: .protein, emoji: "🥓", unit: "paquet",
            estimatedPrice: 3.10, defaultShelfLifeDays: 9, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-FROMAGE",
            name: "Emmental râpé",
            brand: "Président",
            packagingText: "200 g",
            ingredientsText: "Emmental français (lait, sel, ferments, présure), fécule de pomme de terre.",
            allergens: ["milk"],
            additives: [],
            additivesKnown: true,
            nutriScore: "d",
            nova: 3,
            nutriments: Nutriments(energyKcal: 372, sugars: 0.5, salt: 0.5, saturatedFat: 18, fat: 29, proteins: 27, fiber: 0),
            suggestedLocation: .fridge, suggestedCategory: .dairy, emoji: "🧀", unit: "sachet",
            estimatedPrice: 2.75, defaultShelfLifeDays: 30, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-THON",
            name: "Thon au naturel",
            brand: "Petit Navire",
            packagingText: "3 × 80 g",
            ingredientsText: "Thon listao, eau, sel.",
            allergens: ["fish"],
            additives: [],
            additivesKnown: true,
            nutriScore: "a",
            nova: 1,
            nutriments: Nutriments(energyKcal: 108, sugars: 0, salt: 0.9, saturatedFat: 0.2, fat: 0.8, proteins: 25, fiber: 0),
            suggestedLocation: .pantry, suggestedCategory: .protein, emoji: "🐟", unit: "boîte",
            estimatedPrice: 3.95, defaultShelfLifeDays: 900, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-LAIT",
            name: "Lait demi-écrémé",
            brand: "Lactel",
            packagingText: "1 L",
            ingredientsText: "Lait demi-écrémé stérilisé UHT.",
            allergens: ["milk"],
            additives: [],
            additivesKnown: true,
            nutriScore: "b",
            nova: 1,
            nutriments: Nutriments(energyKcal: 46, sugars: 4.8, salt: 0.13, saturatedFat: 1, fat: 1.5, proteins: 3.2, fiber: 0),
            suggestedLocation: .fridge, suggestedCategory: .dairy, emoji: "🥛", unit: "bouteille",
            estimatedPrice: 1.05, defaultShelfLifeDays: 10, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-OEUFS",
            name: "Œufs frais plein air",
            brand: "Loué",
            packagingText: "6 œufs",
            ingredientsText: "Œufs de poules élevées en plein air.",
            allergens: ["eggs"],
            additives: [],
            additivesKnown: true,
            nutriScore: "a",
            nova: 1,
            nutriments: Nutriments(energyKcal: 139, sugars: 0.4, salt: 0.35, saturatedFat: 2.9, fat: 9.8, proteins: 12.6, fiber: 0),
            suggestedLocation: .fridge, suggestedCategory: .protein, emoji: "🥚", unit: "boîte",
            estimatedPrice: 2.85, defaultShelfLifeDays: 21, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-LEGUMES",
            name: "Poêlée de légumes surgelés",
            brand: "Findus",
            packagingText: "750 g",
            ingredientsText: "Courgettes, poivrons, oignons, haricots verts.",
            allergens: [],
            additives: [],
            additivesKnown: true,
            nutriScore: "a",
            nova: 1,
            nutriments: Nutriments(energyKcal: 42, sugars: 3.1, salt: 0.02, saturatedFat: 0.1, fat: 0.5, proteins: 1.9, fiber: 2.8),
            suggestedLocation: .freezer, suggestedCategory: .frozen, emoji: "🥦", unit: "sachet",
            estimatedPrice: 3.20, defaultShelfLifeDays: 300, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-CEREALES",
            name: "Céréales fourrées chocolat",
            brand: "Chocapic",
            packagingText: "430 g",
            ingredientsText: "Céréales (blé, riz), sucre, cacao maigre, sirop de glucose, arômes.",
            allergens: ["gluten", "milk"],
            additives: ["e322", "e500", "e330"],
            additivesKnown: true,
            nutriScore: "d",
            nova: 4,
            nutriments: Nutriments(energyKcal: 420, sugars: 26, salt: 0.4, saturatedFat: 3.6, fat: 8.5, proteins: 7.2, fiber: 5.1),
            suggestedLocation: .pantry, suggestedCategory: .grocery, emoji: "🥣", unit: "paquet",
            estimatedPrice: 3.60, defaultShelfLifeDays: 240, isDemoData: true
        ),
        ScannedProduct(
            barcode: "DEMO-BEURRE",
            name: "Beurre doux",
            brand: "Elle & Vire",
            packagingText: "250 g",
            ingredientsText: "Crème pasteurisée.",
            allergens: ["milk"],
            additives: [],
            additivesKnown: true,
            nutriScore: "e",
            nova: 2,
            nutriments: Nutriments(energyKcal: 749, sugars: 0.6, salt: 0.02, saturatedFat: 54, fat: 82, proteins: 0.7, fiber: 0),
            suggestedLocation: .fridge, suggestedCategory: .dairy, emoji: "🧈", unit: "plaquette",
            estimatedPrice: 2.95, defaultShelfLifeDays: 45, isDemoData: true
        )
    ]
}
