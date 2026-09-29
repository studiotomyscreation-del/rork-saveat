import Foundation
import Testing
@testable import SAVEAT

/// Phase 2 — barcode identity. Every expected value below was computed by hand
/// from the GS1 mod-10 rule and the UPC-E expansion table, and the real codes
/// (Coca-Cola, Nutella…) were checked against Open Food Facts.
struct NormalizedGTINTests {

    // MARK: - Supported formats

    @Test func validGTIN8() {
        let gtin = NormalizedGTIN(parsing: "96385074", hint: .ean8)
        #expect(gtin.format == .gtin8)
        #expect(gtin.validity == .valid)
        #expect(gtin.normalizedValue == "00000096385074")
    }

    @Test func validUPCA() {
        let gtin = NormalizedGTIN(parsing: "036000291452")
        #expect(gtin.format == .upcA)
        #expect(gtin.validity == .valid)
        #expect(gtin.normalizedValue == "00036000291452")
    }

    @Test func validEAN13() {
        let french = NormalizedGTIN(parsing: "3017620422003")
        #expect(french.format == .ean13)
        #expect(french.validity == .valid)
        #expect(french.normalizedValue == "03017620422003")

        let german = NormalizedGTIN(parsing: "4006381333931")
        #expect(german.validity == .valid)
        #expect(german.normalizedValue == "04006381333931")
    }

    @Test func validGTIN14() {
        let gtin = NormalizedGTIN(parsing: "10036000291459")
        #expect(gtin.format == .gtin14)
        #expect(gtin.validity == .valid)
        #expect(gtin.normalizedValue == "10036000291459")
    }

    @Test func validUPCE() {
        let gtin = NormalizedGTIN(parsing: "04963406", hint: .upcE)
        #expect(gtin.format == .upcE)
        #expect(gtin.validity == .valid)
        #expect(gtin.expandedUPCA == "049000006346")
        #expect(gtin.normalizedValue == "00049000006346")
    }

    // MARK: - UPC-E → UPC-A (every branch of the table)

    @Test func upcEExpansionFollowsTheOfficialTable() {
        // d6 = 0, 1, 2 → manufacturer d1 d2 d6 0 0, item 0 0 d3 d4 d5
        #expect(UPCE.expand("01234505") == "012000003455")
        #expect(UPCE.expand("04252614") == "042100005264")
        // d6 = 3 → manufacturer d1 d2 d3 0 0, item 0 0 0 d4 d5
        #expect(UPCE.expand("01234531") == "012300000451")
        // d6 = 4 → manufacturer d1 d2 d3 d4 0, item 0 0 0 0 d5
        #expect(UPCE.expand("01234543") == "012340000053")
        // d6 = 5…9 → manufacturer d1…d5, item 0 0 0 0 d6
        #expect(UPCE.expand("01234572") == "012345000072")
        #expect(UPCE.expand("04963406") == "049000006346")
        // Number system 1
        #expect(UPCE.expand("11234520") == "112200003450")
    }

    @Test func upcEExpansionIsNotPadding() {
        let expanded = UPCE.expand("04252614")
        #expect(expanded != "000004252614")
        #expect(expanded.map(GTINCheckDigit.isValid) == true)
    }

    @Test func upcERejectsOtherNumberSystems() {
        #expect(UPCE.expand("24252614") == nil)
        let gtin = NormalizedGTIN(parsing: "24252614", hint: .upcE)
        #expect(gtin.validity == .invalid(.upcEStructure))
        #expect(gtin.normalizedValue == nil)
    }

    // MARK: - Check digit

    @Test func checkDigitValid() {
        #expect(GTINCheckDigit.compute(for: "03600029145") == "2")
        #expect(GTINCheckDigit.compute(for: "301762042200") == "3")
        #expect(GTINCheckDigit.compute(for: "9638507") == "4")
        #expect(GTINCheckDigit.compute(for: "1003600029145") == "9")
        #expect(GTINCheckDigit.isValid("0049000028911"))
    }

