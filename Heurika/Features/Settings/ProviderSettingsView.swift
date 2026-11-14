import SwiftUI
import HeurikaCore

struct ProviderSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingPaywall = false

    var body: some View {
        Form {
            Section {
                Text("Every provider is bring-your-own-key. Heurika never ships a shared key — your key, your rate limits, your cost (Groq's free tier means most people pay nothing).")
                    .font(HeurikaFont.caption)
                    .foregroundStyle(HeurikaColor.espressoSoft)
            }

            Section("Active Provider") {
                Picker("Provider", selection: Binding(
                    get: { viewModel.settings.selectedProvider },
                    set: { newValue in
                        if newValue.requiresPro && !viewModel.isPro {
                            showingPaywall = true
                            return
                        }
                        viewModel.settings.selectedProvider = newValue
                        viewModel.persistSettings()
                    }
                )) {
                    ForEach(AIProviderType.allCases) { provider in
                        HStack {
                            Text(provider.displayName)
                            if provider.requiresPro && !viewModel.isPro {
                                Text("PRO")
                            }
                        }
                        .tag(provider)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("AI Data Permission") {
                if SharedDefaults.shared.hasCurrentAIDataConsent(for: viewModel.settings.selectedProvider) {
                    Label("Approved for \(viewModel.settings.selectedProvider.displayName)", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(HeurikaColor.sage)
                } else {
                    NavigationLink {
                        AIPrivacySettingsView()
                    } label: {
                        Label("Review before using \(viewModel.settings.selectedProvider.displayName)", systemImage: "hand.raised")
                            .foregroundStyle(HeurikaColor.crimsonAccent)
                    }
                }
            }

            ForEach(AIProviderType.allCases) { provider in
                providerKeySection(provider)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HeurikaColor.parchment)
        .navigationTitle("AI Provider")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.refresh() }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .safeAreaInset(edge: .bottom) {
            if let confirmation = viewModel.savedConfirmation {
                Text(confirmation)
                    .font(HeurikaFont.caption)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(HeurikaColor.espresso, in: Capsule())
                    .foregroundStyle(HeurikaColor.parchment)
                    .padding(.bottom, HeurikaTheme.Spacing.sm)
            }
        }
    }

    @ViewBuilder
    private func providerKeySection(_ provider: AIProviderType) -> some View {
        Section {
            if viewModel.hasStoredKey(for: provider) {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(HeurikaColor.sage)
                    Text("Key saved")
                    Spacer()
                    Button("Remove", role: .destructive) {
                        viewModel.clearKey(for: provider)
                    }
                    .font(HeurikaFont.caption)
                }
            } else {
                SecureField("\(provider.displayName) API key", text: keyBinding(for: provider))
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                Button("Save Key") {
                    viewModel.saveKey(keyBinding(for: provider).wrappedValue, for: provider)
                }
            }

            Link(destination: provider.consoleURL) {
                Label("Get a \(provider.displayName) key", systemImage: "arrow.up.forward")
            }
            .font(HeurikaFont.caption)

            if provider == .groq {
                TextField("Model", text: Binding(
                    get: { viewModel.settings.groqModel },
                    set: { viewModel.settings.groqModel = $0; viewModel.persistSettings() }
                ))
            } else if provider == .openAI {
                TextField("Model", text: Binding(
                    get: { viewModel.settings.openAIModel },
                    set: { viewModel.settings.openAIModel = $0; viewModel.persistSettings() }
                ))
            } else {
                TextField("Model", text: Binding(
                    get: { viewModel.settings.anthropicModel },
                    set: { viewModel.settings.anthropicModel = $0; viewModel.persistSettings() }
                ))
            }
        } header: {
            HStack {
                Text(provider.displayName)
                if provider.requiresPro { ProSealBadge() }
            }
        } footer: {
            Text("Model names occasionally change on the provider's end — update this if a request starts failing.")
        }
    }

    private func keyBinding(for provider: AIProviderType) -> Binding<String> {
        switch provider {
        case .groq: return $viewModel.groqKey
        case .openAI: return $viewModel.openAIKey
        case .anthropic: return $viewModel.anthropicKey
        }
    }
}

#Preview {
    NavigationStack {
        ProviderSettingsView(viewModel: SettingsViewModel())
    }
}
