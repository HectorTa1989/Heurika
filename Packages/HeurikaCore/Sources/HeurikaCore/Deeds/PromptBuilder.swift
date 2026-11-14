import Foundation

/// Builds the system/user message pair sent to whichever provider is active.
/// Pure and dependency-free on purpose — this is the piece most worth unit
/// testing, since a subtly wrong prompt silently produces bad rewrites rather
/// than throwing an error.
public enum PromptBuilder {

    public static let translateToken = "__TRANSLATE__"

    /// Builds the (system, user) pair for a `.rewrite` Deed.
    public static func build(for deed: Deed, input: String, translateLanguage: String) -> (system: String, user: String) {
        var instruction = deed.instruction ?? "Rewrite the following text, keeping its meaning intact."
        if instruction == translateToken {
            instruction = "Translate the following text into \(translateLanguage). Return only the translation, preserving tone and meaning."
        }

        let system = """
        You are a precise, minimal text-rewriting engine embedded in a mobile keyboard.
        Instruction: \(instruction)
        Rules:
        - Output ONLY the rewritten text.
        - No explanations, no preamble, no quotation marks, no markdown formatting.
        - Preserve the original language unless the instruction says to translate.
        - If the input is empty or nonsensical, return it unchanged.
        """

        return (system, input)
    }

    /// Builds the (system, user) pair for the Heurika Bar's intent router.
    /// `catalog` is the list of `.act` Deeds currently available to route to
    /// (built-ins plus the person's own act-type custom Deeds).
    public static func buildIntentResolution(typedText: String, catalog: [Deed]) -> (system: String, user: String) {
        let catalogDescription = catalog.map { deed -> String in
            let kind = deed.kind == .rewrite ? "rewrite" : "act"
            return "- id: \"\(deed.id)\", name: \"\(deed.name)\", kind: \"\(kind)\""
        }.joined(separator: "\n")

        let system = """
        You are the intent router for Heurika, an agentic keyboard. The person typed
        free text and is asking you to decide what to do with it.

        You may choose exactly one of:
        1. "rewrite" — if they want their own text improved, translated, or restyled in place.
           Pick the best rewrite deedID from the catalog. Use builtin.polish only when no
           more specific rewrite matches.
        2. "act" — if they want a link, lookup, or action result. Pick the single
           best-matching act deedID from this catalog (do not invent new ids):
        \(catalogDescription)
        3. "unclear" — if you genuinely cannot tell what they want. Prefer this over guessing.

        Critical: you have no access to live data (scores, prices, hours, current events).
        Never fabricate an answer. If the request needs live information, resolve to "act"
        with the best matching search/maps Deed and put the search terms in "query" — the
        real destination will answer it, not you.

        Respond with strict JSON only, matching the given schema.
        """

        return (system, typedText)
    }
}
