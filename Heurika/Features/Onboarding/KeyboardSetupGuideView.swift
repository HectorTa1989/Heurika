import SwiftUI
import UIKit
import HeurikaCore

/// iOS does not expose a public deep link straight to
/// Settings › General › Keyboard › Keyboards — only to the app's own
/// Settings page. Once Heurika is installed, that page shows a "Keyboards"
/// row automatically (iOS adds it because the extension exists), so this
/// view opens the app's Settings page and spells out the remaining two taps
/// rather than pretending a one-tap deep link exists.
struct KeyboardSetupGuideView: View {
    let onFinished: () -> Void

    private let steps = [
        "Tap \"Open Settings\" below",
        "Tap Keyboards, then Add New Keyboard",
        "Choose Heurika, then tap it again and enable Allow Full Access",
    ]

    var body: some View {
        VStack(spacing: HeurikaTheme.Spacing.lg) {
            Spacer(minLength: HeurikaTheme.Spacing.xl)

            ZStack {
                Circle()
                    .fill(HeurikaColor.goldGradient)
                    .frame(width: 110, height: 110)
                    .shadow(color: HeurikaColor.antiqueGold.opacity(0.35), radius: 20, y: 8)
                Image(systemName: "gearshape.2")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(HeurikaColor.ink)
            }

            Text("Turn on Heurika")
                .font(HeurikaFont.display(28, weight: .bold))
                .foregroundStyle(HeurikaColor.ink)

            VStack(alignment: .leading, spacing: HeurikaTheme.Spacing.md) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: HeurikaTheme.Spacing.sm) {
                        Text("\(index + 1)")
                            .font(HeurikaFont.body(13, weight: .bold))
                            .foregroundStyle(HeurikaColor.parchment)
                            .frame(width: 22, height: 22)
                            .background(HeurikaColor.espresso, in: Circle())
                        Text(step)
                            .font(HeurikaFont.body(15))
                            .foregroundStyle(HeurikaColor.espressoSoft)
                        Spacer()
                    }
                }
            }
            .heurikaCard()
            .padding(.horizontal, HeurikaTheme.Spacing.lg)

            Text("Full Access is what lets AI Deeds reach the provider you approved. Ordinary typing stays local. Review or withdraw provider permission in Settings › AI Privacy & Consent.")
                .font(HeurikaFont.caption)
                .foregroundStyle(HeurikaColor.espressoSoft.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, HeurikaTheme.Spacing.xl)

            Spacer()

            VStack(spacing: HeurikaTheme.Spacing.sm) {
                VintageButton(title: "Open Settings", systemImage: "arrow.up.forward.app") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                VintageButton(title: "I'll do this later", style: .secondary) {
                    onFinished()
                }
            }
            .padding(.horizontal, HeurikaTheme.Spacing.lg)
            .padding(.bottom, HeurikaTheme.Spacing.lg)
        }
    }
}

#Preview {
    KeyboardSetupGuideView(onFinished: {})
        .background(HeurikaColor.parchmentGradient)
}
