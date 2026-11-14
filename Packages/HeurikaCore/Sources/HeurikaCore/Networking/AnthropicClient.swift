import Foundation

/// Bring-your-own-key Anthropic client using the Messages API. Unlike the
/// OpenAI-shaped providers, `system` is a top-level request field (not a
/// message role) and response text comes back as an array of content blocks.
public struct AnthropicClient: AIProviderClient {
    private let apiKey: String
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let apiVersion = "2023-06-01"

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func complete(_ request: AICompletionRequest) async throws -> String {
        var urlRequest = URLRequest(url: Self.endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")

        var system = request.system
        if request.jsonSchema != nil {
            // The Messages API doesn't take a JSON-schema response_format the
            // way OpenAI-compatible APIs do, so structured output is enforced
            // by instruction + a strict parse on our side (IntentResolver
            // falls back to `.unclear` if parsing fails, it never guesses).
            system += "\n\nRespond with ONLY a single valid JSON object matching this exact shape, no prose, no markdown fences: " +
                (try? String(data: JSONSerialization.data(withJSONObject: request.jsonSchema ?? [:]), encoding: .utf8) ?? "")!
        }

        let body: [String: Any] = [
            "model": request.model,
            "system": system,
            "messages": [
                ["role": "user", "content": request.user]
            ],
            "max_tokens": request.maxOutputTokens,
            "temperature": 0.4
        ]

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, http) = try await HTTPExecutor.send(urlRequest)

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw AIActionError.noAPIKey(provider: .anthropic)
            }
            throw AIActionError.server(status: http.statusCode, message: HTTPExecutor.extractErrorMessage(from: data))
        }

        guard
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = obj["content"] as? [[String: Any]],
            let firstText = content.first(where: { ($0["type"] as? String) == "text" }),
            let text = firstText["text"] as? String
        else {
            throw AIActionError.invalidResponse
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
