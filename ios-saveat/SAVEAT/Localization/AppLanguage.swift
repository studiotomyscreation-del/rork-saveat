import Foundation
import SwiftUI

/// Languages SAVEAT ships in.
///
/// French stays the production reference; English is written for a US audience
/// (US units, Fahrenheit, US date order). Adding a language later means adding a
/// case here and one more entry per `Loc` in the catalog — screens stay untouched.
nonisolated enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case fr
    case en

    nonisolated var id: String { rawValue }

    /// Shown in the settings picker, always in its own language.
    nonisolated var displayName: String {
        switch self {
        case .fr: "Français"
        case .en: "English (US)"
        }
    }

    nonisolated var flag: String {
        switch self {
        case .fr: "🇫🇷"
        case .en: "🇺🇸"
        }
    }

    /// Locale used for dates, numbers and system-formatted values.
    nonisolated var locale: Locale {
        switch self {
        case .fr: Locale(identifier: "fr_FR")
        case .en: Locale(identifier: "en_US")
        }
    }

    /// French uses grams / millilitres / Celsius, US English uses oz / cups / Fahrenheit.
    nonisolated var usesMetric: Bool { self == .fr }

    /// Language name handed to the recipe assistant.
    nonisolated var promptLanguage: String {
        switch self {
        case .fr: "français"
        case .en: "American English"
        }
    }

    /// Open Food Facts language code, used to pick the right product field.
    nonisolated var offCode: String {
        switch self {
        case .fr: "fr"
        case .en: "en"
        }
    }

    /// Language matching the phone, falling back to English for everything else.
    nonisolated static var deviceDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.lowercased().hasPrefix("fr") ? .fr : .en
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
        }
    }

    /// Resolved copy for a specific language, used by notifications and prompts.
    nonisolated func s(in language: AppLanguage) -> String {
        switch language {
        case .fr: fr
        case .en: en
        }
    }

    /// Fills `%@` / `%d` placeholders in the resolved copy.
    nonisolated func f(_ arguments: CVarArg...) -> String {
        String(format: s, arguments: arguments)
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
