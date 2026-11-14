import Foundation

/// Versioned consent for sending user-selected text to a named AI provider.
/// Consent is stored per provider because switching providers changes the
/// third party that receives the text.
public struct AIDataConsentRecord: Codable, Equatable, Sendable {
    public let provider: AIProviderType
    public let policyVersion: Int
    public let acceptedAt: Date

    public init(provider: AIProviderType, policyVersion: Int, acceptedAt: Date) {
        self.provider = provider
        self.policyVersion = policyVersion
        self.acceptedAt = acceptedAt
    }
}

public enum AIConsentPolicy {
    /// Increment when the disclosed data flow or provider use materially changes.
    public static let currentVersion = 1
}
