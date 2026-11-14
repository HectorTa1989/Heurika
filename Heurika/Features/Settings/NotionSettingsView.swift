import SwiftUI
import HeurikaCore

struct NotionSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Text("The Notion Search Deed calls Notion's real Search API with your own integration token — it only sees pages you've explicitly shared with that integration inside Notion.")
                    .font(HeurikaFont.caption)
                    .foregroundStyle(HeurikaColor.espressoSoft)
            }

            Section("Setup") {
                stepRow(1, "Go to notion.so/my-integrations and create an Internal Integration")
                stepRow(2, "Copy its token and paste it below")
                stepRow(3, "In Notion, share the pages you want searchable with that integration")
            }

            Section("Integration Token") {
                if viewModel.settings.notionIntegrationTokenSet {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(HeurikaColor.sage)
                        Text("Token saved")
                        Spacer()
                        Button("Remove", role: .destructive) {
                            viewModel.clearNotionToken()
                        }
                        .font(HeurikaFont.caption)
                    }
                } else {
                    SecureField("secret_...", text: $viewModel.notionToken)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    Button("Save Token") { viewModel.saveNotionToken() }
                }

                Link(destination: URL(string: "https://www.notion.so/my-integrations")!) {
                    Label("Open notion.so/my-integrations", systemImage: "arrow.up.forward")
                }
                .font(HeurikaFont.caption)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HeurikaColor.parchment)
        .navigationTitle("Notion")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.refresh() }
    }

    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: HeurikaTheme.Spacing.sm) {
            Text("\(number)")
                .font(HeurikaFont.body(12, weight: .bold))
                .foregroundStyle(HeurikaColor.parchment)
                .frame(width: 20, height: 20)
                .background(HeurikaColor.espresso, in: Circle())
            Text(text)
                .font(HeurikaFont.body(14))
                .foregroundStyle(HeurikaColor.espressoSoft)
        }
    }
}

#Preview {
    NavigationStack {
        NotionSettingsView(viewModel: SettingsViewModel())
    }
}
