import Foundation

/// Realistic seed content so every screen is testable immediately.
nonisolated enum MockData {
    nonisolated static func date(inDays days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
    }

    // MARK: Stock

    nonisolated static var inventory: [FoodItem] {
        [
            // 🧊 Frigo
            FoodItem(name: "Yaourts nature", emoji: "🥣", quantity: 8, unit: "pot",
                     category: .dairy, location: .fridge, bestBefore: date(inDays: 1),
                     isOpened: true, estimatedValue: 2.40, brand: "Danone",
                     product: DemoCatalogue.product(for: "DEMO-YAOURT"), matchKeys: ["yaourt"]),
            FoodItem(name: "Jambon blanc", emoji: "🥓", quantity: 1, unit: "paquet",
                     category: .protein, location: .fridge, bestBefore: date(inDays: 1),
                     isOpened: true, estimatedValue: 3.10, brand: "Herta",
                     product: DemoCatalogue.product(for: "DEMO-JAMBON"), matchKeys: ["jambon"]),
            FoodItem(name: "Courgettes", emoji: "🥒", quantity: 3, unit: "pièce",
                     category: .produce, location: .fridge, bestBefore: date(inDays: 1),
                     estimatedValue: 2.10, matchKeys: ["courgette"]),
            FoodItem(name: "Lait demi-écrémé", emoji: "🥛", quantity: 2, unit: "bouteille",
                     category: .dairy, location: .fridge, bestBefore: date(inDays: 3),
                     isOpened: true, estimatedValue: 1.05, brand: "Lactel",
                     product: DemoCatalogue.product(for: "DEMO-LAIT"), matchKeys: ["lait"]),
            FoodItem(name: "Œufs frais", emoji: "🥚", quantity: 12, unit: "pièce",
                     category: .protein, location: .fridge, bestBefore: date(inDays: 14),
                     estimatedValue: 3.20, brand: "Loué",
                     product: DemoCatalogue.product(for: "DEMO-OEUFS"), matchKeys: ["oeuf", "œuf"]),
            FoodItem(name: "Emmental râpé", emoji: "🧀", quantity: 1, unit: "sachet",
                     category: .dairy, location: .fridge, bestBefore: date(inDays: 9),
                     isOpened: true, estimatedValue: 2.75, brand: "Président",
                     product: DemoCatalogue.product(for: "DEMO-FROMAGE"), matchKeys: ["fromage", "emmental"]),
            FoodItem(name: "Tomates", emoji: "🍅", quantity: 4, unit: "pièce",
                     category: .produce, location: .fridge, bestBefore: date(inDays: 5),
                     estimatedValue: 2.30, matchKeys: ["tomate"]),
            FoodItem(name: "Poulet rôti", emoji: "🍗", quantity: 1, unit: "reste",
                     category: .protein, location: .fridge, bestBefore: date(inDays: 2),
                     isOpened: true, estimatedValue: 5.40, matchKeys: ["poulet"]),

            // 🥫 Placards
            FoodItem(name: "Coquillettes", emoji: "🍝", quantity: 2, unit: "paquet",
                     category: .grocery, location: .pantry, bestBefore: date(inDays: 420),
                     estimatedValue: 1.35, brand: "Panzani",
                     product: DemoCatalogue.product(for: "DEMO-PATES"), matchKeys: ["pate", "pates", "coquillette"]),
            FoodItem(name: "Riz long grain", emoji: "🍚", quantity: 1, unit: "paquet",
                     category: .grocery, location: .pantry, bestBefore: date(inDays: 400),
                     estimatedValue: 2.85, brand: "Taureau Ailé",
                     product: DemoCatalogue.product(for: "DEMO-RIZ"), matchKeys: ["riz"]),
            FoodItem(name: "Thon au naturel", emoji: "🐟", quantity: 3, unit: "boîte",
                     category: .protein, location: .pantry, bestBefore: date(inDays: 700),
                     estimatedValue: 3.95, brand: "Petit Navire",
                     product: DemoCatalogue.product(for: "DEMO-THON"), matchKeys: ["thon"]),
            FoodItem(name: "Sauce tomate basilic", emoji: "🥫", quantity: 2, unit: "pot",
                     category: .grocery, location: .pantry, bestBefore: date(inDays: 300),
                     estimatedValue: 1.75, brand: "Panzani",
                     product: DemoCatalogue.product(for: "DEMO-SAUCE"), matchKeys: ["sauce tomate", "coulis"]),
            FoodItem(name: "Pain de campagne", emoji: "🍞", quantity: 1, unit: "demi",
                     category: .grocery, location: .pantry, bestBefore: date(inDays: 2),
                     isOpened: true, estimatedValue: 1.60, matchKeys: ["pain"]),
            FoodItem(name: "Oignons", emoji: "🧅", quantity: 4, unit: "pièce",
                     category: .produce, location: .pantry, bestBefore: nil,
                     estimatedValue: 1.20, matchKeys: ["oignon"]),
            FoodItem(name: "Lentilles vertes", emoji: "🫘", quantity: 1, unit: "paquet",
                     category: .grocery, location: .pantry, bestBefore: date(inDays: 500),
                     estimatedValue: 2.10, matchKeys: ["lentille"]),

            // ❄️ Congélateur
            FoodItem(name: "Poêlée de légumes", emoji: "🥦", quantity: 1, unit: "sachet",
                     category: .frozen, location: .freezer, bestBefore: date(inDays: 220),
                     estimatedValue: 3.20, brand: "Findus",
                     product: DemoCatalogue.product(for: "DEMO-LEGUMES"), matchKeys: ["legume", "poelee"]),
            FoodItem(name: "Petits pois surgelés", emoji: "🫛", quantity: 1, unit: "sachet",
                     category: .frozen, location: .freezer, bestBefore: date(inDays: 150),
                     estimatedValue: 1.90, matchKeys: ["pois"]),
            FoodItem(name: "Steaks hachés", emoji: "🥩", quantity: 4, unit: "pièce",
                     category: .frozen, location: .freezer, bestBefore: date(inDays: 90),
                     estimatedValue: 6.20, matchKeys: ["steak", "boeuf"])
        ]
        .filter { $0.quantity > 0 }
    }

    // MARK: Curated meals (offline fallback for the assistant)

    nonisolated static var curatedMeals: [Meal] {
        [
            Meal(
                name: "Riz sauté jambon, œufs & courgettes",
                emoji: "🍳",
                summary: "Le grand classique anti-gaspi : tout part dans la même poêle.",
                imageName: "fried_rice_cast_iron_pan",
                prepMinutes: 8, cookMinutes: 10, difficulty: "Facile", servings: 2,
                kcalPerServing: 480, proteinsPerServing: 26,
                ingredients: [
                    MealIngredient(name: "Riz long grain", quantityText: "150 g", category: .grocery, estimatedPrice: 0.60),
                    MealIngredient(name: "Jambon blanc", quantityText: "2 tranches", category: .protein, estimatedPrice: 1.20),
                    MealIngredient(name: "Œufs", quantityText: "2 pièces", category: .protein, estimatedPrice: 0.60),
                    MealIngredient(name: "Courgettes", quantityText: "1 pièce", category: .produce, estimatedPrice: 0.70),
                    MealIngredient(name: "Oignon", quantityText: "1 pièce", category: .produce, estimatedPrice: 0.30),
                    MealIngredient(name: "Huile d'olive", quantityText: "1 c. à s.", isStaple: true)
                ],
                steps: [
                    "Fais revenir l'oignon émincé dans un filet d'huile.",
                    "Ajoute les courgettes en dés, laisse dorer 6 minutes.",
                    "Ajoute le riz cuit et le jambon coupé, fais sauter à feu vif.",
                    "Pousse le riz sur le côté, brouille les œufs puis mélange le tout."
                ],
                tags: ["Express", "Anti-gaspi"],
                antiWasteNote: "Utilise ton jambon ouvert et tes courgettes."
            ),
            Meal(
                name: "Gratin de courgettes au fromage",
                emoji: "🧀",
                summary: "Un plat familial qui vide le bac à légumes.",
                imageName: "zucchini_cheese_gratin",
                prepMinutes: 10, cookMinutes: 25, difficulty: "Facile", servings: 4,
                kcalPerServing: 410, proteinsPerServing: 19,
                ingredients: [
                    MealIngredient(name: "Courgettes", quantityText: "3 pièces", category: .produce, estimatedPrice: 2.10),
                    MealIngredient(name: "Emmental râpé", quantityText: "80 g", category: .dairy, estimatedPrice: 1.10),
                    MealIngredient(name: "Œufs", quantityText: "3 pièces", category: .protein, estimatedPrice: 0.90),
                    MealIngredient(name: "Lait", quantityText: "20 cl", category: .dairy, estimatedPrice: 0.35),
                    MealIngredient(name: "Sel", quantityText: "1 pincée", isStaple: true)
                ],
                steps: [
                    "Préchauffe le four à 190 °C.",
                    "Coupe les courgettes en fines rondelles, dispose-les dans un plat.",
                    "Bats les œufs avec le lait, verse sur les courgettes.",
                    "Couvre de fromage et enfourne 25 minutes."
                ],
                tags: ["Végétarien", "Four"],
                antiWasteNote: "Parfait pour les courgettes à utiliser en priorité."
            ),
            Meal(
                name: "Omelette jambon & fromage",
                emoji: "🍳",
                summary: "Dix minutes chrono, uniquement avec le frigo.",
                imageName: "french_omelette_ham_cheese",
                prepMinutes: 4, cookMinutes: 6, difficulty: "Facile", servings: 2,
                kcalPerServing: 380, proteinsPerServing: 28,
                ingredients: [
                    MealIngredient(name: "Œufs", quantityText: "4 pièces", category: .protein, estimatedPrice: 1.20),
                    MealIngredient(name: "Jambon blanc", quantityText: "2 tranches", category: .protein, estimatedPrice: 1.20),
                    MealIngredient(name: "Emmental râpé", quantityText: "40 g", category: .dairy, estimatedPrice: 0.60),
                    MealIngredient(name: "Poivre", quantityText: "1 pincée", isStaple: true)
                ],
                steps: [
                    "Bats les œufs avec une pincée de sel et de poivre.",
                    "Verse dans une poêle chaude légèrement huilée.",
                    "Ajoute le jambon et le fromage, replie l'omelette."
                ],
                tags: ["Express", "Repas à 0 €"],
                antiWasteNote: "Ton jambon ouvert part en premier."
            ),
            Meal(
                name: "Pâtes à la sauce tomate & thon",
                emoji: "🍝",
                summary: "Le dîner du placard quand le frigo est vide.",
                imageName: nil,
                prepMinutes: 5, cookMinutes: 12, difficulty: "Facile", servings: 3,
                kcalPerServing: 520, proteinsPerServing: 27,
                ingredients: [
                    MealIngredient(name: "Coquillettes", quantityText: "300 g", category: .grocery, estimatedPrice: 0.80),
                    MealIngredient(name: "Sauce tomate", quantityText: "1 pot", category: .grocery, estimatedPrice: 1.75),
                    MealIngredient(name: "Thon au naturel", quantityText: "1 boîte", category: .protein, estimatedPrice: 1.30),
                    MealIngredient(name: "Oignon", quantityText: "1 pièce", category: .produce, estimatedPrice: 0.30),
                    MealIngredient(name: "Huile d'olive", quantityText: "1 c. à s.", isStaple: true)
                ],
                steps: [
                    "Fais cuire les pâtes dans l'eau salée.",
                    "Fais revenir l'oignon, ajoute la sauce tomate et le thon égoutté.",
                    "Laisse mijoter 6 minutes, mélange avec les pâtes."
                ],
                tags: ["Économique", "Placard"],
                antiWasteNote: "Zéro achat : tout vient de tes placards."
            ),
            Meal(
                name: "Soupe de légumes du frigo",
                emoji: "🥣",
                summary: "Tout ce qui traîne finit dedans, et c'est très bon.",
                imageName: "vegetable_soup_bread",
                prepMinutes: 10, cookMinutes: 20, difficulty: "Facile", servings: 4,
                kcalPerServing: 210, proteinsPerServing: 8,
                ingredients: [
                    MealIngredient(name: "Courgettes", quantityText: "2 pièces", category: .produce, estimatedPrice: 1.40),
                    MealIngredient(name: "Tomates", quantityText: "2 pièces", category: .produce, estimatedPrice: 1.15),
                    MealIngredient(name: "Oignon", quantityText: "1 pièce", category: .produce, estimatedPrice: 0.30),
                    MealIngredient(name: "Pain de campagne", quantityText: "2 tranches", category: .grocery, estimatedPrice: 0.40),
                    MealIngredient(name: "Sel", quantityText: "1 pincée", isStaple: true)
                ],
                steps: [
                    "Fais suer l'oignon, ajoute les légumes coupés grossièrement.",
                    "Couvre d'eau, laisse mijoter 20 minutes.",
                    "Mixe et sers avec le pain grillé."
                ],
                tags: ["Végétarien", "Léger"],
                antiWasteNote: "Idéale pour le pain rassis."
            ),
            Meal(
                name: "Pain perdu du placard",
                emoji: "🍞",
                summary: "Le dessert qui sauve le pain de la poubelle.",
                imageName: "french_toast_berries",
                prepMinutes: 5, cookMinutes: 8, difficulty: "Facile", servings: 2,
                kcalPerServing: 340, proteinsPerServing: 12,
                ingredients: [
                    MealIngredient(name: "Pain de campagne", quantityText: "4 tranches", category: .grocery, estimatedPrice: 0.60),
                    MealIngredient(name: "Œufs", quantityText: "2 pièces", category: .protein, estimatedPrice: 0.60),
                    MealIngredient(name: "Lait", quantityText: "20 cl", category: .dairy, estimatedPrice: 0.35),
                    MealIngredient(name: "Sucre", quantityText: "1 c. à s.", isStaple: true)
                ],
                steps: [
                    "Bats les œufs avec le lait et le sucre.",
                    "Trempe les tranches de pain rassis.",
                    "Fais dorer à la poêle 2 minutes de chaque côté."
                ],
                tags: ["Repas à 0 €", "Sucré"],
                antiWasteNote: "Ton pain entamé devient un dessert."
            ),
            Meal(
                name: "Poêlée de légumes & œufs au plat",
                emoji: "🥦",
                summary: "Direct du congélateur, prêt en un quart d'heure.",
                imageName: nil,
                prepMinutes: 3, cookMinutes: 12, difficulty: "Facile", servings: 2,
                kcalPerServing: 320, proteinsPerServing: 18,
                ingredients: [
                    MealIngredient(name: "Poêlée de légumes", quantityText: "400 g", category: .frozen, estimatedPrice: 1.70),
                    MealIngredient(name: "Œufs", quantityText: "2 pièces", category: .protein, estimatedPrice: 0.60),
                    MealIngredient(name: "Emmental râpé", quantityText: "30 g", category: .dairy, estimatedPrice: 0.45),
                    MealIngredient(name: "Huile d'olive", quantityText: "1 c. à s.", isStaple: true)
                ],
                steps: [
                    "Fais sauter les légumes encore surgelés 10 minutes à feu vif.",
                    "Casse les œufs par-dessus, couvre 3 minutes.",
                    "Parsème de fromage et sers aussitôt."
                ],
                tags: ["Express", "Végétarien"],
                antiWasteNote: "Vide ton congélateur sans rien acheter."
            ),
            Meal(
                name: "Salade de lentilles au thon",
                emoji: "🥗",
                summary: "Riche en protéines, se prépare la veille.",
                imageName: nil,
                prepMinutes: 10, cookMinutes: 20, difficulty: "Facile", servings: 4,
                kcalPerServing: 390, proteinsPerServing: 24,
                ingredients: [
                    MealIngredient(name: "Lentilles vertes", quantityText: "250 g", category: .grocery, estimatedPrice: 1.20),
                    MealIngredient(name: "Thon au naturel", quantityText: "1 boîte", category: .protein, estimatedPrice: 1.30),
                    MealIngredient(name: "Tomates", quantityText: "2 pièces", category: .produce, estimatedPrice: 1.15),
                    MealIngredient(name: "Oignon", quantityText: "1 pièce", category: .produce, estimatedPrice: 0.30),
                    MealIngredient(name: "Vinaigre", quantityText: "1 c. à s.", isStaple: true)
                ],
                steps: [
                    "Cuis les lentilles 20 minutes dans l'eau non salée.",
                    "Égoutte et laisse tiédir.",
                    "Mélange avec le thon, les tomates en dés et l'oignon émincé."
                ],
                tags: ["Protéines", "Batch cooking"],
                antiWasteNote: "Se garde 3 jours au frigo."
            )
        ]
    }

    // MARK: Challenges

    nonisolated static var challenges: [Challenge] {
        [
            Challenge(title: "Cuisiner 3 repas avec ton stock", detail: "Défi Zéro Gaspi — 7 jours", emoji: "🍽️", progress: 2, target: 3),
            Challenge(title: "Réussir un repas à 0 €", detail: "Aucun achat nécessaire", emoji: "🥘", progress: 1, target: 1),
            Challenge(title: "Sauver 5 produits", detail: "Avant leur date limite", emoji: "🥕", progress: 3, target: 5),
            Challenge(title: "Une semaine sans doublon", detail: "Ne racheter que ce qu'il manque", emoji: "🛒", progress: 4, target: 7)
        ]
    }
}
