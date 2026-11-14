import SwiftUI

/// Font tokens for the container app. Playfair Display carries headlines and
/// hero moments; Lora carries body copy and UI labels — a classic
/// display-serif/text-serif pairing that reads as considered rather than
/// templated. Every case uses `relativeTo:` so Dynamic Type still scales
/// these correctly for accessibility.
///
/// NOTE: these custom serif faces are used throughout the container app
/// (onboarding, settings, paywall) but deliberately NOT for the keyboard's
/// own letter keys — key glyphs stay on the system font for maximum
/// legibility at small sizes and to keep the extension's memory footprint
/// low. The vintage palette still carries through to the keyboard's action
/// bar and buttons. See KeyboardLayoutProvider.
public enum HeurikaFont {

    public static func display(_ size: CGFloat, weight: DisplayWeight = .regular) -> Font {
        .custom(weight.postscriptName, size: size, relativeTo: .largeTitle)
    }

    public static func body(_ size: CGFloat = 17, weight: BodyWeight = .regular) -> Font {
        .custom(weight.postscriptName, size: size, relativeTo: .body)
    }

    public enum DisplayWeight {
        case regular, semibold, bold, black

        var postscriptName: String {
            switch self {
            case .regular: return "PlayfairDisplayHeurika-Regular"
            case .semibold: return "PlayfairDisplayHeurika-SemiBold"
            case .bold: return "PlayfairDisplayHeurika-Bold"
            case .black: return "PlayfairDisplayHeurika-Black"
            }
        }
    }

    public enum BodyWeight {
        case regular, medium, semibold, bold, italic

        var postscriptName: String {
            switch self {
            case .regular: return "LoraHeurika-Regular"
            case .medium: return "LoraHeurika-Medium"
            case .semibold: return "LoraHeurika-SemiBold"
            case .bold: return "LoraHeurika-Bold"
            case .italic: return "LoraHeurika-Italic"
            }
        }
    }

    // Common presets used across most screens, so views don't hand-pick sizes ad hoc.
    public static let heroTitle = display(34, weight: .bold)
    public static let title = display(26, weight: .semibold)
    public static let sectionHeader = display(20, weight: .semibold)
    public static let bodyText = body(17)
    public static let caption = body(13, weight: .medium)
    public static let quote = body(18, weight: .italic)
}
