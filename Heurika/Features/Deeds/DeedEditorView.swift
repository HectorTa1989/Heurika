import SwiftUI
import HeurikaCore

/// Creates or edits a custom Deed. Rewrite Deeds can be drafted with AI from
/// a plain-English description; act Deeds are configured directly (name +
/// URL template) since that's simple enough not to need a model call — see
/// `DeedBuilderAssistant` for why AI-assist is scoped to rewrites only.
struct DeedEditorView: View {
    let existingDeed: Deed?
    /// Returns nil on success, or an error to display inline without dismissing.
    let onSave: (Deed) -> DeedsRepositoryError?

    @Environment(\.dismiss) private var dismiss
    @State private var kind: Deed.Kind
    @State private var name: String
    @State private var symbol: String
    @State private var instruction: String
    @State private var urlTemplate: String
    @State private var aiDescription = ""
    @State private var isDrafting = false
    @State private var draftError: String?
    @State private var saveError: String?

    init(existingDeed: Deed?, onSave: @escaping (Deed) -> DeedsRepositoryError?) {
        self.existingDeed = existingDeed
        self.onSave = onSave
        _kind = State(initialValue: existingDeed?.kind ?? .rewrite)
        _name = State(initialValue: existingDeed?.name ?? "")
        _symbol = State(initialValue: existingDeed?.symbol ?? "sparkles")
        _instruction = State(initialValue: existingDeed?.instruction ?? "")
        if case .openURLTemplate(let template) = existingDeed?.actPayload {
            _urlTemplate = State(initialValue: template)
        } else {
            _urlTemplate = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if existingDeed == nil {
                    Section {
                        Picker("Type", selection: $kind) {
                            Text("Rewrite text").tag(Deed.Kind.rewrite)
                            Text("Insert a link").tag(Deed.Kind.act)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                if kind == .rewrite {
                    aiAssistSection
                }

                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("SF Symbol name", text: $symbol)
                    HStack {
                        Text("Preview")
                        Spacer()
                        DeedIconBadge(symbol: symbol.isEmpty ? "questionmark" : symbol, size: 32)
                    }
                }

                if kind == .rewrite {
                    Section("Instruction") {
                        TextField("How should it rewrite text?", text: $instruction, axis: .vertical)
                            .lineLimit(3...8)
                    }
                } else {
                    Section("Link Template") {
                        TextField("https://example.com/search?q={query}", text: $urlTemplate, axis: .vertical)
                            .lineLimit(2...4)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                        Text("Use {query} where the resolved search text should go.")
                            .font(HeurikaFont.caption)
                            .foregroundStyle(HeurikaColor.espressoSoft)
                    }
                }

                if let saveError {
                    Section {
                        Text(saveError)
                            .font(HeurikaFont.caption)
                            .foregroundStyle(HeurikaColor.crimsonAccent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HeurikaColor.parchment)
            .navigationTitle(existingDeed == nil ? "New Deed" : "Edit Deed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var aiAssistSection: some View {
        Section("Draft with AI") {
            TextField("Describe it: \"When I say draft a decline, write a polite meeting decline\"", text: $aiDescription, axis: .vertical)
                .lineLimit(2...4)

            Button {
                runAIDraft()
            } label: {
                HStack {
                    if isDrafting { ProgressView() }
                    Text(isDrafting ? "Drafting…" : "Draft with AI")
                }
            }
            .disabled(isDrafting || aiDescription.trimmingCharacters(in: .whitespaces).isEmpty)

            if let draftError {
                Text(draftError)
                    .font(HeurikaFont.caption)
                    .foregroundStyle(HeurikaColor.crimsonAccent)
            }
        }
    }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if kind == .rewrite {
            return !instruction.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            return Self.validHTTPSURLTemplate(urlTemplate)
        }
    }

    private func runAIDraft() {
        isDrafting = true
        draftError = nil
        Task {
            do {
                let draft = try await DeedBuilderAssistant().draft(from: aiDescription)
                name = draft.name
                symbol = draft.symbol
                instruction = draft.instruction
            } catch let error as AIActionError {
                draftError = error.friendlyMessage
            } catch {
                draftError = "Couldn't draft that — try rephrasing"
            }
            isDrafting = false
        }
    }

    private func save() {
        var deed = existingDeed ?? Deed(name: name, symbol: symbol, kind: kind, isBuiltIn: false)
        deed.name = name.trimmingCharacters(in: .whitespaces)
        deed.symbol = symbol.trimmingCharacters(in: .whitespaces)
        deed.kind = kind
        if kind == .rewrite {
            deed.instruction = instruction
            deed.actPayload = nil
        } else {
            deed.instruction = nil
            deed.actPayload = .openURLTemplate(template: urlTemplate.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        if let error = onSave(deed) {
            saveError = error.friendlyMessage
        } else {
            dismiss()
        }
    }

    private static func validHTTPSURLTemplate(_ template: String) -> Bool {
        let trimmed = template.trimmingCharacters(in: .whitespacesAndNewlines)
        let sample = trimmed.replacingOccurrences(of: "{query}", with: "sample")
        guard let components = URLComponents(string: sample),
              components.scheme?.lowercased() == "https",
              components.host != nil else { return false }
        return !trimmed.contains("\n") && !trimmed.contains("\r")
    }
}

#Preview {
    DeedEditorView(existingDeed: nil, onSave: { _ in nil })
}
