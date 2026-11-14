import Foundation
import HeurikaCore

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings = SharedDefaults.shared.providerSettings
    @Published var isPro = SharedDefaults.shared.subscriptionStatus.effectiveIsPro

    @Published var groqKey = ""
    @Published var openAIKey = ""
    @Published var anthropicKey = ""
    @Published var notionToken = ""

    @Published var savedConfirmation: String?

    func refresh() {
        settings = SharedDefaults.shared.providerSettings
        isPro = SharedDefaults.shared.subscriptionStatus.effectiveIsPro
        // Keys are never pre-filled into the text fields once saved — the
        // field shows a placeholder indicating one is stored, matching how
        // most apps treat secrets already written to Keychain.
    }

    func hasStoredKey(for provider: AIProviderType) -> Bool {
        KeychainStore.shared.apiKey(for: provider) != nil
    }

    func persistSettings() {
        SharedDefaults.shared.providerSettings = settings
    }

    func saveKey(_ value: String, for provider: AIProviderType) {
        guard !value.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        KeychainStore.shared.setAPIKey(value, for: provider)
        clearField(for: provider)
        flashConfirmation("\(provider.displayName) key saved")
    }

    func clearKey(for provider: AIProviderType) {
        KeychainStore.shared.setAPIKey(nil, for: provider)
        clearField(for: provider)
        flashConfirmation("\(provider.displayName) key removed")
    }

    func saveNotionToken() {
        guard !notionToken.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        KeychainStore.shared.setNotionToken(notionToken)
        notionToken = ""
        var updated = settings
        updated.notionIntegrationTokenSet = true
        settings = updated
        persistSettings()
        flashConfirmation("Notion token saved")
    }

    func clearNotionToken() {
        KeychainStore.shared.setNotionToken(nil)
        notionToken = ""
        var updated = settings
        updated.notionIntegrationTokenSet = false
        settings = updated
        persistSettings()
        flashConfirmation("Notion token removed")
    }

    private func clearField(for provider: AIProviderType) {
        switch provider {
        case .groq: groqKey = ""
        case .openAI: openAIKey = ""
        case .anthropic: anthropicKey = ""
        }
    }

    private func flashConfirmation(_ text: String) {
        savedConfirmation = text
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if savedConfirmation == text { savedConfirmation = nil }
        }
    }
}
