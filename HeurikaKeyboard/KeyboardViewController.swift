import UIKit
import SwiftUI
import HeurikaCore

final class KeyboardViewController: UIInputViewController {

    private var keyboardState: KeyboardState!
    private var hostingController: UIHostingController<KeyboardRootView>?
    private var deedExecutor: DeedExecutor!
    private let intentResolver = IntentResolver()
    private var lastShiftTapTime: Date?
    private var heightConstraint: NSLayoutConstraint?
    private let textChecker = UITextChecker()
    private var supplementaryLexiconEntries: [UILexiconEntry] = []

    // Approximate content height: 4 key rows (~48pt each incl. spacing) +
    // the action/status bar (~46pt) + vertical padding. Tune on-device if
    // key caps ever change size — see README "Tuning the keyboard height".
    private let preferredHeight: CGFloat = 258

    override func viewDidLoad() {
        super.viewDidLoad()

        keyboardState = KeyboardState(hasFullAccess: hasFullAccess, needsInputModeSwitchKey: needsInputModeSwitchKey)
        keyboardState.delegate = self
        deedExecutor = DeedExecutor()

        setUpHostingController()
        setUpHeightConstraint()
        loadSupplementaryLexicon()
        refreshTypingAssistance()

        if !SharedDefaults.shared.keyboardHasBeenActivated {
            SharedDefaults.shared.keyboardHasBeenActivated = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Full Access and the input-mode-switch requirement can both change
        // between appearances (e.g. the person just enabled Full Access and
        // switched back), so refresh rather than trusting viewDidLoad's snapshot.
        keyboardState.hasFullAccess = hasFullAccess
        keyboardState.needsInputModeSwitchKey = needsInputModeSwitchKey
        keyboardState.availableDeeds = DeedsRepository.shared.allIncludingBuiltIns()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // On devices with a home indicator (no physical home button), the
        // bottom safe area needs to be added on top of the key rows'
        // height, or the last row sits under the gesture area.
        heightConstraint?.constant = preferredHeight + view.safeAreaInsets.bottom
    }

    override func textWillChange(_ textInput: UITextInput?) {}

    override func textDidChange(_ textInput: UITextInput?) {
        keyboardState.returnKeyLabel = returnKeyLabel(for: textDocumentProxy.returnKeyType ?? .default)
        refreshTypingAssistance()
    }

    // MARK: - Layout

    private func setUpHostingController() {
        let hosting = UIHostingController(rootView: KeyboardRootView(state: keyboardState))
        hosting.view.backgroundColor = .clear
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting
    }

    private func setUpHeightConstraint() {
        // iOS also installs its own internal "UIView-Encapsulated-Layout-Height"
        // constraint on the extension's view. A .required-priority constraint
        // here is the standard way keyboard extensions fix their height, and
        // it wins, but it's normal to see a one-line Auto Layout conflict
        // notice in the console about it — it's diagnostic, not a real bug.
        let constraint = view.heightAnchor.constraint(equalToConstant: preferredHeight)
        constraint.priority = .required
        constraint.isActive = true
        heightConstraint = constraint
    }

    private func returnKeyLabel(for type: UIReturnKeyType) -> String {
        switch type {
        case .go: return "Go"
        case .google, .yahoo: return "Search"
        case .join: return "Join"
        case .next: return "Next"
        case .route: return "Route"
        case .search: return "Search"
        case .send: return "Send"
        case .done: return "Done"
        case .emergencyCall: return "SOS"
        case .continue: return "Continue"
        default: return "return"
        }
    }

    // MARK: - Native typing assistance

    private func loadSupplementaryLexicon() {
        requestSupplementaryLexicon { [weak self] lexicon in
            Task { @MainActor in
                self?.supplementaryLexiconEntries = lexicon.entries
                self?.refreshTypingAssistance()
            }
        }
    }

    private func refreshTypingAssistance() {
        updateAutomaticShift()
        updateSuggestions()
    }

    private func updateSuggestions() {
        guard keyboardState.layer == .letters else {
            keyboardState.suggestions = []
            return
        }
        let word = TextContextReader.currentWord(from: textDocumentProxy)
        guard word.count >= 2 else {
            keyboardState.suggestions = []
            return
        }

        let language = textDocumentProxy.documentInputMode?.primaryLanguage ?? primaryLanguage ?? "en-US"
        let range = NSRange(location: 0, length: (word as NSString).length)
        var candidates: [String] = []
        let misspelled = textChecker.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: language
        )
        if misspelled.location != NSNotFound {
            candidates.append(contentsOf: textChecker.guesses(forWordRange: misspelled, in: word, language: language) ?? [])
        }
        candidates.append(contentsOf: textChecker.completions(forPartialWordRange: range, in: word, language: language) ?? [])
        candidates.append(contentsOf: supplementaryLexiconEntries.compactMap { entry in
            entry.userInput.range(of: word, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) != nil ? entry.documentText : nil
        })

        var seen = Set<String>()
        keyboardState.suggestions = candidates.filter { candidate in
            guard candidate.caseInsensitiveCompare(word) != .orderedSame else { return false }
            return seen.insert(candidate.lowercased()).inserted
        }.prefix(3).map { $0 }
    }

