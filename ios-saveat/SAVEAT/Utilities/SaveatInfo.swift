import Foundation

/// Legal and support destinations required by App Store review, plus the real
/// bundle version, so every screen points at the same canonical values.
nonisolated enum SaveatInfo {
    static let termsURL = URL(string: "https://saveat-antigaspi.fr/conditions-utilisation")!
    static let privacyURL = URL(string: "https://saveat-antigaspi.fr/confidentialite")!
    static let supportURL = URL(string: "https://saveat-antigaspi.fr/support")!

    /// Marketing version and build number read from the bundle, e.g. "1.0.0 (4)".
    static var versionText: String {
        let marketing = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        switch (marketing, build) {
        case let (version?, build?): return "\(version) (\(build))"
        case let (version?, nil): return version
        default: return "—"
        }
    }
}
