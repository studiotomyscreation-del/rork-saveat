import Foundation
import Testing
@testable import SAVEAT

/// LANGUAGE ≠ MARKET: the four country × language combinations from the
/// Phase 1 brief, plus resolution priority and fallback.
///
/// Serialized because `LanguageRuntime` and `MarketRuntime` are process-wide.
@MainActor
@Suite(.serialized)
struct MarketContextTests {

    /// Sets both runtimes, runs `body`, then restores what was there before.
    private func with(country: String, language: AppLanguage, _ body: () -> Void) {
        let previousMarket = MarketRuntime.current
        let previousLanguage = LanguageRuntime.current
        MarketRuntime.set(MarketContext.make(countryCode: country, source: .manual))
        LanguageRuntime.set(language)
        body()
        MarketRuntime.set(previousMarket)
        LanguageRuntime.set(previousLanguage)
    }

    // MARK: - FR market

    @Test func franceInFrenchIsEuroMetricKilometers() {
        with(country: "FR", language: .fr) {
            let market = MarketRuntime.current
            #expect(market.countryCode == "FR")
            #expect(market.currencyCode == "EUR")
            #expect(market.measurementSystem == .metric)
            #expect(market.distanceUnit == .kilometers)
            #expect(market.nutritionPresentation.showsNutriScore)
            #expect(market.dateVocabulary == .dlcDdm)
            #expect(market.printedDateOrder == .dayFirst)
            #expect(Money.code == "EUR")
            #expect(Units.distance(kilometers: 5).hasSuffix("km"))
            #expect(Units.weight(grams: 500) == "500 g")
            #expect(Units.ovenTemperature(celsius: 180) == "180 °C")
        }
    }

    @Test func franceInEnglishStaysEuroMetricKilometers() {
        with(country: "FR", language: .en) {
            let market = MarketRuntime.current
            #expect(market.currencyCode == "EUR")
            #expect(market.measurementSystem == .metric)
            #expect(market.distanceUnit == .kilometers)
            #expect(market.nutritionPresentation.showsNutriScore)
            #expect(Money.code == "EUR")
            #expect(Units.distance(kilometers: 5).hasSuffix("km"))
            #expect(Units.weight(grams: 500) == "500 g")
            #expect(Units.ovenTemperature(celsius: 180) == "180 °C")
        }
    }

    // MARK: - US market

    @Test func unitedStatesInEnglishIsDollarCustomaryMiles() {
        with(country: "US", language: .en) {
            let market = MarketRuntime.current
            #expect(market.countryCode == "US")
            #expect(market.currencyCode == "USD")
            #expect(market.measurementSystem == .usCustomary)
            #expect(market.distanceUnit == .miles)
            #expect(market.nutritionPresentation == .usNutritionFacts)
            #expect(!market.nutritionPresentation.showsNutriScore)
            #expect(market.dateVocabulary == .useByBestBy)
            #expect(market.printedDateOrder == .monthFirst)
            #expect(market.addressFormat == .us)
            #expect(market.businessRegistry == .unavailable)
            #expect(Money.code == "USD")
            #expect(Units.distance(kilometers: 5).hasSuffix("mi"))
            #expect(Units.weight(grams: 500).hasSuffix("lb"))
            #expect(Units.ovenTemperature(celsius: 180) == "355°F")
        }
    }

    @Test func unitedStatesInFrenchStaysDollarCustomaryMiles() {
        with(country: "US", language: .fr) {
            let market = MarketRuntime.current
            #expect(market.currencyCode == "USD")
            #expect(market.measurementSystem == .usCustomary)
            #expect(market.distanceUnit == .miles)
            #expect(!market.nutritionPresentation.showsNutriScore)
            #expect(Money.code == "USD")
            #expect(Units.distance(kilometers: 5).hasSuffix("mi"))
            #expect(Units.weight(grams: 500).hasSuffix("lb"))
            #expect(Units.ovenTemperature(celsius: 180) == "355°F")
        }
    }

    // MARK: - Resolution

    @Test func manualChoiceWinsOverPhoneRegion() {
        let market = MarketContext.resolve(manualCountryCode: "US", deviceRegionCode: "FR")
        #expect(market.countryCode == "US")
        #expect(market.source == .manual)
    }

    @Test func phoneRegionIsUsedWithoutManualChoice() {
        let market = MarketContext.resolve(manualCountryCode: nil, deviceRegionCode: "us")
        #expect(market.countryCode == "US")
        #expect(market.source == .deviceRegion)
    }

    @Test func missingOrInvalidRegionFallsBackToFrance() {
        let missing = MarketContext.resolve(manualCountryCode: nil, deviceRegionCode: nil)
        #expect(missing.countryCode == "FR")
        #expect(missing.source == .fallback)

        let numeric = MarketContext.resolve(manualCountryCode: "", deviceRegionCode: "001")
        #expect(numeric.countryCode == "FR")
        #expect(numeric.source == .fallback)
    }

    @Test func unitedKingdomKeepsMetricFoodButMilesAndPounds() {
        let market = MarketContext.make(countryCode: "GB", source: .deviceRegion)
        #expect(market.currencyCode == "GBP")
        #expect(market.measurementSystem == .metric)
        #expect(market.distanceUnit == .miles)
        #expect(!market.nutritionPresentation.showsNutriScore)
    }

    @Test func canadaIsDollarMetricKilometers() {
        let market = MarketContext.make(countryCode: "CA", source: .deviceRegion)
        #expect(market.currencyCode == "CAD")
        #expect(market.measurementSystem == .metric)
        #expect(market.distanceUnit == .kilometers)
    }
}
