import Foundation

/// Diagnostic logging for calls to the Rork Toolkit AI gateway — mirrors
/// `PurchaseLog`'s shape for RevenueCat (`PurchasesBootstrap.swift`).
/// Debug-only console output; never logs the secret key itself, only
/// whether one was detected.
nonisolated enum MealAILog {
    static func info(_ message: String) {
        #if DEBUG
        print("[SAVEAT/AI] \(message)")
        #endif
    }

    static func error(_ message: String) {
        #if DEBUG
        print("[SAVEAT/AI] ERROR \(message)")
        #endif
    }
}
