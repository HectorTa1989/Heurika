import Foundation

/// Calls Notion's real Search API (`POST /v1/search`) with the person's own
/// internal integration token. Returns the single best-matching page's title
/// and URL as plain text — not a scrape, not an approximation, an actual API
/// call against results the token's workspace grants access to.
///
/// Setup: the person creates an "Internal Integration" at
/// notion.so/my-integrations, pastes the token into Heurika Settings, and
/// shares the specific pages/databases they want searchable with that
/// integration from within Notion (Notion scopes internal integrations to
/// explicitly-shared content — Heurika cannot search anything the person
/// hasn't shared with their own integration).
public struct NotionClient: Sendable {
    private let token: String
    private static let endpoint = URL(string: "https://api.notion.com/v1/search")!
    private static let notionVersion = "2022-06-28"

    public init(token: String) {
        self.token = token
    }

    public struct Result: Sendable {
        public let title: String
        public let url: String
    }

    public func search(query: String) async throws -> Result {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.notionVersion, forHTTPHeaderField: "Notion-Version")

        let body: [String: Any] = [
            "query": query,
            "page_size": 1,
            "sort": ["direction": "descending", "timestamp": "last_edited_time"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, http) = try await HTTPExecutor.send(request)

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 {
                throw AIActionError.notionNotConfigured
            }
            throw AIActionError.server(status: http.statusCode, message: HTTPExecutor.extractErrorMessage(from: data))
        }

        guard
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let results = obj["results"] as? [[String: Any]],
            let first = results.first
        else {
            throw AIActionError.notionNoResults
        }

        let url = (first["url"] as? String) ?? ""
        let title = Self.extractTitle(from: first) ?? "Untitled"
        return Result(title: title, url: url)
    }

    /// Notion's title lives nested inside whichever property is of type
    /// "title" — its key name varies by database, so this scans for the
    /// type rather than assuming a property is literally called "title".
    private static func extractTitle(from page: [String: Any]) -> String? {
        guard let properties = page["properties"] as? [String: Any] else { return nil }
        for (_, value) in properties {
            guard let prop = value as? [String: Any], (prop["type"] as? String) == "title" else { continue }
            guard let titleArray = prop["title"] as? [[String: Any]] else { continue }
            let text = titleArray.compactMap { ($0["plain_text"] as? String) }.joined()
            if !text.isEmpty { return text }
        }
        return nil
    }
}
