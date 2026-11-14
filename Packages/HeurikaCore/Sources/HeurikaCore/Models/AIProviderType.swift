import Foundation

/// The three supported LLM providers. All three are bring-your-own-key —
/// Heurika never ships a shared embedded API key. A key baked into a client
/// binary is extractable and gets abused, and free-tier usage should not
/// depend on infrastructure this project doesn't operate. See README
/// "Why BYOK" for the full reasoning.
public enum AIProviderType: String, Codable, CaseIterable, Identifiable, Equatable, Hashable, Sendable {
    case groq
    case openAI
    case anthropic

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .groq: return "Groq"
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        }
    }

    public var subtitle: String {
        switch self {
        case .groq: return "Free tier available · default"
        case .openAI: return "Bring your own key · Pro"
        case .anthropic: return "Bring your own key · Pro"
        }
    }

    /// Only Groq is available on the free plan. OpenAI / Anthropic require Pro.
    public var requiresPro: Bool {
        switch self {
        case .groq: return false
        case .openAI, .anthropic: return true
        }
    }

    public var defaultModel: String {
        switch self {
        // Groq deprecated llama-3.3-70b-versatile / llama-3.1-8b-instant in June 2026.
        // gpt-oss-20b is the current recommended fast default; keep this
        // configurable in Settings since hosted model lineups change often.
        case .groq: return "openai/gpt-oss-20b"
        case .openAI: return "gpt-4.1-mini"
        case .anthropic: return "claude-haiku-4-5-20251001"
        }
    }

    public var consoleURL: URL {
        switch self {
        case .groq: return URL(string: "https://console.groq.com/keys")!
        case .openAI: return URL(string: "https://platform.openai.com/api-keys")!
        case .anthropic: return URL(string: "https://console.anthropic.com/settings/keys")!
        }
    }
}

/// Everything the person has configured about how Deeds should be run.
/// Lives in the shared App Group so both the app and the keyboard extension
/// see the same settings without a network round trip.
public struct ProviderSettings: Codable, Equatable, Sendable {
    public var selectedProvider: AIProviderType
    public var groqModel: String
    public var openAIModel: String
    public var anthropicModel: String
    public var translateTargetLanguage: String
    public var notionIntegrationTokenSet: Bool

    public static let `default` = ProviderSettings(
        selectedProvider: .groq,
        groqModel: AIProviderType.groq.defaultModel,
        openAIModel: AIProviderType.openAI.defaultModel,
        anthropicModel: AIProviderType.anthropic.defaultModel,
        translateTargetLanguage: "Spanish",
        notionIntegrationTokenSet: false
    )

    public init(
        selectedProvider: AIProviderType,
        groqModel: String,
        openAIModel: String,
        anthropicModel: String,
        translateTargetLanguage: String,
        notionIntegrationTokenSet: Bool
    ) {
        self.selectedProvider = selectedProvider
        self.groqModel = groqModel
        self.openAIModel = openAIModel
        self.anthropicModel = anthropicModel
        self.translateTargetLanguage = translateTargetLanguage
        self.notionIntegrationTokenSet = notionIntegrationTokenSet
    }

    public var modelForSelectedProvider: String {
        switch selectedProvider {
        case .groq: return groqModel
        case .openAI: return openAIModel
        case .anthropic: return anthropicModel
        }
    }

    public static let commonTranslateLanguages = [
        "Spanish", "French", "German", "Portuguese", "Vietnamese",
        "Japanese", "Korean", "Mandarin Chinese", "Italian", "Hindi", "Arabic"
    ]
}