    private func updateAutomaticShift() {
        guard keyboardState.layer == .letters, !keyboardState.isCapsLocked else { return }
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        guard let autocapitalizationType = textDocumentProxy.autocapitalizationType else {
            keyboardState.isShifted = false
            return
        }
        let shouldShift: Bool
        switch autocapitalizationType {
        case .none:
            shouldShift = false
        case .allCharacters:
            shouldShift = true
        case .words:
            shouldShift = before.isEmpty || before.last?.isWhitespace == true
        case .sentences:
            let trimmed = before.trimmingCharacters(in: .whitespaces)
            shouldShift = trimmed.isEmpty || trimmed.last.map { ".!?\n".contains($0) } == true
        @unknown default:
            shouldShift = false
        }
        keyboardState.isShifted = shouldShift
    }

    private func refreshTypingAssistanceAfterEdit() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshTypingAssistance()
        }
    }

    // MARK: - Deed execution

    private func runDeed(_ deed: Deed) {
        guard hasFullAccess else {
            keyboardState.showStatus("Enable Full Access to use Deeds")
            return
        }
        let context = TextContextReader.currentContext(from: textDocumentProxy)
        guard !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            keyboardState.showStatus("Type something first")
            return
        }

        keyboardState.isBusy = true
        Task {
            do {
                let outcome = try await deedExecutor.execute(deed: deed, context: context)
                apply(outcome)
            } catch let error as AIActionError {
                keyboardState.showStatus(error.friendlyMessage)
            } catch {
                keyboardState.showStatus("Something went wrong — try again")
            }
            keyboardState.isBusy = false
        }
    }

    private func runHeurika() {
        guard hasFullAccess else {
            keyboardState.showStatus("Enable Full Access to use Heurika")
            return
        }
        let context = TextContextReader.currentContext(from: textDocumentProxy)
        guard !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            keyboardState.showStatus("Type something, then tap Heurika")
            return
        }

        keyboardState.isBusy = true
        Task {
            do {
                let resolution = try await intentResolver.resolve(typedText: context)
                switch resolution.resolution {
                case .rewrite:
                    let deed = resolution.deedID
                        .flatMap { id in keyboardState.availableDeeds.first(where: { $0.id == id && $0.kind == .rewrite }) }
                        ?? BuiltInDeeds.polish
                    let outcome = try await deedExecutor.execute(deed: deed, context: context, resolvedQuery: resolution.query)
                    apply(outcome)
                case .act:
                    guard let deedID = resolution.deedID,
                          let deed = keyboardState.availableDeeds.first(where: { $0.id == deedID }) else {
                        keyboardState.showStatus("Not sure what you meant")
                        keyboardState.isBusy = false
                        return
                    }
                    let outcome = try await deedExecutor.execute(deed: deed, context: context, resolvedQuery: resolution.query ?? context)
                    apply(outcome)
                case .unclear:
                    keyboardState.showStatus(resolution.reasoning ?? "Not sure what you meant")
                }
            } catch let error as AIActionError {
                keyboardState.showStatus(error.friendlyMessage)
            } catch {
                keyboardState.showStatus("Something went wrong — try again")
            }
            keyboardState.isBusy = false
        }
    }

    @MainActor
    private func apply(_ outcome: DeedExecutionOutcome) {
        switch outcome {
        case .replaceText(let newText, let originalLength):
            replaceContext(originalLength: originalLength, with: newText)
        case .insertText(let text):
            textDocumentProxy.insertText(text)
        case .copiedToClipboard:
            keyboardState.showStatus("Copied")
        }
    }

    /// Backspaces exactly the number of grapheme clusters that were sent to
    /// the model, then inserts the result. `deleteBackward()` removes one
    /// extended grapheme cluster per call in the same way the system
    /// backspace does, which is what `String.count` also measures — so this
    /// lines up correctly for the overwhelming majority of text. The one
    /// acknowledged edge case is certain exotic ZWJ emoji sequences where
    /// the two can diverge by a character or two; see README → "Known
    /// limitations" rather than this being silently assumed perfect.
    private func replaceContext(originalLength: Int, with newText: String) {
        for _ in 0..<originalLength {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(newText)
    }

    // MARK: - Shift / caps lock

    private func handleShiftTap() {
        let now = Date()
        if let last = lastShiftTapTime, now.timeIntervalSince(last) < 0.32 {
            keyboardState.isCapsLocked.toggle()
            keyboardState.isShifted = keyboardState.isCapsLocked
        } else if keyboardState.isCapsLocked {
            keyboardState.isCapsLocked = false
            keyboardState.isShifted = false
        } else {
            keyboardState.isShifted.toggle()
        }
        lastShiftTapTime = now
    }
}

