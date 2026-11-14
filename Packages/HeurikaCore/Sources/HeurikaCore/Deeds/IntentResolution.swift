import Foundation

/// The structured decision the LLM hands back when the person holds the
/// Heurika Bar. This is the "agentic" core of the product: instead of the
/// person picking a Deed chip, they type what they want in plain language and
/// the model decides which Deed applies and what to fill into it.
///
/// Deliberately narrow: the model chooses from the Deed catalog it's given
/// (built-ins + the person's own saved Deeds) and fills in a query / rewrite
/// text. It never invents live facts (scores, prices, hours) — for anything
/// that would require real-time data Heurika doesn't have, resolution routes
/// to `.act` with a search/maps Deed so the real source answers, rather than
/// letting the model guess. See README → "On not making things up".
public struct IntentResolution: Codable, Equatable, Sendable {
    public enum Resolution: String, Codable, Equatable, Sendable {
        /// The typed text should be rewritten in place per `instruction`.
        case rewrite
        /// One of the catalog Deeds should run, using `query` as its input.
        case act
        /// The model could not confidently map the intent to anything —
        /// surfaced to the person as a gentle "not sure what you meant" toast
        /// rather than silently doing nothing or guessing.
        case unclear
    }

    public var resolution: Resolution
    /// Present when `resolution == .act`: the id of the chosen catalog Deed.
    public var deedID: String?
    /// The text to hand to the chosen Deed (search query, rewrite instruction
    /// target, calendar event description, etc).
    public var query: String?
    /// One-line reason, shown briefly in the keyboard's status area so the
    /// person can see what Heurika understood before it acts.
    public var reasoning: String?

    public init(resolution: Resolution, deedID: String?, query: String?, reasoning: String?) {
        self.resolution = resolution
        self.deedID = deedID
        self.query = query
        self.reasoning = reasoning
    }

    /// The exact JSON Schema handed to providers that support constrained
    /// structured output (Groq / OpenAI json_schema mode). Keeping this next
    /// to the model it decodes into means the two can't drift apart.
    public static let jsonSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "resolution": ["type": "string", "enum": ["rewrite", "act", "unclear"]],
            "deedID": ["type": ["string", "null"]],
            "query": ["type": ["string", "null"]],
            "reasoning": ["type": ["string", "null"]]
        ],
        "required": ["resolution", "deedID", "query", "reasoning"],
        "additionalProperties": false
    ]
}
