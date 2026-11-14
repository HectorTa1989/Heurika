import SwiftUI
import HeurikaCore

struct AIPrivacySettingsView: View {
    @State private var consentedProviders: Set<AIProviderType> = []

    var body: some View {
        Form {
            Section {
                Text("Heurika sends text only when you tap its dedicated action or a Deed. The selected text, the Deed instruction, and no other keystrokes are sent to the provider you approved.")
                    .font(HeurikaFont.caption)
                    .foregroundStyle(HeurikaColor.espressoSoft)
            } header: {
                Text("How AI data is used")
            }

            Section {
                ForEach(AIProviderType.allCases) { provider in
                    Toggle(isOn: consentBinding(for: provider)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(provider.displayName)
                            Text("Send selected text and instructions when you run an AI Deed")
                                .font(HeurikaFont.caption)
                                .foregroundStyle(HeurikaColor.espressoSoft)
                        }
                    }
                }
            } header: {
                Text("Provider permissions")
            } footer: {
                Text("Turning a provider off immediately blocks new AI requests to it. Stored API keys are managed separately under AI Provider & Keys.")
            }

            Section("Other integrations") {
                Label("Notion receives only the search query you submit through the Notion Search Deed.", systemImage: "doc.text.magnifyingglass")
                    .font(HeurikaFont.caption)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HeurikaColor.parchment)
        .navigationTitle("AI Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refresh() }
    }

    private func consentBinding(for provider: AIProviderType) -> Binding<Bool> {
        Binding(
            get: { consentedProviders.contains(provider) },
            set: { isOn in
                if isOn {
                    SharedDefaults.shared.grantAIDataConsent(for: provider)
                    consentedProviders.insert(provider)
                } else {
                    SharedDefaults.shared.revokeAIDataConsent(for: provider)
                    consentedProviders.remove(provider)
                }
            }
        )
    }

    private func refresh() {
        consentedProviders = Set(AIProviderType.allCases.filter {
            SharedDefaults.shared.hasCurrentAIDataConsent(for: $0)
        })
    }
}

#Preview {
    NavigationStack { AIPrivacySettingsView() }
}
