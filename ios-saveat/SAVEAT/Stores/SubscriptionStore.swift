import Foundation
import Observation
import RevenueCat
import StoreKit

/// The premium plans SAVEAT sells, derived from the RevenueCat product identifier.
nonisolated enum PremiumPlan: String, Sendable, Equatable {
    case monthly
    case yearly
    case lifetime
    case unknown

    /// Derived from the App Store product identifier, e.g. `saveat_pro_annual`
    /// → `.yearly`, `saveat_pro_monthly` → `.monthly`.
    nonisolated init(productIdentifier: String) {
        let id = productIdentifier.lowercased()
        if id.contains("life") || id.contains("vie") {
            self = .lifetime
        } else if id.contains("annual") || id.contains("annuel") || id.contains("year") || id.contains("yearly") {
            self = .yearly
        } else if id.contains("month") || id.contains("mensuel") || id.contains("mois") {
            self = .monthly
        } else {
            self = .unknown
        }
    }

    nonisolated var title: String {
        switch self {
        case .monthly: S.Subscription.planMonthly.s
        case .yearly: S.Subscription.planYearly.s
        case .lifetime: S.Subscription.planLifetime.s
        case .unknown: S.Subscription.planGeneric.s
        }
    }
}

/// Every subscription state the app must handle, mapped from `CustomerInfo`.
nonisolated enum SubscriptionStatus: Sendable, Equatable {
    case free
    case trial(plan: PremiumPlan, expiration: Date?)
    case active(plan: PremiumPlan, expiration: Date?)
    /// Still usable, but the user turned auto-renew off.
    case cancelled(plan: PremiumPlan, expiration: Date?)
    /// Apple could not charge the card — access is kept during the grace period.
    case billingIssue(plan: PremiumPlan, expiration: Date?)
    case lifetime
    case expired(plan: PremiumPlan, expiration: Date?)

    nonisolated var isPremium: Bool {
        switch self {
        case .free, .expired: false
        case .trial, .active, .cancelled, .billingIssue, .lifetime: true
        }
    }

    nonisolated var plan: PremiumPlan? {
        switch self {
        case .free: nil
        case .lifetime: .lifetime
        case .trial(let plan, _), .active(let plan, _), .cancelled(let plan, _),
             .billingIssue(let plan, _), .expired(let plan, _): plan
        }
    }

    nonisolated var expiration: Date? {
        switch self {
        case .free, .lifetime: nil
        case .trial(_, let date), .active(_, let date), .cancelled(_, let date),
             .billingIssue(_, let date), .expired(_, let date): date
        }
    }

    /// Short status line shown in the profile.
    nonisolated var headline: String {
        switch self {
        case .free: S.Subscription.freeHeadline.s
        case .trial: S.Subscription.trialHeadline.s
        case .active(let plan, _): plan.title
        case .cancelled(let plan, _): S.Subscription.cancelledHeadline.f(plan.title)
        case .billingIssue: S.Subscription.billingHeadline.s
        case .lifetime: S.Subscription.lifetimeHeadline.s
        case .expired: S.Subscription.expiredHeadline.s
        }
    }

    nonisolated var detail: String {
        let dateText = expiration.map { SubscriptionStatus.dateText($0) }
        switch self {
        case .free:
            return S.Subscription.freeDetail.s
        case .trial:
            return dateText.map { S.Subscription.trialDetail.f($0) } ?? S.Subscription.trialDetailNoDate.s
        case .active:
            return dateText.map { S.Subscription.activeDetail.f($0) } ?? S.Subscription.activeDetailNoDate.s
        case .cancelled:
            return dateText.map { S.Subscription.cancelledDetail.f($0) } ?? S.Subscription.cancelledDetailNoDate.s
        case .billingIssue:
            return S.Subscription.billingDetail.s
        case .lifetime:
            return S.Subscription.lifetimeDetail.s
        case .expired:
            return dateText.map { S.Subscription.expiredDetail.f($0) } ?? S.Subscription.expiredDetailNoDate.s
        }
    }

    nonisolated var needsAttention: Bool {
        if case .billingIssue = self { return true }
        return false
    }

    /// Renewal dates follow the reader's locale, so a US subscriber reads
    /// "September 12, 2026" where a French one reads "12 septembre 2026".
    nonisolated static func dateText(_ date: Date) -> String {
        Units.mediumDate(date)
    }
}

