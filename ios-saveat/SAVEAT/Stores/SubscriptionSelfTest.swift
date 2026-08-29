import Foundation
import RevenueCat

/// End-to-end verification of the RevenueCat **Test Store** chain:
/// offerings → purchase → `saveat_pro` entitlement → premium unlock → restore.
///
/// It never runs against the App Store, and it runs on a throwaway app user id so
/// the real (anonymous) user is left exactly as it was: free tier, quotas intact.
/// Every step prints `[SAVEAT/RC] selftest …` so the whole run is traceable in the
/// runtime logs.
@MainActor
enum SubscriptionSelfTest {
    /// Manual only. This self-test opens its OWN Test Store purchase sheet, so it must
    /// never run automatically: it would intercept the sheet the user meant for the
    /// paywall, and its clean-up would then send the app back to the free tier.
    static var canRun: Bool { PurchasesBootstrap.environment.isTestStore }

    /// Runs the full chain and reports each step as PASS / FAIL, returning a summary.
    @discardableResult
    static func run(store: SubscriptionStore) async -> String {
        guard canRun else { return "Auto-test disponible uniquement en Test Store." }
        guard !store.isPremium else {
            return "Premium déjà actif : teste directement dans l'app (l'auto-test repartirait de zéro)."
        }

        var failures: [String] = []
        let testUserID = "saveat-selftest-\(UUID().uuidString.prefix(8))"
        PurchaseLog.info("selftest ▶ start on isolated user \(testUserID)")

        // Step 0 — isolate the run from the real user.
        do {
            let result = try await Purchases.shared.logIn(testUserID)
            PurchaseLog.info("selftest 0/5 PASS isolated user created=\(result.created)")
        } catch {
            PurchaseLog.error("selftest 0/5 FAIL logIn: \(error.localizedDescription)")
            PurchaseLog.error("selftest ■ aborted")
            return "Échec : connexion à l'utilisateur de test."
        }

        // Step 1 — offerings and packages.
        var purchasable: Package?
        do {
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                let ids = current.availablePackages.map(\.identifier).joined(separator: ", ")
                PurchaseLog.info("selftest 1/5 PASS offering '\(current.identifier)' packages=[\(ids)]")
                purchasable = current.availablePackages.first { $0.packageType == .annual }
                    ?? current.availablePackages.first
            } else {
                failures.append("aucune offering courante")
                PurchaseLog.error("selftest 1/5 FAIL no current offering")
            }
        } catch {
            failures.append("offerings: \(error.localizedDescription)")
            PurchaseLog.error("selftest 1/5 FAIL offerings: \(error.localizedDescription)")
        }

        // Step 2 — purchase + entitlement activation.
        var didPurchase = false
        if let package = purchasable {
            PurchaseLog.info("selftest 2/5 purchasing \(package.identifier) / \(package.storeProduct.productIdentifier)")
            do {
                let result = try await Purchases.shared.purchase(package: package)
                let entitlement = result.customerInfo.entitlements[SubscriptionStore.entitlementID]
                if result.userCancelled {
                    failures.append("achat annulé")
                    PurchaseLog.error("selftest 2/5 FAIL purchase reported as cancelled")
                } else if entitlement?.isActive == true {
                    didPurchase = true
                    let store = entitlement?.store.rawValue ?? -1
                    let period = entitlement?.periodType == .trial ? "trial" : "normal"
                    PurchaseLog.info("selftest 2/5 PASS \(SubscriptionStore.entitlementID) active product=\(entitlement?.productIdentifier ?? "?") period=\(period) store=\(store) expires=\(entitlement?.expirationDate.map(Self.iso) ?? "jamais")")
                } else {
                    failures.append("entitlement \(SubscriptionStore.entitlementID) inactif après achat")
                    PurchaseLog.error("selftest 2/5 FAIL purchase succeeded but entitlement is inactive — check the product→entitlement mapping in RevenueCat")
                }
            } catch {
                failures.append("achat: \(error.localizedDescription)")
                PurchaseLog.error("selftest 2/5 FAIL purchase: \(error.localizedDescription)")
            }
        } else {
            failures.append("aucun package achetable")
            PurchaseLog.error("selftest 2/5 SKIP no purchasable package")
        }

        // Step 3 — the app-facing store must unlock premium (status + quotas).
        if didPurchase {
            await store.refreshCustomerInfo()
            let unlockedScans = store.canScan && store.remainingScans == .max
            let unlockedAI = store.canAskAI && store.remainingAIRequests == .max
            if store.isPremium, unlockedScans, unlockedAI {
                PurchaseLog.info("selftest 3/5 PASS premium unlocked status='\(store.status.headline)' scans=illimités ia=illimitée")
            } else {
                failures.append("déblocage premium incomplet")
                PurchaseLog.error("selftest 3/5 FAIL premium=\(store.isPremium) status='\(store.status.headline)' scansUnlocked=\(unlockedScans) aiUnlocked=\(unlockedAI)")
            }
        } else {
            PurchaseLog.error("selftest 3/5 SKIP no purchase to verify")
        }

        // Step 4 — restore from a cold cache, as a reinstall would.
        if didPurchase {
            Purchases.shared.invalidateCustomerInfoCache()
            do {
                let info = try await Purchases.shared.restorePurchases()
                if info.entitlements[SubscriptionStore.entitlementID]?.isActive == true {
                    PurchaseLog.info("selftest 4/5 PASS restore returned an active \(SubscriptionStore.entitlementID)")
                } else {
                    failures.append("restauration sans entitlement actif")
                    PurchaseLog.error("selftest 4/5 FAIL restore returned no active entitlement")
                }
            } catch {
                failures.append("restauration: \(error.localizedDescription)")
                PurchaseLog.error("selftest 4/5 FAIL restore: \(error.localizedDescription)")
            }
        } else {
            PurchaseLog.error("selftest 4/5 SKIP no purchase to restore")
        }

        // Step 5 — clean-up: back to a fresh anonymous user, free tier.
        do {
            let info = try await Purchases.shared.logOut()
            store.apply(info)
            let stillPremium = info.entitlements[SubscriptionStore.entitlementID]?.isActive == true
            if stillPremium {
                failures.append("nettoyage: l'utilisateur reste premium")
                PurchaseLog.error("selftest 5/5 FAIL test purchase leaked to the real user")
            } else {
                PurchaseLog.info("selftest 5/5 PASS back to anonymous free user premium=\(store.isPremium)")
            }
        } catch {
            failures.append("nettoyage: \(error.localizedDescription)")
            PurchaseLog.error("selftest 5/5 FAIL logOut: \(error.localizedDescription)")
        }

        await store.loadOfferings()

        if failures.isEmpty {
            PurchaseLog.info("selftest ■ RESULT ALL PASS — Test Store chain verified")
            return "Tout est OK : achat → saveat_pro → premium → restauration."
        }
        PurchaseLog.error("selftest ■ RESULT \(failures.count) FAILURE(S): \(failures.joined(separator: " | "))")
        return "\(failures.count) échec(s) : \(failures.joined(separator: " | "))"
    }

    private static func iso(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
