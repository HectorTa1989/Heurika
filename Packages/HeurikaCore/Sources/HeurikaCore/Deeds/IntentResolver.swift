import Foundation

/// Powers the Heurika Bar: the person types free text and holds the bar, and
/// this decides whether they meant "rewrite what I typed" or "go do this
/// specific thing" — routing to a real Deed either way. See `PromptBuilder`
/// for the system prompt and `IntentResolution` for the honesty constraint
/// (never fabricate live data; fall back to `.unclear` rather than guess).
public final class IntentResolver: Sendable {
    private let actionService: AIActionService

    public init(actionService: AIActionService = AIActionService()) {
        self.actionService = actionService
    }

    public func resolve(typedText: String) async throws -> IntentResolution {
        guard !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIActionError.emptyContext
        }

        let settings = SharedDefaults.shared.providerSettings
        let status = SharedDefaults.shared.subscriptionStatus
        let isPro = status.effectiveIsPro

        if !isPro {
            guard settings.selectedProvider == .groq else {
                throw AIActionError.proRequiredForProvider(provider: settings.selectedProvider)
            }
            guard UsageTracker.shared.remainingFreeActionsToday() > 0 else {
                throw AIActionError.dailyLimitReached
            }
        }

        guard SharedDefaults.shared.hasCurrentAIDataConsent(for: settings.selectedProvider) else {
            throw AIActionError.aiDataConsentRequired(provider: settings.selectedProvider)
        }

        guard let apiKey = KeychainStore.shared.apiKey(for: settings.selectedProvider) else {
            throw AIActionError.noAPIKey(provider: settings.selectedProvider)
        }

        let catalog = DeedsRepository.shared.allIncludingBuiltIns()
        let (system, user) = PromptBuilder.buildIntentResolution(typedText: typedText, catalog: catalog)

        let client = clientFor(provider: settings.selectedProvider, apiKey: apiKey)
        let request = AICompletionRequest(
            system: system,
            user: user,
            model: settings.modelForSelectedProvider,
            jsonSchema: IntentResolution.jsonSchema,
            maxOutputTokens: 300
        )

        let raw = try await client.complete(request)

        if !isPro {
            UsageTracker.shared.recordUsage()
        }

        guard let data = raw.data(using: .utf8),
              let resolution = try? JSONDecoder().decode(IntentResolution.self, from: data) else {
            // A malformed structured-output response degrades to "unclear"
            // rather than crashing the keyboard or silently doing nothing.
            return IntentResolution(resolution: .unclear, deedID: nil, query: nil, reasoning: nil)
        }
        return resolution
    }

    private func clientFor(provider: AIProviderType, apiKey: String) -> AIProviderClient {
        switch provider {
        case .groq: return GroqClient(apiKey: apiKey)
        case .openAI: return OpenAIClient(apiKey: apiKey)
        case .anthropic: return AnthropicClient(apiKey: apiKey)
        }
    }
}