    @Test func checkDigitInvalidIsReportedNotThrown() {
        let cases = ["036000291453", "3017620422004", "96385075", "10036000291458"]
        for code in cases {
            let gtin = NormalizedGTIN(parsing: code)
            #expect(gtin.validity == .invalid(.checkDigit), "\(code)")
            #expect(gtin.normalizedValue == nil)
            // The scan keeps going with the code exactly as read.
            #expect(gtin.lookupCode == code)
        }
        let upcE = NormalizedGTIN(parsing: "04252615", hint: .upcE)
        #expect(upcE.validity == .invalid(.checkDigit))
        #expect(upcE.expandedUPCA == "042100005265")
    }

    // MARK: - Leading zeros & sanitisation

    @Test func leadingZerosArePreserved() {
        let gtin = NormalizedGTIN(parsing: "0049000028911")
        #expect(gtin.rawValue == "0049000028911")
        #expect(gtin.digits == "0049000028911")
        #expect(gtin.lookupCode == "0049000028911")
        #expect(gtin.normalizedValue == "00049000028911")
        #expect(gtin.representation(length: 12) == "049000028911")
    }

    @Test func surroundingWhitespaceIsIgnoredButKeptInRaw() {
        let gtin = NormalizedGTIN(parsing: " 036000291452 \n")
        #expect(gtin.rawValue == " 036000291452 \n")
        #expect(gtin.lookupCode == "036000291452")
        #expect(gtin.validity == .valid)
        #expect(gtin == NormalizedGTIN(parsing: "036000291452"))
    }

    @Test func printedGroupingIsAccepted() {
        #expect(NormalizedGTIN(parsing: "0-36000-29145-2").normalizedValue == "00036000291452")
        #expect(NormalizedGTIN(parsing: "3 017620 422003").normalizedValue == "03017620422003")
    }

    @Test func nonNumericIsRefused() {
        for code in ["ABC123456789", "03600029145X", "0360.0029145", "０３６０００２９１４５２"] {
            let gtin = NormalizedGTIN(parsing: code)
            #expect(gtin.validity == .unsupported(.nonNumeric), "\(code)")
            #expect(gtin.normalizedValue == nil)
            #expect(gtin.format == nil)
        }
    }

    @Test func invalidLengthIsRefused() {
        #expect(NormalizedGTIN(parsing: "12345").validity == .unsupported(.length(5)))
        #expect(NormalizedGTIN(parsing: "1234567890").validity == .unsupported(.length(10)))
        #expect(NormalizedGTIN(parsing: "123456789012345").validity == .unsupported(.length(15)))
        #expect(NormalizedGTIN(parsing: "   ").validity == .unsupported(.empty))
    }

    // MARK: - Equivalence

    @Test func upcAMatchesItsCanonicalForms() {
        let upcA = NormalizedGTIN(parsing: "036000291452")
        let ean13 = NormalizedGTIN(parsing: "0036000291452")
        let gtin14 = NormalizedGTIN(parsing: "00036000291452")
        #expect(upcA == ean13)
        #expect(upcA == gtin14)
        #expect(Set([upcA, ean13, gtin14]).count == 1)
    }

    @Test func upcEMatchesItsUPCA() {
        let upcE = NormalizedGTIN(parsing: "04963406", hint: .upcE)
        let upcA = NormalizedGTIN(parsing: "049000006346")
        let ean13 = NormalizedGTIN(parsing: "0049000006346")
        #expect(upcE == upcA)
        #expect(upcE == ean13)
    }

    @Test func differentProductsDoNotMatch() {
        #expect(NormalizedGTIN(parsing: "036000291452") != NormalizedGTIN(parsing: "049000028911"))
        #expect(!NormalizedGTIN.sameProduct("3017620422003", "4006381333931"))
        // GS1 rule: a GTIN-8 and the same digits left-padded to 12 are one identity.
        #expect(NormalizedGTIN(parsing: "96385074", hint: .ean8) == NormalizedGTIN(parsing: "000096385074"))
    }

    @Test func invalidCodesOnlyMatchThemselves() {
        #expect(NormalizedGTIN(parsing: "036000291453") == NormalizedGTIN(parsing: " 036000291453"))
        #expect(NormalizedGTIN(parsing: "036000291453") != NormalizedGTIN(parsing: "036000291454"))
        #expect(!NormalizedGTIN.sameProduct("036000291453", "0036000291453"))
    }

