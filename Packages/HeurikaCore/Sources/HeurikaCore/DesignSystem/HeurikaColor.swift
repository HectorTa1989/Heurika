import SwiftUI
import UIKit

/// Heurika's palette: parchment, espresso, antique gold. Defined as raw hex
/// so both SwiftUI (app) and UIKit (keyboard extension, which needs
/// `UIColor` for a couple of low-level drawing calls) can use the same
/// source of truth without duplicating values.
public enum HeurikaColor {

    // Base hex values
    public static let parchmentHex = "#F4EDE0"
    public static let parchmentDeepHex = "#E9DCC3"
    public static let espressoHex = "#3B2A20"
    public static let espressoSoftHex = "#5B4636"
    public static let antiqueGoldHex = "#B8863B"
    public static let antiqueGoldBrightHex = "#D4A24C"
    public static let inkHex = "#2A1E17"
    public static let crimsonAccentHex = "#8C3A2B"
    public static let sageHex = "#6B7A5E"

    // SwiftUI Colors
    public static let parchment = Color(hex: parchmentHex)
    public static let parchmentDeep = Color(hex: parchmentDeepHex)
    public static let espresso = Color(hex: espressoHex)
    public static let espressoSoft = Color(hex: espressoSoftHex)
    public static let antiqueGold = Color(hex: antiqueGoldHex)
    public static let antiqueGoldBright = Color(hex: antiqueGoldBrightHex)
    public static let ink = Color(hex: inkHex)
    public static let crimsonAccent = Color(hex: crimsonAccentHex)
    public static let sage = Color(hex: sageHex)

    /// Subtle warm gradient used behind hero / paywall content — evokes aged
    /// paper without needing a bundled texture image.
    public static let parchmentGradient = LinearGradient(
        colors: [parchment, parchmentDeep],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let goldGradient = LinearGradient(
        colors: [antiqueGoldBright, antiqueGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

public extension Color {
    /// Minimal hex initializer — no external dependency needed for a handful
    /// of brand colors.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

public extension UIColor {
    /// Used by the keyboard extension's UIKit key/action-bar drawing, which
    /// stays in plain UIKit for performance and memory footprint rather than
    /// hosting a SwiftUI view hierarchy inside the memory-constrained extension.
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