// MARK: - KeyboardStateDelegate

extension KeyboardViewController: KeyboardStateDelegate {

    func keyboardDidTapKey(_ key: KeyboardKey) {
        switch key {
        case .character(let text):
            textDocumentProxy.insertText(text)
            if keyboardState.isShifted && !keyboardState.isCapsLocked {
                keyboardState.isShifted = false
            }
            refreshTypingAssistanceAfterEdit()
        case .backspace:
            textDocumentProxy.deleteBackward()
            refreshTypingAssistanceAfterEdit()
        case .space:
            textDocumentProxy.insertText(" ")
            refreshTypingAssistanceAfterEdit()
        case .returnKey:
            textDocumentProxy.insertText("\n")
            refreshTypingAssistanceAfterEdit()
        case .shift:
            handleShiftTap()
        case .switchToNumbers:
            keyboardState.layer = .numbers
            keyboardState.suggestions = []
        case .switchToSymbols:
            keyboardState.layer = .symbols
            keyboardState.suggestions = []
        case .switchToLetters:
            keyboardState.layer = .letters
            refreshTypingAssistance()
        case .globe:
            break
        }
    }

    func keyboardDidTapDeedChip(_ deed: Deed) {
        runDeed(deed)
    }

    func keyboardDidTapHeurika() {
        runHeurika()
    }

    func keyboardDidTapSuggestion(_ suggestion: String) {
        let word = TextContextReader.currentWord(from: textDocumentProxy)
        guard !word.isEmpty else { return }
        replaceContext(originalLength: word.count, with: suggestion)
        refreshTypingAssistanceAfterEdit()
    }

    func keyboardDidTapGlobe() {
        advanceToNextInputMode()
    }
}