/// Premium features that can be gated, with their upsell copy attached.
nonisolated enum PremiumFeature: String, Sendable, Identifiable {
    case unlimitedScans
    case unlimitedAI
    case zeroEuroMode
    case endOfMonth
    case savingsStats

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .unlimitedScans: S.Subscription.featureScans.s
        case .unlimitedAI: S.Subscription.featureAI.s
        case .zeroEuroMode: S.Subscription.featureZeroCost.s
        case .endOfMonth: S.Subscription.featureBudget.s
        case .savingsStats: S.Subscription.featureStats.s
        }
    }
}

/// Single source of truth for RevenueCat: entitlement `saveat_pro`, offerings,
/// purchases, restores and the free-tier daily quotas.
@Observable
@MainActor
final class SubscriptionStore {
    /// The entitlement configured in the SAVEAT RevenueCat project.
    static let entitlementID = "saveat_pro"

    /// Free-tier limits (never blocking the core loop, only the premium extras).
    static let freeDailyScans = 8
    static let freeDailyAIRequests = 3

    private enum Keys {
        static let quotaDay = "saveat.quota.day"
        static let quotaScans = "saveat.quota.scans"
        static let quotaAI = "saveat.quota.ai"
    }

    private(set) var status: SubscriptionStatus = .free
    private(set) var customerInfo: CustomerInfo?
    private(set) var offerings: Offerings?
    private(set) var isLoadingOfferings = false
    private(set) var hasLoadedCustomerInfo = false

    var isPurchasing = false
    var isRestoring = false
    /// Only ever set by an action the user explicitly triggered (purchase, restore).
    /// Background loading problems must never land here: they would pop an alert
    /// out of nowhere — they go to `loadFailureMessage` instead.
    var errorMessage: String?
    /// Why the offerings could not be loaded, shown inline with a retry button.
    private(set) var loadFailureMessage: String?
    /// Raw technical reason the offerings call failed — diagnostics only, never shown to a buyer.
    private(set) var lastOfferingsErrorDetail: String?
    /// Result of the manual StoreKit probe (see `runStoreKitProbe`).
    private(set) var storeKitReport: String?
    private(set) var isProbingStoreKit = false
    /// Set when a purchase awaits parental approval / Ask to Buy.
    var pendingMessage: String?

    private(set) var scansUsedToday = 0
    private(set) var aiRequestsUsedToday = 0

    var isPremium: Bool { status.isPremium }

    /// Which RevenueCat store this build talks to (Test Store today).
    var environment: PurchaseEnvironment { PurchasesBootstrap.environment }

    /// False when no valid API key was found: the app must never call `Purchases.shared`.
    private var isConfigured: Bool { PurchasesBootstrap.isConfigured }

    /// Current offering from RevenueCat: the `default` offering with its
    /// `$rc_annual` and `$rc_monthly` packages.
    var currentOffering: Offering? { offerings?.current }

    /// What to tell the user when no package can be displayed.
    var unavailableReason: String {
        if let loadFailureMessage { return loadFailureMessage }
        if !isConfigured { return S.Subscription.purchasesUnavailable.s }
        if currentOffering == nil {
            return S.Subscription.offeringsUnavailable.s
        }
        return S.Subscription.offeringsNotReady.s
    }

    /// Only use RevenueCat's hosted Paywall when one is actually configured for the offering.
    var remotePaywallOffering: Offering? {
        guard let offering = currentOffering, offering.paywall != nil else { return nil }
        return offering
    }

    init() {
        let defaults = UserDefaults.standard
        let today = Self.dayKey()
        if defaults.string(forKey: Keys.quotaDay) == today {
            scansUsedToday = defaults.integer(forKey: Keys.quotaScans)
            aiRequestsUsedToday = defaults.integer(forKey: Keys.quotaAI)
        } else {
            defaults.set(today, forKey: Keys.quotaDay)
            defaults.set(0, forKey: Keys.quotaScans)
            defaults.set(0, forKey: Keys.quotaAI)
        }

        guard isConfigured else {
            PurchaseLog.error("SubscriptionStore started without a configured SDK — staying on the free tier")
            return
        }

        // Premium must survive a relaunch even offline: RevenueCat keeps the last
        // known entitlements on disk, so seed the status synchronously before any
        // network call instead of flashing the free tier.
        if let cached = Purchases.shared.cachedCustomerInfo {
            apply(cached)
            PurchaseLog.info("restored cached entitlements at launch premium=\(isPremium)")
        }

        Task { await observeCustomerInfo() }
        Task { await refreshCustomerInfo() }
        Task { await loadOfferings() }
    }

