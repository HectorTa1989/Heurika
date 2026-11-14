import Foundation

public enum AIActionError: Error, Equatable, Sendable {
    case noFullAccess
    case emptyContext
    case noAPIKey(provider: AIProviderType)
    case aiDataConsentRequired(provider: AIProviderType)
    case proRequiredForProvider(provider: AIProviderType)
    case proRequiredForCustomDeed
    case dailyLimitReached
    case network(String)
    case invalidResponse
    case server(status: Int, message: String)
    case notionNotConfigured
    case notionNoResults

    /// Short, calm, non-technical copy for the keyboard's tiny status strip.
    /// Never blames the person, never shows raw error text from a server.
    public var friendlyMessage: String {
        switch self {
        case .noFullAccess:
            return "Turn on Full Access in Settings to use Deeds"
        case .emptyContext:
            return "Type something first"
        case .noAPIKey(let provider):
            return "Add a \(provider.displayName) key in Heurika settings"
        case .aiDataConsentRequired(let provider):
            return "Review \(provider.displayName) AI privacy in Heurika settings"
        case .proRequiredForProvider(let provider):
            return "\(provider.displayName) needs Heurika Pro"
        case .proRequiredForCustomDeed:
            return "Custom Deeds need Heurika Pro"
        case .dailyLimitReached:
            return "Today's free Deeds are used up — upgrade for unlimited"
        case .network:
            return "No connection right now"
        case .invalidResponse:
            return "That didn't come back right — try again"
        case .server(_, let message):
            return message.isEmpty ? "Something went wrong — try again" : message
        case .notionNotConfigured:
            return "Add a Notion token in Heurika settings"
        case .notionNoResults:
            return "No matching Notion pages found"
        }
    }
}
