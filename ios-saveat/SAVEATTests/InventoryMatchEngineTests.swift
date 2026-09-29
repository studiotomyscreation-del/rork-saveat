import Foundation
import Testing
@testable import SAVEAT

/// Phase 3 — « Déjà chez vous »: exact GTIN matches against the real stock.
struct InventoryMatchEngineTests {

    private func item(
        _ name: String,
        barcode: String?,
        quantity: Double = 1,
        location: StorageLocation = .pantry,
        daysLeft: Int? = nil
    ) -> FoodItem {
        FoodItem(
            name: name, emoji: "🥫", quantity: quantity, unit: "unité",
            category: .grocery, location: location,
            bestBefore: daysLeft.flatMap { Calendar.current.date(byAdding: .day, value: $0, to: .now) },
            barcode: barcode
        )
    }

    @Test func absentGTINReturnsNil() {
        let stock = [item("Nutella", barcode: "3017620422003")]
        #expect(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "4006381333931"), in: stock) == nil)
        #expect(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "4006381333931"), in: []) == nil)
    }

    @Test func exactGTINPresent() throws {
        let stock = [item("Nutella", barcode: "3017620422003", quantity: 2, location: .pantry)]
        let match = try #require(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "3017620422003"), in: stock))
        #expect(match.kind == .exact)
        #expect(match.occurrences.count == 1)
        #expect(match.occurrences.first?.item.name == "Nutella")
        #expect(match.occurrences.first?.location == .pantry)
        #expect(match.totalQuantity == 2)
    }

    @Test func upcAMatchesItsCanonicalForm() throws {
        let stock = [item("Diet Coke", barcode: "049000028911", quantity: 1, location: .fridge)]
        let scanned = NormalizedGTIN(parsing: "0049000028911")
        let match = try #require(InventoryMatchEngine.exactMatch(for: scanned, in: stock))
        #expect(match.totalQuantity == 1)
        #expect(match.byLocation == [.init(location: .fridge, quantity: 1)])

        // UPC-E on the pack, UPC-A in the stock.
        let upcEStock = [item("Coke", barcode: "049000006346")]
        #expect(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "04963406", hint: .upcE), in: upcEStock) != nil)
    }

    @Test func recordedQuantityIsUsedNotOnePerScan() throws {
        let stock = [item("Riz", barcode: "3017620422003", quantity: 2.5)]
        let match = try #require(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "3017620422003"), in: stock))
        #expect(match.totalQuantity == 2.5)
    }

    @Test func emptiedLinesAreIgnored() {
        let stock = [item("Riz", barcode: "3017620422003", quantity: 0)]
        #expect(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "3017620422003"), in: stock) == nil)
    }

    @Test func severalOccurrencesAreAllReturned() throws {
        let stock = [
            item("Yaourt", barcode: "3017620422003", quantity: 1, location: .fridge),
            item("Tomates", barcode: nil, location: .fridge),
            item("Yaourt", barcode: "03017620422003", quantity: 2, location: .fridge)
        ]
        let match = try #require(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "3017620422003"), in: stock))
        #expect(match.occurrences.count == 2)
        #expect(match.totalQuantity == 3)
        #expect(match.byLocation == [.init(location: .fridge, quantity: 3)])
    }

    @Test func severalLocationsAreAggregated() throws {
        let stock = [
            item("Pain", barcode: "3017620422003", quantity: 2, location: .pantry),
            item("Pain", barcode: "3017620422003", quantity: 1, location: .fridge),
            item("Pain", barcode: "3017620422003", quantity: 3, location: .freezer)
        ]
        let match = try #require(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "3017620422003"), in: stock))
        #expect(match.totalQuantity == 6)
        #expect(match.byLocation == [
            .init(location: .fridge, quantity: 1),
            .init(location: .pantry, quantity: 2),
            .init(location: .freezer, quantity: 3)
        ])
    }

    @MainActor
    @Test func messagesAreLocalizedPerLocation() throws {
        let previous = LanguageRuntime.current
        defer { LanguageRuntime.set(previous) }
        let stock = [
            item("Pain", barcode: "3017620422003", quantity: 2, location: .pantry),
            item("Pain", barcode: "3017620422003", quantity: 1, location: .fridge)
        ]
        let match = try #require(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "3017620422003"), in: stock))

        LanguageRuntime.set(.fr)
        #expect(S.InventoryMatch.title.s == "Vous en avez déjà à la maison")
        #expect(match.locationLines == ["1 dans votre frigo", "2 dans votre placard", "Total : 3 à la maison"])

        LanguageRuntime.set(.en)
        #expect(S.InventoryMatch.title.s == "You already have this at home")
        #expect(match.locationLines == ["1 in your fridge", "2 in your pantry", "Total: 3 at home"])
    }

    @Test func legacyStoredBarcodeIsNotRewritten() throws {
        let stock = [item("Diet Coke", barcode: " 049000028911", quantity: 2)]
        let match = try #require(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "0049000028911"), in: stock))
        #expect(match.occurrences.first?.item.barcode == " 049000028911")
        #expect(stock.first?.barcode == " 049000028911")
    }

    @MainActor
    @Test func recordedDateCloseToExpiryIsFlagged() throws {
        let previous = LanguageRuntime.current
        defer { LanguageRuntime.set(previous) }
        let stock = [
            item("Lait", barcode: "3017620422003", quantity: 1, location: .fridge, daysLeft: 2),
            item("Lait", barcode: "3017620422003", quantity: 1, location: .pantry, daysLeft: 30),
            item("Lait", barcode: "3017620422003", quantity: 1, location: .pantry, daysLeft: nil)
        ]
        let match = try #require(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "3017620422003"), in: stock))
        #expect(match.totalQuantity == 3)
        #expect(match.useSoonQuantity == 1)
        LanguageRuntime.set(.fr)
        #expect(match.useSoonLine == "1 est à utiliser bientôt")
        LanguageRuntime.set(.en)
        #expect(match.useSoonLine == "1 should be used soon")
    }

    @Test func noDateMeansNoUseSoonFlag() throws {
        let stock = [item("Pâtes", barcode: "3017620422003", quantity: 4)]
        let match = try #require(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "3017620422003"), in: stock))
        #expect(match.useSoonQuantity == 0)
        #expect(match.useSoonLine == nil)
        // Nothing written back.
        #expect(stock.first?.bestBefore == nil)
    }

    @Test func noFalseMatchBetweenDifferentProducts() {
        let stock = [
            item("Nutella", barcode: "3017620422003"),
            item("Coca", barcode: "049000028911"),
            item("Invalide", barcode: "036000291453"),
            item("Demo", barcode: "DEMO-PATES"),
            item("Vrac", barcode: nil)
        ]
        #expect(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "4006381333931"), in: stock) == nil)
        #expect(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "036000291452"), in: stock) == nil)
        #expect(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: "DEMO-RIZ"), in: stock) == nil)
        #expect(InventoryMatchEngine.exactMatch(for: NormalizedGTIN(parsing: ""), in: stock) == nil)
    }
}