    // MARK: - Customer info

    /// Real-time entitlement updates (renewals, cancellations, billing issues, family sharing).
    private func observeCustomerInfo() async {
        for await info in Purchases.shared.customerInfoStream {
            apply(info)
        }
    }

    /// Never surfaces an alert: a slow or unreachable App Store must not interrupt
    /// the user. The last known entitlements simply stay in place.
    func refreshCustomerInfo() async {
        guard isConfigured else { return }
        do {
            let info = try await Purchases.shared.customerInfo()
            apply(info)
        } catch {
            PurchaseLog.error("customerInfo failed: \(error.localizedDescription)")
        }
        hasLoadedCustomerInfo = true
    }

    func apply(_ info: CustomerInfo) {
        customerInfo = info
        let newStatus = Self.status(from: info)
        if newStatus != status {
            PurchaseLog.info("entitlement \(Self.entitlementID) -> \(newStatus.headline) (premium=\(newStatus.isPremium))")
        }
        status = newStatus
    }

    /// Maps a `CustomerInfo` onto every subscription state the UI must handle.
    static func status(from info: CustomerInfo) -> SubscriptionStatus {
        guard let entitlement = info.entitlements[entitlementID] else { return .free }
        let plan = PremiumPlan(productIdentifier: entitlement.productIdentifier)

        guard entitlement.isActive else {
            return .expired(plan: plan, expiration: entitlement.expirationDate)
        }
        guard let expiration = entitlement.expirationDate else {
            return .lifetime
        }
        if entitlement.billingIssueDetectedAt != nil {
            return .billingIssue(plan: plan, expiration: expiration)
        }
        if entitlement.periodType == .trial {
            return .trial(plan: plan, expiration: expiration)
        }
        return entitlement.willRenew
            ? .active(plan: plan, expiration: expiration)
            : .cancelled(plan: plan, expiration: expiration)
    }

    // MARK: - Offerings

    /// Packages the `default` offering is expected to expose ($rc_annual, $rc_monthly).
    private static let expectedPackageTypes: [PackageType] = [.annual, .monthly]

    /// Loads the `default` offering. Failures are reported inline (never as an
    /// alert) and one silent retry covers a slow or briefly unavailable App Store.
    func loadOfferings(isRetry: Bool = false) async {
        guard isConfigured else {
            loadFailureMessage = "Les achats ne sont pas disponibles sur cette version."
            return
        }
        guard !isLoadingOfferings else { return }
        isLoadingOfferings = true
        defer { isLoadingOfferings = false }

        do {
            let loaded = try await Purchases.shared.offerings()
            offerings = loaded
            if let current = loaded.current {
                let summary = current.availablePackages
                    .map { "\($0.identifier)/\($0.storeProduct.productIdentifier)@\($0.storeProduct.localizedPriceString)" }
                    .joined(separator: ", ")
                PurchaseLog.info("offering '\(current.identifier)' loaded with \(current.availablePackages.count) package(s) [\(summary)] paywall=\(current.paywall != nil)")

                // Sandbox / App Store Connect misconfiguration is the usual reason a
                // package silently disappears from the offering — make it loud in the logs.
                let present = Set(current.availablePackages.map(\.packageType))
                let missing = Self.expectedPackageTypes.filter { !present.contains($0) }
                if !missing.isEmpty {
                    PurchaseLog.error("offering '\(current.identifier)' is missing \(missing.map(String.init(describing:)).joined(separator: ", ")) — check that the Apple products are attached to the packages and 'Ready to Submit' in App Store Connect")
                }

                if current.availablePackages.isEmpty {
                    loadFailureMessage = "Les abonnements ne sont pas encore disponibles depuis l'App Store. Réessaie dans quelques instants."
                    // The call succeeded, so this is an Apple-side product problem, not a
                    // network error: record it as such for the diagnostics card.
                    lastOfferingsErrorDetail = "getOfferings() a réussi mais l'offering '\(current.identifier)' expose 0 package — StoreKit n'a renvoyé aucun produit achetable (produits non 'Ready to Submit', indisponibles dans la région, ou accord payant non signé)."
                } else {
                    loadFailureMessage = nil
                    lastOfferingsErrorDetail = nil
                }
            } else {
                PurchaseLog.error("offerings loaded but no current offering is set in RevenueCat")
                loadFailureMessage = "Les abonnements ne sont pas disponibles pour le moment."
                lastOfferingsErrorDetail = "Aucun offering courant : \(loaded.all.count) offering(s) re\u{00E7}u(s), aucun marqu\u{00E9} 'Current' dans RevenueCat."
            }
        } catch {
            PurchaseLog.error("offerings failed\(isRetry ? " (retry)" : ""): \(Self.technicalDetail(for: error))")
            loadFailureMessage = Self.message(for: error)
            lastOfferingsErrorDetail = Self.technicalDetail(for: error)

            // A single quiet retry absorbs a cold start or a slow StoreKit answer.
            if !isRetry {
                isLoadingOfferings = false
                try? await Task.sleep(for: .seconds(2))
                await loadOfferings(isRetry: true)
            }
        }
    }

