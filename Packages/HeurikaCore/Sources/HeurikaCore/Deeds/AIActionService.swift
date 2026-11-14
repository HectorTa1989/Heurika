import Foundation

/// The single entry point for running a `.rewrite` Deed. Everything
/// provider-agnostic (gating, key lookup, prompt building, usage counting)
/// lives here so `KeyboardViewController` never has to know which provider
/// is active or what the free-plan rules are.
public final class AIActionService: Sendable {
    public init() {}

    public func runRewrite(deed: Deed, inputText: String) async throws -> String {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIActionError.emptyContext
        }

        let settings = SharedDefaults.shared.providerSettings
        let status = SharedDefaults.shared.subscriptionStatus
        let isPro = status.effectiveIsPro

        try enforceGating(deed: deed, provider: settings.selectedProvider, isPro: isPro)

        guard SharedDefaults.shared.hasCurrentAIDataConsent(for: settings.selectedProvider) else {
            throw AIActionError.aiDataConsentRequired(provider: settings.selectedProvider)
        }

        guard let apiKey = KeychainStore.shared.apiKey(for: settings.selectedProvider) else {
            throw AIActionError.noAPIKey(provider: settings.selectedProvider)
        }

        let client = makeClient(provider: settings.selectedProvider, apiKey: apiKey)
        let (system, user) = PromptBuilder.build(for: deed, input: inputText, translateLanguage: settings.translateTargetLanguage)
        let request = AICompletionRequest(system: system, user: user, model: settings.modelForSelectedProvider)

        let output = try await client.complete(request)

        if !isPro {
            UsageTracker.shared.recordUsage()
        }
        return output
    }

    /// Runs the Notion Search Deed specifically — separate from `runRewrite`
    /// because it hits Notion's API rather than an LLM provider, but shares
    /// the same gating/usage accounting.
    public func runNotionSearch(query: String) async throws -> NotionClient.Result {
        let status = SharedDefaults.shared.subscriptionStatus
        guard status.effectiveIsPro else {
            throw AIActionError.proRequiredForCustomDeed
        }
        guard let token = KeychainStore.shared.notionToken() else {
            throw AIActionError.notionNotConfigured
        }
        return try await NotionClient(token: token).search(query: query)
    }

    private func enforceGating(deed: Deed, provider: AIProviderType, isPro: Bool) throws {
        if !isPro {
            if provider.requiresPro {
                throw AIActionError.proRequiredForProvider(provider: provider)
            }
            if !deed.isBuiltIn {
                throw AIActionError.proRequiredForCustomDeed
            }
            guard UsageTracker.shared.remainingFreeActionsToday() > 0 else {
                throw AIActionError.dailyLimitReached
            }
        }
    }

    private func makeClient(provider: AIProviderType, apiKey: String) -> AIProviderClient {
        switch provider {
        case .groq: return GroqClient(apiKey: apiKey)
        case .openAI: return OpenAIClient(apiKey: apiKey)
        case .anthropic: return AnthropicClient(apiKey: apiKey)
        }
    }
}
