import Foundation

/// Non-secret, shared state: provider selection/model, translate language,
/// and the last-synced subscription snapshot. Backed by the App Group suite
/// so reads inside the keyboard extension are synchronous and local — no
/// network call needed just to check "is this person Pro".
public final class SharedDefaults: @unchecked Sendable {
    public static let shared = SharedDefaults()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let providerSettings = "heurika.providerSettings.v1"
        static let subscriptionStatus = "heurika.subscriptionStatus.v1"
        static let hasCompletedOnboarding = "heurika.hasCompletedOnboarding.v1"
        static let keyboardHasBeenActivated = "heurika.keyboardHasBeenActivated.v1"
        static let aiDataConsentRecords = "heurika.aiDataConsentRecords.v1"
    }

    /// `defaults` is injectable so unit tests can pass an isolated suite
    /// instead of touching the real App Group container; production code
    /// always goes through `SharedDefaults.shared`, which resolves the real
    /// App Group.
    init(defaults: UserDefaults? = nil) {
        if let defaults {
            self.defaults = defaults
            return
        }
        guard let suite = UserDefaults(suiteName: HeurikaConstants.appGroupID) else {
            // Falling back to .standard keeps the app usable (rather than
            // crashing) if the App Group entitlement is ever missing, e.g.
            // during local development before capabilities are wired up —
            // but the extension and app would then see different values, so
            // this is flagged loudly rather than silently "working".
            assertionFailure("App Group '\(HeurikaConstants.appGroupID)' is not available — check entitlements.")
            self.defaults = .standard
            return
        }
        self.defaults = suite
    }

    // MARK: - Provider settings

    public var providerSettings: ProviderSettings {
        get { decode(Key.providerSettings) ?? .default }
        set { encode(newValue, forKey: Key.providerSettings) }
    }

    // MARK: - Subscription status

    public var subscriptionStatus: SubscriptionStatus {
        get { decode(Key.subscriptionStatus) ?? .freeDefault }
        set { encode(newValue, forKey: Key.subscriptionStatus) }
    }

    // MARK: - Onboarding

    public var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Key.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Key.hasCompletedOnboarding) }
    }

    /// iOS has no public API for "is my custom keyboard currently enabled" —
    /// this is the standard workaround: the extension sets this the first
    /// time it actually loads, so the app can show real status instead of
    /// guessing. `false` just means "not seen yet", not "definitely off".
    public var keyboardHasBeenActivated: Bool {
        get { defaults.bool(forKey: Key.keyboardHasBeenActivated) }
        set { defaults.set(newValue, forKey: Key.keyboardHasBeenActivated) }
    }

    // MARK: - Third-party AI consent

    public var aiDataConsentRecords: [String: AIDataConsentRecord] {
        get { decode(Key.aiDataConsentRecords) ?? [:] }
        set { encode(newValue, forKey: Key.aiDataConsentRecords) }
    }

    public func hasCurrentAIDataConsent(for provider: AIProviderType) -> Bool {
        guard let record = aiDataConsentRecords[provider.rawValue] else { return false }
        return record.provider == provider && record.policyVersion == AIConsentPolicy.currentVersion
    }

    public func grantAIDataConsent(for provider: AIProviderType, at date: Date = Date()) {
        var records = aiDataConsentRecords
        records[provider.rawValue] = AIDataConsentRecord(
            provider: provider,
            policyVersion: AIConsentPolicy.currentVersion,
            acceptedAt: date
        )
        aiDataConsentRecords = records
    }

    public func revokeAIDataConsent(for provider: AIProviderType) {
        var records = aiDataConsentRecords
        records.removeValue(forKey: provider.rawValue)
        aiDataConsentRecords = records
    }

    public func revokeAllAIDataConsent() {
        aiDataConsentRecords = [:]
    }

    // MARK: - Generic helpers

    private func decode<T: Decodable>(_ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