    /// Packages of the current offering, annual first, prices straight from the App Store.
    var packages: [Package] {
        guard let offering = currentOffering else { return [] }
        let order: [PackageType] = [.annual, .monthly, .lifetime]
        return offering.availablePackages.sorted { lhs, rhs in
            let l = order.firstIndex(of: lhs.packageType) ?? order.count
            let r = order.firstIndex(of: rhs.packageType) ?? order.count
            if l != r { return l < r }
            return lhs.storeProduct.price < rhs.storeProduct.price
        }
    }

    /// Monthly-equivalent price line for an annual package, e.g. "≈ 1,67 €/mois"
    /// in France and "≈ $1.67/month" in the US.
    ///
    /// Derived from the real App Store price of the annual product
    /// (`storeProduct.price` ÷ 12) and rendered in that product's own currency,
    /// so it always matches what Apple will actually charge.
    func monthlyEquivalent(for package: Package) -> String? {
        guard package.packageType == .annual else { return nil }
        let product = package.storeProduct
        let monthly = (product.price as NSDecimalNumber)
            .dividing(by: 12, withBehavior: NSDecimalNumberHandler(roundingMode: .plain,
                                                                   scale: 2,
                                                                   raiseOnExactness: false,
                                                                   raiseOnOverflow: false,
                                                                   raiseOnUnderflow: false,
                                                                   raiseOnDivideByZero: false))
        guard monthly.doubleValue > 0 else { return nil }
        return S.Subscription.perMonth.f(Self.storePrice(monthly.decimalValue, like: product))
    }

    /// Formats an amount in the currency of the store product it came from.
    ///
    /// SAVEAT never writes a currency into the app: the App Store decides it per
    /// country, so France sees euros and the US sees dollars. A tester signed in
    /// to a foreign storefront will legitimately see that storefront's currency —
    /// that is Apple's behaviour, not a formatting bug.
    private static func storePrice(_ amount: Decimal, like product: StoreProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatter?.locale ?? Locale.current
        if let code = product.currencyCode { formatter.currencyCode = code }
        return formatter.string(from: amount as NSDecimalNumber)
            ?? product.localizedPriceString
    }

    /// Displayed price of a package, exactly as the App Store returns it.
    func priceLabel(for package: Package) -> String {
        package.storeProduct.localizedPriceString
    }

    // MARK: - Purchases

