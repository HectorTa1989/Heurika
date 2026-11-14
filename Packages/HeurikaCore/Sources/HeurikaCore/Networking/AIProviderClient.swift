import Foundation

/// A single request to an LLM: a system instruction plus the user's input.
/// Kept intentionally tiny — Heurika never needs multi-turn chat history,
/// every Deed run is a fresh, isolated call.
public struct AICompletionRequest: Sendable {
    public var system: String
    public var user: String
    public var model: String
    /// When set, the provider is asked to constrain output to this JSON
    /// Schema (used only by `IntentResolver`). Text-rewrite Deeds leave this nil.
    public var jsonSchema: [String: Any]?
    /// Keeps latency reasonable and caps worst-case cost on a per-call basis.
    public var maxOutputTokens: Int

    public init(system: String, user: String, model: String, jsonSchema: [String: Any]? = nil, maxOutputTokens: Int = 600) {
        self.system = system
        self.user = user
        self.model = model
        self.jsonSchema = jsonSchema
        self.maxOutputTokens = maxOutputTokens
    }
}

public protocol AIProviderClient: Sendable {
    /// Runs one completion and returns the raw text content. Throws
    /// `AIActionError` for anything the caller should show a friendly
    /// message for (network failure, bad key, server error).
    func complete(_ request: AICompletionRequest) async throws -> String
}

/// Shared helpers used by every concrete client so retry/timeout/error
/// mapping behavior is identical across providers.
enum HTTPExecutor {
    static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    static func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AIActionError.invalidResponse
            }
            return (data, http)
        } catch let error as AIActionError {
            throw error
        } catch {
            throw AIActionError.network(error.localizedDescription)
        }
    }

    /// Pulls a short human-readable message out of a JSON error body without
    /// assuming any particular provider's exact schema, so a malformed or
    /// unexpected error payload degrades to a generic message instead of crashing.
    static func extractErrorMessage(from data: Data) -> String {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ""
        }
        if let error = obj["error"] as? [String: Any], let message = error["message"] as? String {
            return message
        }
        if let message = obj["message"] as? String {
            return message
        }
        return ""
    }
}
