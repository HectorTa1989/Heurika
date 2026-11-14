import Foundation

/// Values supplied by build settings and surfaced through Info.plist. Keeping
/// them out of source prevents shipping fake links or a template purchase key.
enum AppConfiguration {
    private enum InfoKey {
        static let revenueCatAPIKey = "HeurikaRevenueCatAPIKey"
        static let privacyPolicyURL = "HeurikaPrivacyPolicyURL"
        static let termsOfUseURL = "HeurikaTermsOfUseURL"
        static let supportURL = "HeurikaSupportURL"
    }

    static var revenueCatAPIKey: String? { configuredString(InfoKey.revenueCatAPIKey) }
    static var privacyPolicyURL: URL? { configuredURL(InfoKey.privacyPolicyURL) }
    static var termsOfUseURL: URL? { configuredURL(InfoKey.termsOfUseURL) }
    static var supportURL: URL? { configuredURL(InfoKey.supportURL) }

    static var missingLaunchValues: [String] {
        var missing: [String] = []
        if revenueCatAPIKey == nil { missing.append("RevenueCat public SDK key") }
        if privacyPolicyURL == nil { missing.append("Privacy Policy URL") }
        if termsOfUseURL == nil { missing.append("Terms of Use URL") }
        if supportURL == nil { missing.append("Support URL") }
        return missing
    }

    private static func configuredString(_ key: String) -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              !value.contains("$("),
              !value.contains("YOUR_") else { return nil }
        return value
    }

    private static func configuredURL(_ key: String) -> URL? {
        guard let value = configuredString(key),
              let url = URL(string: value),
              url.scheme?.lowercased() == "https",
              url.host != nil else { return nil }
        return url
    }
}