    // MARK: - 8-digit ambiguity

    @Test func eightDigitsWithoutHint() {
        // Only valid as UPC-E → UPC-E.
        let onlyUPCE = NormalizedGTIN(parsing: "04963406")
        #expect(onlyUPCE.format == .upcE)
        #expect(onlyUPCE.normalizedValue == "00049000006346")
        #expect(!onlyUPCE.isAmbiguousEightDigit)

        // Only valid as GTIN-8 → GTIN-8.
        let onlyGTIN8 = NormalizedGTIN(parsing: "96385074")
        #expect(onlyGTIN8.format == .gtin8)

        // Valid both ways → literal GTIN-8 reading, flagged.
        let both = NormalizedGTIN(parsing: "12345670")
        #expect(both.format == .gtin8)
        #expect(both.isAmbiguousEightDigit)
        #expect(NormalizedGTIN(parsing: "12345670", hint: .upcE).normalizedValue == "00123456000070")
        // The same pack read with and without its symbology still matches.
        #expect(both.matches(NormalizedGTIN(parsing: "12345670", hint: .upcE)))
    }

    // MARK: - Legacy stock (read-time normalisation)

    @Test func legacyStockBarcodeMatchesAFreshScanWithoutBeingRewritten() {
        let stored = FoodItem(
            name: "Diet Coke", emoji: "🥤", quantity: 2, unit: "can",
            category: .grocery, location: .pantry, barcode: "049000028911"
        )
        let scanned = ScannedProduct(barcode: "0049000028911", name: "Diet Coke")

        #expect(stored.gtin == scanned.gtin)
        #expect(NormalizedGTIN.sameProduct(stored.barcode, scanned.barcode))
        #expect(stored.barcode == "049000028911")
        #expect(scanned.barcode == "0049000028911")
    }

    @Test func legacyNonGTINBarcodesKeepTheirHistoricalBehaviour() {
        #expect(NormalizedGTIN.sameProduct("DEMO-PATES", "DEMO-PATES"))
        #expect(!NormalizedGTIN.sameProduct("DEMO-PATES", "DEMO-RIZ"))
        #expect(!NormalizedGTIN.sameProduct(nil, "3017620422003"))
        #expect(!NormalizedGTIN.sameProduct(nil, nil))
        let item = FoodItem(name: "Tomates", emoji: "🍅", quantity: 1, unit: "unité", category: .produce, location: .fridge)
        #expect(item.gtin == nil)
    }

    @Test func legacyStockSurvivesADecodeRoundTripUntouched() throws {
        let item = FoodItem(
            name: "Nutella", emoji: "🍫", quantity: 1, unit: "pot",
            category: .grocery, location: .pantry, barcode: " 3017620422003"
        )
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(FoodItem.self, from: data)
        _ = decoded.gtin
        #expect(decoded.barcode == " 3017620422003")
        #expect(decoded.gtin?.normalizedValue == "03017620422003")
    }

    // MARK: - Open Food Facts / scanner non-regression

    @Test func lookupCodeIsWhatTheScannerRead() {
        // FR EAN-13, US UPC-A as delivered by AVFoundation (13 digits), US UPC-A typed
        // (12 digits), UPC-E (8 digits): OFF accepts each of these verbatim.
        let reads: [(String, NormalizedGTIN.SymbologyHint?)] = [
            ("3017620422003", .other),
            ("0049000028911", .other),
            ("049000028911", nil),
            ("04963406", .upcE),
            ("96385074", .ean8)
        ]
        for (code, hint) in reads {
            #expect(NormalizedGTIN(parsing: code, hint: hint).lookupCode == code)
        }
    }

    @Test func demoCatalogueCodesStillResolve() {
        for product in DemoCatalogue.all {
            let lookup = NormalizedGTIN(parsing: product.barcode).lookupCode
            #expect(DemoCatalogue.product(for: lookup) != nil, "\(product.barcode)")
        }
    }
}
