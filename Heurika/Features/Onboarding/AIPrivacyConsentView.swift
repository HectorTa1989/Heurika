import SwiftUI
import HeurikaCore

struct AIPrivacyConsentView: View {
    let onContinue: () -> Void

    @State private var hasAgreed = false

    private var provider: AIProviderType {
        SharedDefaults.shared.providerSettings.selectedProvider
    }

    var body: some View {
        VStack(spacing: HeurikaTheme.Spacing.lg) {
            Spacer(minLength: HeurikaTheme.Spacing.xl)

            Image(systemName: "hand.raised.square.fill")
                .font(.system(size: 58))
                .foregroundStyle(HeurikaColor.antiqueGold)
                .accessibilityHidden(true)

            Text("Choose what leaves your phone")
                .font(HeurikaFont.display(28, weight: .bold))
                .foregroundStyle(HeurikaColor.ink)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: HeurikaTheme.Spacing.md) {
                disclosureRow("text.bubble", "Only text you explicitly run through Heurika is sent.")
                disclosureRow("arrow.up.right", "That text and the rewrite instruction go to \(provider.displayName).")
                disclosureRow("key.horizontal", "Your \(provider.displayName) API key is stored in the iOS Keychain.")
                disclosureRow("keyboard", "Ordinary typing is never logged or sent by Heurika.")
            }
            .heurikaCard()
            .padding(.horizontal, HeurikaTheme.Spacing.lg)

            Toggle(isOn: $hasAgreed) {
                Text("I allow selected text to be sent to \(provider.displayName) when I run an AI Deed.")
                    .font(HeurikaFont.body(14))
                    .foregroundStyle(HeurikaColor.ink)
            }
            .tint(HeurikaColor.antiqueGold)
            .padding(.horizontal, HeurikaTheme.Spacing.xl)

            Text("You can withdraw this permission or approve another provider at any time in Settings › AI Privacy.")
                .font(HeurikaFont.caption)
                .foregroundStyle(HeurikaColor.espressoSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HeurikaTheme.Spacing.xl)

            Spacer()

            VintageButton(title: "Continue", systemImage: "checkmark.shield") {
                SharedDefaults.shared.grantAIDataConsent(for: provider)
                onContinue()
            }
            .disabled(!hasAgreed)
            .padding(.horizontal, HeurikaTheme.Spacing.lg)
            .padding(.bottom, HeurikaTheme.Spacing.lg)
        }
    }

    private func disclosureRow(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: HeurikaTheme.Spacing.sm) {
            Image(systemName: symbol)
                .foregroundStyle(HeurikaColor.antiqueGold)
                .frame(width: 22)
            Text(text)
                .font(HeurikaFont.body(14))
                .foregroundStyle(HeurikaColor.espressoSoft)
            Spacer()
        }
    }
}

#Preview {
    AIPrivacyConsentView(onContinue: {})
        .background(HeurikaColor.parchmentGradient)
}
