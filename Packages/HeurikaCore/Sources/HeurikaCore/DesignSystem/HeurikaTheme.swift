import SwiftUI

/// Layout constants so spacing/radius/shadow choices stay consistent instead
/// of being re-guessed on every screen.
public enum HeurikaTheme {
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 36
        public static let xxl: CGFloat = 52
    }

    public enum Radius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 14
        public static let lg: CGFloat = 22
        public static let pill: CGFloat = 999
    }

    public enum Stroke {
        /// A thin antique-gold hairline used to edge cards instead of a flat
        /// system shadow — reads as "engraved" rather than "material design".
        public static func hairline(_ color: Color = HeurikaColor.antiqueGold.opacity(0.35)) -> some ShapeStyle {
            color
        }
    }

    public static let cardShadow = Color.black.opacity(0.12)
}

public extension View {
    /// The house card style: parchment fill, gold hairline border, soft
    /// espresso-tinted shadow, generous corner radius.
    func heurikaCard(padding: CGFloat = HeurikaTheme.Spacing.lg) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: HeurikaTheme.Radius.lg, style: .continuous)
                    .fill(HeurikaColor.parchment)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HeurikaTheme.Radius.lg, style: .continuous)
                    .strokeBorder(HeurikaColor.antiqueGold.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: HeurikaTheme.cardShadow, radius: 12, x: 0, y: 6)
    }
}
