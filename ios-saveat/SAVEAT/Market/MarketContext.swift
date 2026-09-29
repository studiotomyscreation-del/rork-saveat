import Foundation

/// The country a household shops in, and every commercial convention that
/// follows from it: currency, measures, distances, nutrition labelling,
/// packaging dates, address format and business registry.
///
/// LANGUAGE ≠ MARKET. The language only decides the wording (and how numbers
/// are written); this context decides everything else. A French speaker in
/// New York is in the US market, an English reader in Paris is in the French
/// market. Nothing in here ever reads `LanguageRuntime`.
///
/// Resolution order (see `resolve`):
/// 1. a country chosen by hand in Settings,
/// 2. the phone's region setting,
/// 3. `fallbackCountryCode`, only when the phone reports no usable region.
/// Location is deliberately not used: the region setting is enough, and it
/// needs no permission.
nonisolated struct MarketContext: Equatable, Sendable {
    nonisolated enum MeasurementSystem: String, Sendable {
        case metric
        case usCustomary
    }

    nonisolated enum DistanceUnit: String, Sendable {
        case kilometers
        case miles
    }

    /// How product nutrition is presented.
    nonisolated enum NutritionPresentation: String, Sendable {
        /// Per 100 g with the official Nutri-Score, where it is officially adopted.
        case nutriScore
        /// US Nutrition Facts conventions; Nutri-Score has no standing there.
        case usNutritionFacts
        /// Per 100 g, without Nutri-Score.
        case per100g

        nonisolated var showsNutriScore: Bool { self == .nutriScore }
    }

    /// Which kind of wording packs in this market print for dates.
    nonisolated enum DateVocabulary: String, Sendable {
        /// DLC / DDM (France, Belgium, Luxembourg, Switzerland).
        case dlcDdm
        /// Use By / Best By (United States).
        case useByBestBy
        /// Generic "best before" wording elsewhere.
        case bestBefore
    }

    /// The order numeric dates are printed in on local packaging.
    nonisolated enum PrintedDateOrder: String, Sendable {
        case dayFirst
        case monthFirst
    }

    nonisolated enum AddressFormat: String, Sendable {
        /// Street, postal code + city.
        case france
        /// Street, city, state, ZIP code.
        case us
        case generic
    }

    /// Which official registry can identify a professional in this market.
    nonisolated enum BusinessRegistry: String, Sendable {
        case franceSIRET
        /// No provider yet — a US one is planned, not built.
        case unavailable
    }

    /// Where the country code came from.
    nonisolated enum Source: String, Sendable {
        case manual
        case deviceRegion
        case fallback
    }

    /// ISO 3166-1 alpha-2, uppercase ("FR", "US").
    let countryCode: String
    /// ISO 4217 ("EUR", "USD").
    let currencyCode: String
    let measurementSystem: MeasurementSystem
    let distanceUnit: DistanceUnit
    let nutritionPresentation: NutritionPresentation
    let dateVocabulary: DateVocabulary
    let printedDateOrder: PrintedDateOrder
    let addressFormat: AddressFormat
    let businessRegistry: BusinessRegistry
    /// The market's own default locale ("fr-FR", "en-US"). Wording and number
    /// writing still follow the reader's language, not this.
    let localeIdentifier: String
    let source: Source

    /// Always the user's own time zone — the US alone spans several, so a
    /// market never implies one.
    nonisolated var timeZone: TimeZone { .current }

    nonisolated var usesMetric: Bool { measurementSystem == .metric }

    /// Locale combining the reader's language with this market's region,
    /// e.g. French read in the US → `fr_US`.
    nonisolated func locale(for language: AppLanguage) -> Locale {
        Locale(identifier: "\(language.languageCode)_\(countryCode)")
    }

    // MARK: - Resolution

    /// Used only when neither a manual choice nor a valid phone region exists.
    /// France is SAVEAT's home market, so existing behaviour is preserved.
    nonisolated static let fallbackCountryCode = "FR"

    /// Resolves the market. Takes no language input by design.
    nonisolated static func resolve(manualCountryCode: String?, deviceRegionCode: String?) -> MarketContext {
        if let code = normalized(manualCountryCode) {
            return make(countryCode: code, source: .manual)
        }
        if let code = normalized(deviceRegionCode) {
            return make(countryCode: code, source: .deviceRegion)
        }
        return make(countryCode: fallbackCountryCode, source: .fallback)
    }

    /// Two ASCII letters, uppercased — rejects numeric UN regions like "001".
    nonisolated static func normalized(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let code = raw.trimmingCharacters(in: .whitespaces).uppercased()
        guard code.count == 2, code.allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }
        return code
    }

    nonisolated static func make(countryCode code: String, source: Source) -> MarketContext {
        MarketContext(
            countryCode: code,
            currencyCode: currency(for: code),
            measurementSystem: usCustomaryCountries.contains(code) ? .usCustomary : .metric,
            distanceUnit: milesCountries.contains(code) ? .miles : .kilometers,
            nutritionPresentation: nutritionPresentation(for: code),
            dateVocabulary: dateVocabulary(for: code),
            printedDateOrder: monthFirstCountries.contains(code) ? .monthFirst : .dayFirst,
            addressFormat: code == "FR" ? .france : (code == "US" ? .us : .generic),
            businessRegistry: code == "FR" ? .franceSIRET : .unavailable,
            localeIdentifier: "\(primaryLanguageCode(for: code))-\(code)",
            source: source
        )
    }

    // MARK: - Country rules

    /// Countries still measuring food in ounces, pounds and Fahrenheit.
    private static let usCustomaryCountries: Set<String> = ["US", "LR"]

    /// Road distances in miles. The UK stays metric for food but not for roads.
    private static let milesCountries: Set<String> = ["US", "GB", "LR"]

    /// Countries that have officially adopted Nutri-Score.
    private static let nutriScoreCountries: Set<String> = ["FR", "BE", "ES", "DE", "LU", "NL", "CH"]

    /// Packs print month-first. China is listed to keep the date-reading
    /// preference it had before markets existed; both orders are still tried.
    private static let monthFirstCountries: Set<String> = ["US", "CN"]

    private static let knownCurrencies: [String: String] = [
        "FR": "EUR", "BE": "EUR", "ES": "EUR", "IT": "EUR", "DE": "EUR", "LU": "EUR", "NL": "EUR",
        "US": "USD", "CA": "CAD", "GB": "GBP", "CH": "CHF", "BR": "BRL", "CN": "CNY", "IN": "INR"
    ]

    private nonisolated static func currency(for code: String) -> String {
        if let known = knownCurrencies[code] { return known }
        if let derived = Locale(identifier: "en_\(code)").currency?.identifier, derived.count == 3 {
            return derived.uppercased()
        }
        return "EUR"
    }

    private nonisolated static func nutritionPresentation(for code: String) -> NutritionPresentation {
        if nutriScoreCountries.contains(code) { return .nutriScore }
        if code == "US" { return .usNutritionFacts }
        return .per100g
    }

    private nonisolated static func dateVocabulary(for code: String) -> DateVocabulary {
        switch code {
        case "FR", "BE", "LU", "CH": .dlcDdm
        case "US": .useByBestBy
        default: .bestBefore
        }
    }

    private nonisolated static func primaryLanguageCode(for code: String) -> String {
        switch code {
        case "FR", "BE", "CH", "LU": "fr"
        case "ES": "es"
        case "IT": "it"
        case "DE": "de"
        case "BR": "pt"
        case "CN": "zh"
        case "IN": "hi"
        default: "en"
        }
    }
}
