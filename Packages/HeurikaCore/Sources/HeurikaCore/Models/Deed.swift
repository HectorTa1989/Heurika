import Foundation

/// A `Deed` is Heurika's unit of "doing something" — either rewriting the text
/// the person already typed, or resolving to a concrete outside action
/// (insert a link, search result, meeting link, or calendar draft).
///
/// Everything the keyboard can do — the seven built-in Deeds, anything pinned
/// to a Deed Key, anything the person makes in the Deed Builder — is a `Deed`.
public struct Deed: Identifiable, Codable, Equatable, Hashable, Sendable {

    public enum Kind: String, Codable, Equatable, Hashable, Sendable {
        /// Rewrites the text before the cursor in place, using an LLM instruction.
        case rewrite
    /// Resolves to useful inserted output rather than an AI rewrite.
        case act
    }

    /// What an `.act` Deed actually does once its parameters are filled in.
    public enum ActPayload: Codable, Equatable, Hashable, Sendable {
        /// Builds a URL from `template`, where `{query}` is replaced with the
        /// URL-encoded search text, then inserts the URL into the text field.
        case openURLTemplate(template: String)
        /// Produces a readable calendar-event draft. The keyboard never launches
        /// the containing app or another app.
        case createCalendarEvent
        /// Calls the real Notion Search API with the person's own integration
        /// token and inserts the best match's title + URL at the cursor.
        case notionSearch
        /// Copies the resolved text to the clipboard instead of inserting it.
        case copyToClipboard

        private enum CodingKeys: String, CodingKey { case type, template }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let type = try c.decode(String.self, forKey: .type)
            switch type {
            case "openURLTemplate":
                self = .openURLTemplate(template: try c.decode(String.self, forKey: .template))
            case "createCalendarEvent":
                self = .createCalendarEvent
            case "notionSearch":
                self = .notionSearch
            case "copyToClipboard":
                self = .copyToClipboard
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: c, debugDescription: "Unknown ActPayload type \(type)")
            }
        }

        public func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .openURLTemplate(let template):
                try c.encode("openURLTemplate", forKey: .type)
                try c.encode(template, forKey: .template)
            case .createCalendarEvent:
                try c.encode("createCalendarEvent", forKey: .type)
            case .notionSearch:
                try c.encode("notionSearch", forKey: .type)
            case .copyToClipboard:
                try c.encode("copyToClipboard", forKey: .type)
            }
        }
    }

    public var id: String
    public var name: String
    /// SF Symbol name — every icon in Heurika is a system symbol, never a
    /// bundled image asset, so Deeds stay lightweight and shareable as plain JSON.
    public var symbol: String
    public var kind: Kind
    /// For `.rewrite` Deeds: the instruction sent to the LLM, e.g.
    /// "Fix grammar and spelling. Keep meaning and tone unchanged."
    public var instruction: String?
    /// For `.act` Deeds: what actually happens.
    public var actPayload: ActPayload?
    public var isBuiltIn: Bool
    /// Free plan can use every built-in Deed; only custom (non-built-in) Deeds
    /// are Pro-gated. See `AIActionService` for where this is enforced.
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        symbol: String,
        kind: Kind,
        instruction: String? = nil,
        actPayload: ActPayload? = nil,
        isBuiltIn: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.kind = kind
        self.instruction = instruction
        self.actPayload = actPayload
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
    }
}

// MARK: - Built-in catalog

public enum BuiltInDeeds {

    /// The seven built-in rewrite Deeds. Free forever, no provider restriction
    /// beyond the free plan's own Groq-only + daily-cap rules.
    public static let rewrites: [Deed] = [
        Deed(id: "builtin.polish", name: "Polish", symbol: "sparkles",
             kind: .rewrite,
             instruction: "Improve clarity, grammar, and flow while preserving the original meaning, tone, and intent as closely as possible.",
             isBuiltIn: true),

        Deed(id: "builtin.grammar", name: "Fix Grammar", symbol: "checkmark.seal",
             kind: .rewrite,
             instruction: "Fix grammar, spelling, and punctuation mistakes only. Keep the meaning, tone, and length essentially unchanged.",
             isBuiltIn: true),

        Deed(id: "builtin.professional", name: "Professional", symbol: "briefcase",
             kind: .rewrite,
             instruction: "Rewrite in a professional, polished business tone suitable for a colleague or client. Keep the core meaning.",
             isBuiltIn: true),

        Deed(id: "builtin.casual", name: "Casual", symbol: "bubble.left.and.bubble.right",
             kind: .rewrite,
             instruction: "Rewrite in a relaxed, casual, conversational tone, like texting a friend. Keep the core meaning.",
             isBuiltIn: true),

        Deed(id: "builtin.friendlier", name: "Friendlier", symbol: "heart",
             kind: .rewrite,
             instruction: "Rewrite to sound warmer, kinder, and more approachable, without becoming unprofessional or insincere.",
             isBuiltIn: true),

        Deed(id: "builtin.shorten", name: "Shorten", symbol: "arrow.down.right.and.arrow.up.left",
             kind: .rewrite,
             instruction: "Shorten this text as much as possible while preserving its essential meaning and key details.",
             isBuiltIn: true),

        Deed(id: "builtin.expand", name: "Expand", symbol: "arrow.up.left.and.arrow.down.right",
             kind: .rewrite,
             instruction: "Expand this text with a bit more detail and natural elaboration, without padding or repeating yourself.",
             isBuiltIn: true),

        Deed(id: "builtin.translate", name: "Translate", symbol: "globe",
             kind: .rewrite,
             instruction: "__TRANSLATE__", // PromptBuilder substitutes the configured target language in for this token.
             isBuiltIn: true),
    ]

    /// The six built-in act Deeds insert useful links or results without
    /// launching another app from the keyboard.
    public static let acts: [Deed] = [
        Deed(id: "builtin.websearch", name: "Web Search", symbol: "magnifyingglass",
             kind: .act, actPayload: .openURLTemplate(template: "https://www.google.com/search?q={query}"),
             isBuiltIn: true),

        Deed(id: "builtin.maps", name: "Nearby / Maps", symbol: "map",
             kind: .act, actPayload: .openURLTemplate(template: "https://maps.apple.com/?q={query}"),
             isBuiltIn: true),

        Deed(id: "builtin.linkedin", name: "LinkedIn Search", symbol: "person.crop.rectangle",
             kind: .act, actPayload: .openURLTemplate(template: "https://www.linkedin.com/search/results/people/?keywords={query}"),
             isBuiltIn: true),

        Deed(id: "builtin.meet", name: "Start a Meet", symbol: "video",
             kind: .act, actPayload: .openURLTemplate(template: "https://meet.google.com/new"),
             isBuiltIn: true),

        Deed(id: "builtin.notion", name: "Notion Search", symbol: "doc.text.magnifyingglass",
             kind: .act, actPayload: .notionSearch,
             isBuiltIn: true),

        Deed(id: "builtin.calendar", name: "New Calendar Event", symbol: "calendar.badge.plus",
             kind: .act, actPayload: .createCalendarEvent,
             isBuiltIn: true),
    ]

    public static var all: [Deed] { rewrites + acts }

    /// Used as the Heurika Bar's target when intent resolution decides the
    /// person wants their own text improved but didn't imply a more specific
    /// style (professional, shorter, translated, ...).
    public static let polish: Deed = rewrites.first { $0.id == "builtin.polish" }!

    public static func find(id: String) -> Deed? {
        all.first { $0.id == id }
    }
}
