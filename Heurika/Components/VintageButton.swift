import SwiftUI
import HeurikaCore

/// The house primary/secondary button styles. Primary uses the gold
/// gradient with an embossed feel (light inner highlight + soft shadow);
/// secondary is an outlined espresso hairline on parchment.
struct VintageButton: View {
    enum Style { case primary, secondary, destructive }

    let title: String
    var systemImage: String?
    var style: Style = .primary
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: HeurikaTheme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(HeurikaFont.body(16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(foregroundColor)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: HeurikaTheme.Radius.md, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: HeurikaTheme.Radius.md, style: .continuous))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.85 : 1)
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .primary: HeurikaColor.goldGradient
        case .secondary: HeurikaColor.parchment
        case .destructive: HeurikaColor.crimsonAccent.opacity(0.12)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return HeurikaColor.ink
        case .secondary: return HeurikaColor.espresso
        case .destructive: return HeurikaColor.crimsonAccent
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: return HeurikaColor.espresso.opacity(0.4)
        default: return .clear
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        VintageButton(title: "Continue", systemImage: "arrow.right", style: .primary) {}
        VintageButton(title: "Not now", style: .secondary) {}
        VintageButton(title: "Delete Deed", systemImage: "trash", style: .destructive) {}
        VintageButton(title: "Loading…", style: .primary, isLoading: true) {}
    }
    .padding()
    .background(HeurikaColor.parchment)
}
