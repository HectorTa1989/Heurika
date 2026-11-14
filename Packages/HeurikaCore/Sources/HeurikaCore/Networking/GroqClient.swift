import Foundation

/// Groq's API is OpenAI-compatible at api.groq.com/openai/v1. This is the
/// default, free-plan provider — Groq offers a free individual-developer API
/// tier, so a person can use Heurika's free plan at zero cost with their own
/// key, without Heurika embedding or proxying any shared secret.
public struct GroqClient: AIProviderClient {
    private let apiKey: String
    private static let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func complete(_ request: AICompletionRequest) async throws -> String {
        var urlRequest = URLRequest(url: Self.endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "model": request.model,
            "messages": [
                ["role": "system", "content": request.system],
                ["role": "user", "content": request.user]
            ],
            "max_completion_tokens": request.maxOutputTokens,
            "temperature": 0.4
        ]

        if let schema = request.jsonSchema {
            body["response_format"] = [
                "type": "json_schema",
                "json_schema": [
                    "name": "heurika_intent",
                    "schema": schema,
                    "strict": true
                ]
            ]
        }

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, http) = try await HTTPExecutor.send(urlRequest)

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw AIActionError.noAPIKey(provider: .groq)
            }
            throw AIActionError.server(status: http.statusCode, message: HTTPExecutor.extractErrorMessage(from: data))
        }

        return try Self.extractContent(from: data)
    }

    private static func extractContent(from data: Data) throws -> String {
        guard
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = obj["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw AIActionError.invalidResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
