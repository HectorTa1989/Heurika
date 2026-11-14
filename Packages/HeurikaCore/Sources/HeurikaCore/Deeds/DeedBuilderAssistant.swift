import Foundation

/// Powers the Deed Builder's "Draft with AI" button: the person describes a
/// rewrite Deed in plain English, and this turns it into a structured draft
/// (name, SF Symbol suggestion, instruction) for them to review and edit
/// before saving. Deliberately scoped to rewrite Deeds only — an "act" Deed
/// is just a name + URL template, simple enough to fill in directly without
/// an AI round trip, and Heurika doesn't claim to wire up arbitrary new API
/// integrations from a text description. See README → "What the Deed
/// Builder can and can't do".
public struct DeedDraft: Codable, Equatable, Sendable {
    public var name: String
    public var symbol: String
    public var instruction: String
}

public final class DeedBuilderAssistant: Sendable {
    public init() {}

    public func draft(from description: String) async throws -> DeedDraft {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIActionError.emptyContext
        }

        let settings = SharedDefaults.shared.providerSettings
        let status = SharedDefaults.shared.subscriptionStatus
        guard status.effectiveIsPro else {
            throw AIActionError.proRequiredForCustomDeed
        }
        guard SharedDefaults.shared.hasCurrentAIDataConsent(for: settings.selectedProvider) else {
            throw AIActionError.aiDataConsentRequired(provider: settings.selectedProvider)
        }
        guard let apiKey = KeychainStore.shared.apiKey(for: settings.selectedProvider) else {
            throw AIActionError.noAPIKey(provider: settings.selectedProvider)
        }

        let system = """
        You turn a person's plain-English description of a text-rewriting shortcut
        into a structured definition. Respond with strict JSON only:
        { "name": short 2-4 word title, "symbol": a single valid SF Symbols name
        that visually matches the idea, "instruction": one or two sentences telling
        an LLM exactly how to rewrite text for this Deed. }
        The instruction must describe a TEXT REWRITE only — never an action, lookup,
        or integration; those are configured separately, not drafted by you.
        """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "symbol": ["type": "string"],
                "instruction": ["type": "string"]
            ],
            "required": ["name", "symbol", "instruction"],
            "additionalProperties": false
        ]

        let client = clientFor(provider: settings.selectedProvider, apiKey: apiKey)
        let request = AICompletionRequest(
            system: system,
            user: description,
            model: settings.modelForSelectedProvider,
            jsonSchema: schema,
            maxOutputTokens: 250
        )
        let raw = try await client.complete(request)

        guard let data = raw.data(using: .utf8),
              var parsed = try? JSONDecoder().decode(DeedDraft.self, from: data) else {
            throw AIActionError.invalidResponse
        }

        // A hallucinated or missing SF Symbol name would otherwise render as a
        // blank glyph; falling back to a safe default keeps the draft usable.
        if parsed.symbol.trimmingCharacters(in: .whitespaces).isEmpty {
            parsed.symbol = "sparkles"
        }
        return parsed
    }

    private func clientFor(provider: AIProviderType, apiKey: String) -> AIProviderClient {
        switch provider {
        case .groq: return GroqClient(apiKey: apiKey)
        case .openAI: return OpenAIClient(apiKey: apiKey)
        case .anthropic: return AnthropicClient(apiKey: apiKey)
        }
    }
}
