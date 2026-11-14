import XCTest
@testable import HeurikaCore

/// These tests exercise `AIActionService`'s gating rules only — never a real
/// network call. `AIActionService` intentionally talks to the real
/// `SharedDefaults.shared` / `UsageTracker.shared` singletons (that's the
/// point: it's the same code path production uses), so each test saves and
/// restores that shared state rather than running against an injected
/// double. That's a deliberate, documented trade-off for a service this
/// small — not an oversight.
final class AIActionServiceGatingTests: XCTestCase {

    private var savedSettings: ProviderSettings!
    private var savedStatus: SubscriptionStatus!
    private var savedConsentRecords: [String: AIDataConsentRecord]!

    override func setUp() {
        super.setUp()
        savedSettings = SharedDefaults.shared.providerSettings
        savedStatus = SharedDefaults.shared.subscriptionStatus
        savedConsentRecords = SharedDefaults.shared.aiDataConsentRecords
        for provider in AIProviderType.allCases {
            SharedDefaults.shared.grantAIDataConsent(for: provider)
        }
        UsageTracker.shared.reset()
    }

    override func tearDown() {
        SharedDefaults.shared.providerSettings = savedSettings
        SharedDefaults.shared.subscriptionStatus = savedStatus
        SharedDefaults.shared.aiDataConsentRecords = savedConsentRecords
        UsageTracker.shared.reset()
        super.tearDown()
    }

    private func setFree(provider: AIProviderType = .groq) {
        SharedDefaults.shared.subscriptionStatus = SubscriptionStatus(isPro: false, expiresAt: nil, lastSyncedAt: Date())
        var settings = SharedDefaults.shared.providerSettings
        settings.selectedProvider = provider
        SharedDefaults.shared.providerSettings = settings
    }

    private func setPro() {
        SharedDefaults.shared.subscriptionStatus = SubscriptionStatus(isPro: true, expiresAt: Date().addingTimeInterval(3600), lastSyncedAt: Date())
    }

    func testEmptyInputThrowsBeforeTouchingAnyGatingState() async {
        let service = AIActionService()
        let deed = BuiltInDeeds.rewrites[0]
        do {
            _ = try await service.runRewrite(deed: deed, inputText: "   ")
            XCTFail("expected emptyContext")
        } catch let error as AIActionError {
            XCTAssertEqual(error, .emptyContext)
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }

    func testFreePlanWithNonGroqProviderRequiresPro() async {
        setFree(provider: .openAI)
        let service = AIActionService()
        let deed = BuiltInDeeds.rewrites[0]
        do {
            _ = try await service.runRewrite(deed: deed, inputText: "hello")
            XCTFail("expected proRequiredForProvider")
        } catch let error as AIActionError {
            XCTAssertEqual(error, .proRequiredForProvider(provider: .openAI))
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }

    func testFreePlanWithCustomDeedRequiresPro() async {
        setFree(provider: .groq)
        let service = AIActionService()
        let customDeed = Deed(name: "Custom", symbol: "star", kind: .rewrite, instruction: "Be terse.", isBuiltIn: false)
        do {
            _ = try await service.runRewrite(deed: customDeed, inputText: "hello")
            XCTFail("expected proRequiredForCustomDeed")
        } catch let error as AIActionError {
            XCTAssertEqual(error, .proRequiredForCustomDeed)
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }

    func testFreePlanWithExhaustedDailyLimitBlocks() async {
        setFree(provider: .groq)
        for _ in 0..<HeurikaConstants.freeDailyDeedLimit {
            UsageTracker.shared.recordUsage()
        }
        let service = AIActionService()
        let deed = BuiltInDeeds.rewrites[0]
        do {
            _ = try await service.runRewrite(deed: deed, inputText: "hello")
            XCTFail("expected dailyLimitReached")
        } catch let error as AIActionError {
            XCTAssertEqual(error, .dailyLimitReached)
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }

    func testFreePlanBuiltInDeedWithQuotaPassesGatingAndFailsOnMissingKey() async {
        // No real key exists in this test environment, so a successful pass
        // through gating should land on .noAPIKey — proving gating allowed it
        // through, without needing a real network call to prove it further.
        setFree(provider: .groq)
        KeychainStore.shared.setAPIKey(nil, for: .groq)
        let service = AIActionService()
        let deed = BuiltInDeeds.rewrites[0]
        do {
            _ = try await service.runRewrite(deed: deed, inputText: "hello")
            XCTFail("expected noAPIKey since no key is configured in the test environment")
        } catch let error as AIActionError {
            XCTAssertEqual(error, .noAPIKey(provider: .groq))
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }

    func testConfiguredProviderRequiresCurrentDataConsentBeforeKeyLookup() async {
        setFree(provider: .groq)
        SharedDefaults.shared.revokeAIDataConsent(for: .groq)
        KeychainStore.shared.setAPIKey(nil, for: .groq)

        do {
            _ = try await AIActionService().runRewrite(deed: BuiltInDeeds.polish, inputText: "hello")
            XCTFail("expected aiDataConsentRequired")
        } catch let error as AIActionError {
            XCTAssertEqual(error, .aiDataConsentRequired(provider: .groq))
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }

    func testProPlanSkipsFreeGatingAndFailsOnMissingKeyInstead() async {
        setPro()
        var settings = SharedDefaults.shared.providerSettings
        settings.selectedProvider = .anthropic
        SharedDefaults.shared.providerSettings = settings
        KeychainStore.shared.setAPIKey(nil, for: .anthropic)

        let service = AIActionService()
        let customDeed = Deed(name: "Custom", symbol: "star", kind: .rewrite, instruction: "Be terse.", isBuiltIn: false)
        do {
            _ = try await service.runRewrite(deed: customDeed, inputText: "hello")
            XCTFail("expected noAPIKey — Pro should bypass provider/custom-deed/quota gating entirely")
        } catch let error as AIActionError {
            XCTAssertEqual(error, .noAPIKey(provider: .anthropic))
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }
}
