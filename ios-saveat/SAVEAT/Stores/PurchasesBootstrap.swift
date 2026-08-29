import Foundation
import RevenueCat

/// Which RevenueCat store the app is talking to for this build.
nonisolated enum PurchaseEnvironment: Equatable, Sendable {
    /// RevenueCat Test Store — works without any Apple production setup.
    case testStore
    /// Real App Store products through the Apple platform key.
    case appStore
    /// No usable API key: purchases are disabled, the app must degrade gracefully.
    case unconfigured

    nonisolated var isTestStore: Bool { self == .testStore }
    nonisolated var allowsPurchases: Bool { self != .unconfigured }

    nonisolated var label: String {
        switch self {
        case .testStore: "Test Store"
        case .appStore: "App Store"
        case .unconfigured: "non configuré"
        }
    }
}

/// Configures RevenueCat exactly once at launch and records which store is active.
///
/// SAVEAT now sells real App Store products, so **every build — Debug, TestFlight
/// and App Store — is configured with the public App Store SDK key (`appl_…`)**.
/// The RevenueCat Test Store key is no longer read at all: a single key means the
/// sandbox chain that gets tested is exactly the one that ships.
///
/// Any key that is not an `appl_` key is refused *before* `Purchases.configure`.
/// This matters because RevenueCat's own
/// `Configuration.checkForSimulatedStoreAPIKeyInRelease` raises a `fatalError`
/// (EXC_BREAKPOINT / SIGTRAP at launch) when a simulated-store key reaches a
/// Release binary. Refusing it here means a misconfigured build degrades
/// gracefully — premium is disabled, the whole core SAVEAT loop keeps working —
/// instead of crashing on the splash screen.
nonisolated enum PurchasesBootstrap {
    /// The only key prefix SAVEAT accepts: the public App Store SDK key.
    private static let appStoreKeyPrefix = "appl_"

    private(set) nonisolated(unsafe) static var environment: PurchaseEnvironment = .unconfigured
    private(set) nonisolated(unsafe) static var redactedKey: String = "—"
    /// Human-readable reason why purchases are unavailable, surfaced in diagnostics.
    private(set) nonisolated(unsafe) static var configurationIssue: String?

    /// Which build configuration this binary was compiled with.
    static var buildConfigurationLabel: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }

    static var isConfigured: Bool { environment.allowsPurchases }

    /// Developer tooling: always available in Debug, and in shipped builds only when
    /// the purchase stack failed to configure, so the reason is never invisible.
    static var showsDiagnostics: Bool {
        #if DEBUG
        return true
        #else
        return configurationIssue != nil
        #endif
    }

    static func configure() {
        let appStoreKey = Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY.trimmingCharacters(in: .whitespacesAndNewlines)

        guard appStoreKey.hasPrefix(appStoreKeyPrefix) else {
            environment = .unconfigured
            if appStoreKey.isEmpty {
                configurationIssue = "Aucune clé RevenueCat App Store (« appl_ ») n'est configurée pour ce build."
                PurchaseLog.error("missing EXPO_PUBLIC_REVENUECAT_IOS_API_KEY — premium disabled, core app unaffected")
            } else {
                configurationIssue = "La clé RevenueCat fournie n'est pas une clé publique App Store (« appl_ »)."
                PurchaseLog.error("refused a non-'appl_' RevenueCat key before configure() — only the App Store public SDK key is accepted")
            }
            return
        }

        // Verbose SDK logs while developing; quiet in TestFlight / App Store builds.
        #if DEBUG
        Purchases.logLevel = .info
        #else
        Purchases.logLevel = .error
        #endif
        Purchases.configure(withAPIKey: appStoreKey)

        environment = .appStore
        redactedKey = Self.redact(appStoreKey)
        configurationIssue = nil
        PurchaseLog.info("configured store=\(environment.label) key=\(redactedKey) build=\(buildConfigurationLabel)")
    }

    /// Keeps only the key prefix and last 4 characters — never logs a full key.
    private static func redact(_ key: String) -> String {
        guard key.count > 12 else { return "***" }
        let prefix = key.prefix(5)
        let suffix = key.suffix(4)
        return "\(prefix)…\(suffix)"
    }
}

/// Small tagged logger so the subscription flow can be traced in the runtime logs.
nonisolated enum PurchaseLog {
    static func info(_ message: String) {
        print("[SAVEAT/RC] \(message)")
    }

    static func error(_ message: String) {
        print("[SAVEAT/RC] ERROR \(message)")
    }
}