    func purchase(_ package: Package) async {
        guard isConfigured else {
            errorMessage = S.Subscription.purchasesUnavailable.s
            return
        }
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        PurchaseLog.info("purchase started \(package.storeProduct.productIdentifier) via \(environment.label)")
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                PurchaseLog.info("purchase cancelled by user")
                return
            }
            apply(result.customerInfo)
            PurchaseLog.info("purchase finished premium=\(isPremium)")
            if isPremium { Haptics.success() }
        } catch ErrorCode.purchaseCancelledError {
            // User dismissed the StoreKit sheet — not an error.
        } catch ErrorCode.paymentPendingError {
            pendingMessage = "Ton achat est en attente de validation (Demander à acheter). Premium s'activera dès l'approbation."
        } catch {
            PurchaseLog.error("purchase failed: \(error.localizedDescription)")
            errorMessage = Self.message(for: error)
        }
    }

    func restore() async {
        guard isConfigured else {
            errorMessage = "Les achats ne sont pas disponibles sur cette version."
            return
        }
        guard !isRestoring else { return }
        isRestoring = true
        defer { isRestoring = false }

        PurchaseLog.info("restore started via \(environment.label)")
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            PurchaseLog.info("restore finished premium=\(isPremium)")
            if info.entitlements[Self.entitlementID]?.isActive != true {
                errorMessage = "Aucun abonnement actif trouvé sur ce compte Apple."
            } else {
                Haptics.success()
            }
        } catch {
            PurchaseLog.error("restore failed: \(error.localizedDescription)")
            errorMessage = Self.message(for: error)
        }
    }

    /// Fallback when the Customer Center is unavailable: Apple's native management sheet.
    func openNativeManagement() async {
        guard isConfigured else { return }
        do {
            try await Purchases.shared.showManageSubscriptions()
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    // MARK: - Diagnostics

    /// Human-readable state of the RevenueCat integration, surfaced in Test Store builds.
    var diagnostics: [(String, String)] {
        var lines: [(String, String)] = [
            ("Store", environment.label),
            ("Clé SDK", PurchasesBootstrap.redactedKey),
            ("Build", PurchasesBootstrap.buildConfigurationLabel),
            ("Entitlement", "\(Self.entitlementID) • \(isPremium ? "actif" : "inactif")"),
            ("Statut", status.headline)
        ]
        if let offering = currentOffering {
            lines.append(("Offering", offering.identifier))
            lines.append(("Plans", packages.isEmpty
                ? "aucun"
                : packages.map { planLabel($0) }.joined(separator: " • ")))
            lines.append(("Paywall distant", offering.paywall != nil ? "configuré" : "local (SAVEAT)"))
        } else {
            lines.append(("Offering", isLoadingOfferings ? "chargement…" : "indisponible"))
        }
        lines.append(("Quotas du jour", "\(scansUsedToday)/\(Self.freeDailyScans) scans • \(aiRequestsUsedToday)/\(Self.freeDailyAIRequests) IA"))
        if let userID = customerInfo?.originalAppUserId {
            lines.append(("App User ID", String(userID.suffix(12))))
        }
        if let issue = PurchasesBootstrap.configurationIssue {
            lines.append(("Configuration", issue))
        }
        return lines
    }

    /// Apple product identifiers the `default` offering must expose.
    static let expectedProductIDs = ["saveat_pro_annual", "saveat_pro_monthly"]

    /// Asks StoreKit directly for the two products, bypassing RevenueCat entirely.
    ///
    /// This is the only way to tell the two failure families apart: if StoreKit itself
    /// returns nothing for these identifiers, the problem is on the App Store Connect
    /// side (product state, availability, agreements) and no RevenueCat change can fix it.
    func runStoreKitProbe() async {
        guard !isProbingStoreKit else { return }
        isProbingStoreKit = true
        defer { isProbingStoreKit = false }

        var lines: [String] = []
        lines.append("Bundle : \(Bundle.main.bundleIdentifier ?? "inconnu")")
        lines.append("Cl\u{00E9} SDK : \(PurchasesBootstrap.redactedKey) (\(environment.label))")
        lines.append("Paiements autoris\u{00E9}s : \(StoreKit.AppStore.canMakePayments ? "oui" : "non")")
        if let storefront = await StoreKit.Storefront.current {
            lines.append("Storefront : \(storefront.countryCode)")
        } else {
            lines.append("Storefront : indisponible")
        }

        do {
            let products = try await StoreKit.Product.products(for: Self.expectedProductIDs)
            if products.isEmpty {
                lines.append("StoreKit : 0 produit renvoy\u{00E9} sur \(Self.expectedProductIDs.count) demand\u{00E9}s")
            } else {
                for product in products.sorted(by: { $0.id < $1.id }) {
                    lines.append("StoreKit OK \(product.id) \u{2014} \(product.displayPrice)")
                }
            }
            let found = Set(products.map(\.id))
            let missing = Self.expectedProductIDs.filter { !found.contains($0) }
            if !missing.isEmpty {
                lines.append("StoreKit ABSENT : \(missing.joined(separator: ", "))")
            }
        } catch {
            lines.append("StoreKit erreur : \(Self.technicalDetail(for: error))")
        }

        if let offerings {
            lines.append("RC offering courant : \(offerings.current?.identifier ?? "aucun")")
            for key in offerings.all.keys.sorted() {
                guard let offering = offerings.all[key] else { continue }
                let mapping = offering.availablePackages
                    .map { "\($0.identifier)>\($0.storeProduct.productIdentifier)" }
                    .joined(separator: ", ")
                lines.append("\u{2022} \(key) : \(mapping.isEmpty ? "aucun package" : mapping)")
            }
        } else {
            lines.append("RC offerings : non charg\u{00E9}es")
        }

        if let lastOfferingsErrorDetail {
            lines.append("Erreur RC : \(lastOfferingsErrorDetail)")
        }

        let report = lines.joined(separator: "\n")
        storeKitReport = report
        PurchaseLog.info("StoreKit probe\n\(report)")
    }

    private func planLabel(_ package: Package) -> String {
        switch package.packageType {
        case .annual: "annuel \(package.storeProduct.localizedPriceString)"
        case .monthly: "mensuel \(package.storeProduct.localizedPriceString)"
        case .lifetime: "à vie \(package.storeProduct.localizedPriceString)"
        default: "\(package.identifier) \(package.storeProduct.localizedPriceString)"
        }
    }

    // MARK: - Free quotas

    var remainingScans: Int {
        isPremium ? .max : max(Self.freeDailyScans - scansUsedToday, 0)
    }

    var remainingAIRequests: Int {
        isPremium ? .max : max(Self.freeDailyAIRequests - aiRequestsUsedToday, 0)
    }

    var canScan: Bool { isPremium || scansUsedToday < Self.freeDailyScans }
    var canAskAI: Bool { isPremium || aiRequestsUsedToday < Self.freeDailyAIRequests }

    func registerScan() {
        guard !isPremium else { return }
        rollDayIfNeeded()
        scansUsedToday += 1
        UserDefaults.standard.set(scansUsedToday, forKey: Keys.quotaScans)
    }

    func registerAIRequest() {
        guard !isPremium else { return }
        rollDayIfNeeded()
        aiRequestsUsedToday += 1
        UserDefaults.standard.set(aiRequestsUsedToday, forKey: Keys.quotaAI)
    }

    private func rollDayIfNeeded() {
        let defaults = UserDefaults.standard
        let today = Self.dayKey()
        guard defaults.string(forKey: Keys.quotaDay) != today else { return }
        defaults.set(today, forKey: Keys.quotaDay)
        scansUsedToday = 0
        aiRequestsUsedToday = 0
        defaults.set(0, forKey: Keys.quotaScans)
        defaults.set(0, forKey: Keys.quotaAI)
    }

    private static func dayKey() -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    // MARK: - Errors

    /// Full technical description of an error — diagnostics and logs only.
    static func technicalDetail(for error: Error) -> String {
        let nsError = error as NSError
        var parts: [String] = ["\(nsError.domain) #\(nsError.code)"]
        if let readable = nsError.userInfo["readable_error_code"] as? String {
            parts.append(readable)
        }
        parts.append(nsError.localizedDescription)
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            parts.append("\u{21B3} \(underlying.domain) #\(underlying.code) \(underlying.localizedDescription)")
        }
        return parts.joined(separator: " \u{2022} ")
    }

    /// User-friendly French message, never exposing SDK internals.
    private static func message(for error: Error) -> String {
        guard let code = error as? ErrorCode else {
            return "Une erreur est survenue. Réessaie dans un instant."
        }
        switch code {
        case .networkError, .offlineConnectionError:
            return "Connexion indisponible. Vérifie ton réseau et réessaie."
        case .storeProblemError:
            return "L'App Store est momentanément indisponible. Réessaie plus tard."
        case .productNotAvailableForPurchaseError, .productAlreadyPurchasedError:
            return "Cette offre n'est pas disponible sur ton compte pour le moment."
        case .purchaseNotAllowedError:
            return "Les achats sont désactivés sur cet appareil (restrictions parentales)."
        case .receiptAlreadyInUseError:
            return "Cet achat est déjà lié à un autre compte."
        case .paymentPendingError:
            return "Achat en attente de validation."
        case .configurationError, .unexpectedBackendResponseError:
            return "Les abonnements ne sont pas encore disponibles. Réessaie dans quelques instants."
        case .unknownBackendError, .invalidAppUserIdError:
            return "Service d'abonnement momentanément indisponible. Réessaie plus tard."
        default:
            return "Une erreur est survenue. Réessaie dans un instant."
        }
    }
}
