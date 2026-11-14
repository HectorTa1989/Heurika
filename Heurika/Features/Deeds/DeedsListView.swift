import SwiftUI
import UniformTypeIdentifiers
import HeurikaCore

struct DeedsListView: View {
    @StateObject private var viewModel = DeedsViewModel()
    @State private var showingEditor = false
    @State private var editingDeed: Deed?
    @State private var showingPaywall = false
    @State private var showingImporter = false
    @State private var shareURL: IdentifiableURL?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if viewModel.customDeeds.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.customDeeds) { deed in
                            deedRow(deed)
                        }
                    }
                } header: {
                    Text("Your Deeds")
                } footer: {
                    Text("Custom Deeds need Heurika Pro. Free plan gets all \(BuiltInDeeds.all.count) built-ins, unlimited.")
                }

            }
            .scrollContentBackground(.hidden)
            .background(HeurikaColor.parchment)
            .navigationTitle("Deeds")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            addNewDeed()
                        } label: {
                            Label("New Deed", systemImage: "plus")
                        }
                        Button {
                            showingImporter = true
                        } label: {
                            Label("Import Deed File", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .onAppear { viewModel.refresh() }
            .sheet(isPresented: $showingEditor) {
                DeedEditorView(existingDeed: editingDeed, onSave: { deed in
                    viewModel.save(deed)
                })
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(item: $shareURL) { item in
                ActivityShareSheet(activityItems: [item.url])
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                if case .success(let url) = result {
                    viewModel.importDeeds(from: url)
                }
            }
            .alert("Import Failed", isPresented: .constant(viewModel.importError != nil), actions: {
                Button("OK") { viewModel.importError = nil }
            }, message: {
                Text(viewModel.importError ?? "")
            })
        }
    }

    private var emptyState: some View {
        VStack(spacing: HeurikaTheme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(HeurikaColor.antiqueGold)
            Text("No custom Deeds yet")
                .font(HeurikaFont.body(15, weight: .semibold))
            Text("Describe one in plain English and Heurika drafts it for you.")
                .font(HeurikaFont.caption)
                .foregroundStyle(HeurikaColor.espressoSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HeurikaTheme.Spacing.lg)
        .listRowBackground(Color.clear)
    }

    private func deedRow(_ deed: Deed) -> some View {
        HStack(spacing: HeurikaTheme.Spacing.md) {
            DeedIconBadge(symbol: deed.symbol, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(deed.name).font(HeurikaFont.body(15, weight: .medium))
                Text(deed.kind == .rewrite ? (deed.instruction ?? "") : "Inserts a link or result")
                    .font(HeurikaFont.caption)
                    .foregroundStyle(HeurikaColor.espressoSoft)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                if let url = viewModel.exportForSharing(deed) {
                    shareURL = IdentifiableURL(url: url)
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(HeurikaColor.espressoSoft)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingDeed = deed
            showingEditor = true
        }
        .swipeActions {
            Button(role: .destructive) {
                viewModel.delete(deed)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .listRowBackground(HeurikaColor.parchmentDeep.opacity(0.4))
    }

    private func addNewDeed() {
        if !viewModel.isPro && !viewModel.customDeeds.isEmpty {
            showingPaywall = true
            return
        }
        editingDeed = nil
        showingEditor = true
    }
}

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// Thin SwiftUI wrapper around UIActivityViewController for the system share sheet.
private struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DeedsListView()
}
