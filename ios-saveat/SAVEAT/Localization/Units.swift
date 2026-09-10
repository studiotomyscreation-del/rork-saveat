import Foundation

/// Locale-aware measurements, money and dates.
///
/// French keeps grams / millilitres / Celsius and French date order. US English
/// gets ounces, pounds, fluid ounces, cups and Fahrenheit. Nothing here invents a
/// value: a conversion is only shown when it is honest for that ingredient.
nonisolated enum Units {
    // MARK: - Weight

    private static let gramsPerOunce: Double = 28.3495
    private static let gramsPerPound: Double = 453.592

    /// A weight in grams, rendered in the reader's system.
    ///
    /// US output switches to pounds past one pound, since "26 oz of chicken" is
    /// not how an American cook reads a pack.
    nonisolated static func weight(grams value: Double) -> String {
        guard !LanguageRuntime.current.usesMetric else {
            return Format.grams(value)
        }
        if value >= gramsPerPound {
            let pounds = value / gramsPerPound
            return trimmed(pounds, decimals: pounds < 10 ? 1 : 0) + " lb"
        }
        let ounces = value / gramsPerOunce
        return trimmed(ounces, decimals: ounces < 10 ? 1 : 0) + " oz"
    }

    // MARK: - Volume

    private static let millilitresPerFluidOunce: Double = 29.5735
    private static let millilitresPerCup: Double = 236.588

    /// A volume in millilitres, rendered in the reader's system.
    ///
    /// Cups only appear from one cup up, where they are the natural US unit;
    /// smaller amounts stay in fluid ounces rather than becoming odd fractions.
    nonisolated static func volume(millilitres value: Double) -> String {
        guard !LanguageRuntime.current.usesMetric else {
            if value >= 1_000 {
                return trimmed(value / 1_000, decimals: 1) + " L"
            }
            return "\(Int(value.rounded())) ml"
        }
        if value >= millilitresPerCup {
            let cups = value / millilitresPerCup
            return trimmed(cups, decimals: 2) + (cups > 1.01 ? " cups" : " cup")
        }
        let ounces = value / millilitresPerFluidOunce
        return trimmed(ounces, decimals: ounces < 10 ? 1 : 0) + " fl oz"
    }

    // MARK: - Temperature

    /// An oven temperature in Celsius, rendered in the reader's system.
    ///
    /// Fahrenheit is rounded to the nearest 5° because ovens are set in steps,
    /// not to the degree.
    nonisolated static func ovenTemperature(celsius value: Double) -> String {
        guard !LanguageRuntime.current.usesMetric else {
            return "\(Int(value.rounded())) °C"
        }
        let fahrenheit = value * 9 / 5 + 32
        let rounded = (fahrenheit / 5).rounded() * 5
        return "\(Int(rounded))°F"
    }

    // MARK: - Weight in the pack unit

    /// Rewrites a packaging quantity such as "500 g" or "1 L" for a US reader.
    ///
    /// Anything it cannot parse with confidence is returned untouched rather
    /// than guessed at.
    nonisolated static func packaging(_ raw: String) -> String {
        guard !LanguageRuntime.current.usesMetric else { return raw }

        let text = raw.lowercased().replacingOccurrences(of: ",", with: ".")
        let scanner = Scanner(string: text)
        scanner.charactersToBeSkipped = .whitespaces
        guard let amount = scanner.scanDouble() else { return raw }
        let rest = text[scanner.currentIndex...].trimmingCharacters(in: .whitespaces)

        switch rest {
        case "kg": return weight(grams: amount * 1_000)
        case "g", "gr": return weight(grams: amount)
        case "l", "litre", "litres": return volume(millilitres: amount * 1_000)
        case "cl": return volume(millilitres: amount * 10)
        case "ml": return volume(millilitres: amount)
        default: return raw
        }
    }

    // MARK: - Money

    /// Formats an estimated value in the reader's currency.
    ///
    /// This is only ever used for SAVEAT's own savings estimates — never for a
    /// subscription price, which always comes from the App Store itself.
    nonisolated static func money(_ value: Double, decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.locale = LanguageRuntime.current.locale
        formatter.numberStyle = .currency
        formatter.currencyCode = Money.code
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: value)) ?? Format.money(value, decimals: decimals)
    }

    /// Currency code behind SAVEAT's own savings estimates.
    nonisolated static var currencyCode: String { Money.code }

    /// Currency symbol used in short labels such as "0 €" / "$0".
    nonisolated static var currencySymbol: String { Money.symbol }

    /// Cost badge for a meal that needs no extra shopping: "0 €" / "$0".
    ///
    /// Only ever used where a price is expected. English copy never turns this
    /// into a "$0 meals" phrase, which could read as SAVEAT handing out free food.
    nonisolated static var zeroCostLabel: String {
        Money.symbolLeads ? "\(Money.symbol)0" : "0\u{00a0}\(Money.symbol)"
    }

    // MARK: - Mass for impact figures

    /// Food weight avoided, in the reader's system.
    nonisolated static func foodMass(kilograms value: Double) -> String {
        guard !LanguageRuntime.current.usesMetric else {
            return Format.kg(value)
        }
        let pounds = value * 2.20462
        return trimmed(pounds, decimals: 1) + " lb"
    }

    // MARK: - Dates

    /// Short date such as "12 sept." or "Sep 12", following the reader's locale.
    nonisolated static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageRuntime.current.locale
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter.string(from: date)
    }

    /// Medium date such as "12 septembre 2026" or "September 12, 2026".
    nonisolated static func mediumDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageRuntime.current.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Weekday plus day, such as "lundi 12" or "Monday 12".
    nonisolated static func weekdayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageRuntime.current.locale
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM")
        return formatter.string(from: date)
    }

    /// Month and year, such as "septembre 2026" or "September 2026".
    nonisolated static func monthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageRuntime.current.locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date)
    }

    /// Clock time such as "09:00" or "9:00 AM".
    nonisolated static func time(hour: Int, minute: Int = 0) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? .now
        let formatter = DateFormatter()
        formatter.locale = LanguageRuntime.current.locale
        formatter.setLocalizedDateFormatFromTemplate("j:mm")
        return formatter.string(from: date)
    }

    // MARK: - Helpers

    private nonisolated static func trimmed(_ value: Double, decimals: Int) -> String {
        let factor = pow(10.0, Double(decimals))
        let rounded = (value * factor).rounded() / factor
        if rounded == rounded.rounded() { return "\(Int(rounded))" }

        let formatter = NumberFormatter()
        formatter.locale = LanguageRuntime.current.locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: rounded)) ?? "\(rounded)"
    }
}

