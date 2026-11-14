import UIKit
import HeurikaCore

/// Wraps the one piece of text a third-party keyboard can actually see:
/// `documentContextBeforeInput`. iOS does not guarantee how much context this
/// returns (it can be nil, or trimmed for performance), and — importantly —
/// keyboard extensions have no API to read an arbitrary text *selection* in
/// the host app, only text immediately before/after the cursor. Every Deed
/// in Heurika is therefore scoped to "the text you just typed", not
/// "whatever's selected". See README → "What a keyboard extension can
/// actually see".
enum TextContextReader {

    static func currentContext(from proxy: UITextDocumentProxy) -> String {
        let before = proxy.documentContextBeforeInput ?? ""
        if before.count > HeurikaConstants.maxContextCharacters {
            // `.suffix` operates on Characters (grapheme clusters), not UTF-16
            // code units, so this can't split a multi-scalar emoji in half.
            return String(before.suffix(HeurikaConstants.maxContextCharacters))
        }
        return before
    }

    static func currentWord(from proxy: UITextDocumentProxy) -> String {
        let before = proxy.documentContextBeforeInput ?? ""
        let allowed = CharacterSet.letters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "'’"))
        let suffix = before.reversed().prefix { character in
            character.unicodeScalars.allSatisfy { allowed.contains($0) }
        }
        return String(suffix.reversed())
    }
}
