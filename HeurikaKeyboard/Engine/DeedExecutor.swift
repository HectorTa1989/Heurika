import UIKit
import HeurikaCore

enum DeedExecutionOutcome {
    /// The caller should delete `originalLength` characters before the
    /// cursor and insert `text` — used for rewrites and the Notion Deed's
    /// "Title — url" result.
    case replaceText(String, originalLength: Int)
    /// Inserts new text at the cursor without replacing the current context.
    case insertText(String)
    case copiedToClipboard
}

/// Runs a Deed against the current text context. Everything provider-side
/// (gating, prompt building, HTTP) lives in `HeurikaCore`; this layer only
/// does the things that are specific to being *inside a keyboard extension*:
/// preparing safe text/link output and the delete/insert dance against
/// `UITextDocumentProxy`. Keyboard extensions must not launch other apps, so
/// action Deeds insert useful output rather than opening a destination.
@MainActor
final class DeedExecutor {
    private let actionService = AIActionService()

    init() {}

    func execute(deed: Deed, context: String, resolvedQuery: String? = nil) async throws -> DeedExecutionOutcome {
        switch deed.kind {
        case .rewrite:
            let rewritten = try await actionService.runRewrite(deed: deed, inputText: context)
            return .replaceText(rewritten, originalLength: context.count)

        case .act:
            guard let payload = deed.actPayload else { throw AIActionError.invalidResponse }
            let query = resolvedQuery ?? context
            return try await executeAct(payload, query: query, originalLength: context.count)
        }
    }

    private func executeAct(_ payload: Deed.ActPayload, query: String, originalLength: Int) async throws -> DeedExecutionOutcome {
        switch payload {
        case .openURLTemplate(let template):
            let url = Self.buildURL(template: template, query: query)
            return .replaceText(url.absoluteString, originalLength: originalLength)

        case .createCalendarEvent:
            let draft = "Calendar event: \(query)"
            return .replaceText(draft, originalLength: originalLength)

        case .notionSearch:
            let result = try await actionService.runNotionSearch(query: query)
            let text = result.url.isEmpty ? result.title : "\(result.title) — \(result.url)"
            return .replaceText(text, originalLength: originalLength)

        case .copyToClipboard:
            UIPasteboard.general.string = query
            return .copiedToClipboard
        }
    }

    /// Replaces the first `{query}` token with the URL-encoded query. If a
    /// template has no `{query}` token at all (e.g. a fixed meeting link),
    /// it is inserted as-is.
    static func buildURL(template: String, query: String) -> URL {
        let unreserved = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        let encoded = query.addingPercentEncoding(withAllowedCharacters: unreserved) ?? ""
        let filled = template.replacingOccurrences(of: "{query}", with: encoded)
        return URL(string: filled) ?? URL(string: "https://www.google.com/search?q=\(encoded)")!
    }
}
