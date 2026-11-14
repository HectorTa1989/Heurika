import SwiftUI
import HeurikaCore

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(viewModel.isPro ? "Heurika Pro" : "Free Plan")
                            .font(HeurikaFont.body(16, weight: .semibold))
                        Spacer()
                        if !viewModel.isPro {
                            Button("Upgrade") { showingPaywall = true }
                                .font(HeurikaFont.body(14, weight: .semibold))
                        }
                    }
                }
                .listRowBackground(HeurikaColor.parchmentDeep.opacity(0.5))

                Section {
                    NavigationLink {
                        ProviderSettingsView(viewModel: viewModel)
                    } label: {
                        Label("AI Provider & Keys", systemImage: "cpu")
                    }

                    Picker("Translate to", selection: Binding(
                        get: { viewModel.settings.translateTargetLanguage },
                        set: { viewModel.settings.translateTargetLanguage = $0; viewModel.persistSettings() }
                    )) {
                        ForEach(ProviderSettings.commonTranslateLanguages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                } header: {
                    Text("Deeds")
                }

                Section {
                    NavigationLink {
                        AIPrivacySettingsView()
                    } label: {
                        Label("AI Privacy & Consent", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        NotionSettingsView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Label("Notion Integration", systemImage: "doc.text.magnifyingglass")
                            Spacer()
                            if viewModel.settings.notionIntegrationTokenSet {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(HeurikaColor.sage)
                            } else if !viewModel.isPro {
                                ProSealBadge()
                            }
                        }
                    }
                } header: {
                    Text("Integrations")
                }

                Section {
                    LabeledContent("Version", value: appVersionString)
                    if let supportURL = AppConfiguration.supportURL {
                        Link(destination: supportURL) {
                            Label("Support", systemImage: "questionmark.circle")
                        }
                    }
                    if let privacyURL = AppConfiguration.privacyPolicyURL {
                        Link(destination: privacyURL) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                        }
                    }
                    if !AppConfiguration.missingLaunchValues.isEmpty {
                        NavigationLink {
                            ProductionReadinessView()
                        } label: {
                            Label("Production Setup Required", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(HeurikaColor.crimsonAccent)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .scrollContentBackground(.hidden)
            .background(HeurikaColor.parchment)
            .navigationTitle("Settings")
            .onAppear { viewModel.refresh() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct ProductionReadinessView: View {
    var body: some View {
        List {
            Section {
                ForEach(AppConfiguration.missingLaunchValues, id: \.self) { value in
                    Label(value, systemImage: "xmark.circle")
                        .foregroundStyle(HeurikaColor.crimsonAccent)
                }
            } header: {
                Text("Missing build configuration")
            } footer: {
                Text("Supply these values through an uncommitted xcconfig, CI secret-backed build settings, or App Store release configuration before archiving.")
            }
        }
        .navigationTitle("Production Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
