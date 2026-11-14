import XCTest
@testable import HeurikaCore

final class AIDataConsentTests: XCTestCase {
    private func freshDefaults() -> SharedDefaults {
        let suite = UserDefaults(suiteName: "test.consent.\(UUID().uuidString)")!
        return SharedDefaults(defaults: suite)
    }

    func testConsentIsProviderSpecific() {
        let defaults = freshDefaults()
        defaults.grantAIDataConsent(for: .groq, at: Date(timeIntervalSince1970: 100))

        XCTAssertTrue(defaults.hasCurrentAIDataConsent(for: .groq))
        XCTAssertFalse(defaults.hasCurrentAIDataConsent(for: .openAI))
        XCTAssertFalse(defaults.hasCurrentAIDataConsent(for: .anthropic))
    }

    func testConsentCanBeWithdrawn() {
        let defaults = freshDefaults()
        defaults.grantAIDataConsent(for: .openAI)
        defaults.revokeAIDataConsent(for: .openAI)
        XCTAssertFalse(defaults.hasCurrentAIDataConsent(for: .openAI))
    }

    func testOldPolicyVersionIsNotCurrentConsent() {
        let defaults = freshDefaults()
        defaults.aiDataConsentRecords = [
            AIProviderType.groq.rawValue: AIDataConsentRecord(
                provider: .groq,
                policyVersion: AIConsentPolicy.currentVersion - 1,
                acceptedAt: Date()
            )
        ]
        XCTAssertFalse(defaults.hasCurrentAIDataConsent(for: .groq))
    }
}