/// The currency SAVEAT's own estimates are shown in.
///
/// It follows the phone's country, exactly like the App Store does when it
/// bills someone, and deliberately NOT the language being read. Someone in
/// Quebec sees Canadian dollars whether they read French or English, someone
/// in London sees pounds either way, and a French speaker living in the US
/// sees dollars. Language only decides how the number is written and which
/// side the symbol sits on.
///
/// Subscription prices never pass through here — those always come straight
/// from the App Store.
nonisolated enum Money {
    /// ISO code for the phone's region, falling back to the language's home
    /// currency when the device does not report one.
    nonisolated static var code: String {
        if let identifier = Locale.current.currency?.identifier.uppercased(),
           identifier.count == 3 {
            return identifier
        }
        return languageFallbackCode
    }

    /// Symbol for the resolved currency, with the ambiguous ones spelled the
    /// way the local shopper writes them.
    nonisolated static var symbol: String {
        switch code {
        case "EUR": "€"
        case "USD", "CAD", "AUD", "NZD", "MXN": "$"
        case "GBP": "£"
        case "BRL": "R$"
        case "CNY", "JPY": "¥"
        case "INR": "₹"
        case "CHF": "CHF"
        default: Locale.current.currencySymbol ?? code
        }
    }

    /// True where the symbol comes before the number ($12) rather than after
    /// it (12 €). This is a writing convention, so it follows the language.
    nonisolated static var symbolLeads: Bool {
        switch LanguageRuntime.current {
        case .fr, .es: false
        case .en, .enGB, .ptBR, .zhCN, .hi: true
        }
    }

    /// Home currency of the language, used only when the device region is
    /// unavailable — never in place of a real region.
    private nonisolated static var languageFallbackCode: String {
        switch LanguageRuntime.current {
        case .fr, .es: "EUR"
        case .en: "USD"
        case .enGB: "GBP"
        case .ptBR: "BRL"
        case .zhCN: "CNY"
        case .hi: "INR"
        }
    }
}
