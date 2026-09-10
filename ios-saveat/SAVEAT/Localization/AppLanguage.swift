import Foundation
import SwiftUI

/// Languages SAVEAT ships in.
///
/// French stays the production reference; English is written for a US audience
/// (US units, Fahrenheit, US date order). Spanish, Portuguese (Brazil),
/// Simplified Chinese and Hindi translate the catalog: screens stay untouched.
/// A missing translation falls back to English rather than rendering blank.
nonisolated enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case fr
    case en
    case es
    case ptBR
    case zhCN
    case hi

    nonisolated var id: String { rawValue }

    /// Shown in the settings picker, always in its own language.
    nonisolated var displayName: String {
        switch self {
        case .fr: "Français"
        case .en: "English (US)"
        case .es: "Español"
        case .ptBR: "Português (Brasil)"
        case .zhCN: "简体中文"
        case .hi: "हिन्दी"
        }
    }

    nonisolated var flag: String {
        switch self {
        case .fr: "🇫🇷"
        case .en: "🇺🇸"
        case .es: "🇪🇸"
        case .ptBR: "🇧🇷"
        case .zhCN: "🇨🇳"
        case .hi: "🇮🇳"
        }
    }

    /// Locale used for dates, numbers and system-formatted values.
    nonisolated var locale: Locale {
        switch self {
        case .fr: Locale(identifier: "fr_FR")
        case .en: Locale(identifier: "en_US")
        case .es: Locale(identifier: "es_ES")
        case .ptBR: Locale(identifier: "pt_BR")
        case .zhCN: Locale(identifier: "zh_CN")
        case .hi: Locale(identifier: "hi_IN")
        }
    }

    /// Spanish, Portuguese, Chinese and Hindi use metric measures; US English
    /// uses oz / cups / Fahrenheit. French keeps grams / millilitres / Celsius.
    nonisolated var usesMetric: Bool { self != .en }

    /// Comma decimal separator (1,5 kg) as written in France, Spain and Brazil.
    nonisolated var usesCommaDecimal: Bool {
        switch self {
        case .fr, .es, .ptBR: true
        case .en, .zhCN, .hi: false
        }
    }

    /// Day-first printed dates (09/12 = 9 December) for fr, es, pt-BR and hi;
    /// month-first for US packs. China writes year-first, which the numeric
    /// patterns still parse month-first — acceptable for the two-digit year
    /// formats on Chinese packaging.
    nonisolated var readsDayFirstDates: Bool {
        switch self {
        case .fr, .es, .ptBR, .hi: true
        case .en, .zhCN: false
        }
    }

    /// Language name handed to the recipe assistant.
    nonisolated var promptLanguage: String {
        switch self {
        case .fr: "français"
        case .en: "American English"
        case .es: "español de España"
        case .ptBR: "português do Brasil"
        case .zhCN: "简体中文"
        case .hi: "हिन्दी"
        }
    }

    /// Open Food Facts language code, used to pick the right product field.
    nonisolated var offCode: String {
        switch self {
        case .fr: "fr"
        case .en: "en"
        case .es: "es"
        case .ptBR: "pt"
        case .zhCN: "zh"
        case .hi: "hi"
        }
    }

    /// Language matching the phone, falling back to English for everything else.
    nonisolated static var deviceDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let prefix = preferred.lowercased()
        if prefix.hasPrefix("fr") { return .fr }
        if prefix.hasPrefix("es") { return .es }
        if prefix.hasPrefix("pt") { return .ptBR }
        if prefix.hasPrefix("zh") { return .zhCN }
        if prefix.hasPrefix("hi") { return .hi }
        return .en
    }
}

/// Thread-safe holder for the language currently in use.
///
/// Lives outside SwiftUI so `nonisolated` model code (enum titles, formatters,
/// notification copy) can resolve wording without hopping to the main actor.
nonisolated enum LanguageRuntime {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var value: AppLanguage = .fr

    nonisolated static var current: AppLanguage {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    nonisolated static func set(_ language: AppLanguage) {
        lock.lock()
        value = language
        lock.unlock()
    }
}

/// A piece of copy in every supported language.
///
/// The whole catalog lives in `Strings.swift`; screens only reference entries,
/// never raw text, so a new language is a catalog change rather than a UI change.
/// Spanish, Portuguese, Chinese and Hindi live in side tables keyed by the
/// English source string — a missing entry falls back to English, never blank.
nonisolated struct Loc: Sendable {
    private let fr: String
    private let en: String

    nonisolated init(fr: String, en: String) {
        self.fr = fr
        self.en = en
    }

    /// Resolved copy for the language currently selected.
    nonisolated var s: String {
        switch LanguageRuntime.current {
        case .fr: fr
        case .en: en
        default: TranslationCatalog.value(for: en, in: LanguageRuntime.current) ?? en
        }
    }

    /// Resolved copy for a specific language, used by notifications and prompts.
    nonisolated func s(in language: AppLanguage) -> String {
        switch language {
        case .fr: fr
        case .en: en
        default: TranslationCatalog.value(for: en, in: language) ?? en
        }
    }

    /// Fills `%@` / `%d` placeholders in the resolved copy.
    nonisolated func f(_ arguments: CVarArg...) -> String {
        String(format: s, arguments: arguments)
    }
}

/// Per-language translation tables, keyed by the English source string.
///
/// One file per language under `Localization/Translations/`. Lookups are cheap
/// dictionary hits; a missing key returns nil and the caller falls back to
/// English so new copy can ship before its translation lands.
nonisolated enum TranslationCatalog {
    nonisolated static func value(for english: String, in language: AppLanguage) -> String? {
        switch language {
        case .fr, .en: nil
        case .es: StringsEs.table[english]
        case .ptBR: StringsPtBR.table[english]
        case .zhCN: StringsZhCN.table[english]
        case .hi: StringsHi.table[english]
        }
    }
}

/// Selected language, persisted across launches.
///
/// Changing it only swaps wording and formatting — no stored food, date,
/// history or subscription is touched.
@Observable
final class LanguageStore {
    private static let storageKey = "saveat.language.v1"

    var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
            LanguageRuntime.set(language)
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    /// True until the user picks a language by hand: the app keeps following the phone.
    private(set) var isFollowingDevice: Bool

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        let resolved = stored.flatMap(AppLanguage.init(rawValue:)) ?? AppLanguage.deviceDefault
        language = resolved
        isFollowingDevice = stored == nil
        LanguageRuntime.set(resolved)
    }

    /// Records an explicit choice from the settings screen.
    func select(_ newLanguage: AppLanguage) {
        isFollowingDevice = false
        language = newLanguage
    }

    var locale: Locale { language.locale }
}
