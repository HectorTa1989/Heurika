import Foundation
import HeurikaCore

/// Everything the SwiftUI keyboard view hierarchy needs to render. Owned by
/// `KeyboardViewController`, which is the only thing that mutates it in
/// response to real UIKit events (text changes, trait changes). Keeping this
/// as a plain ObservableObject — rather than making the view controller
/// itself the `@Published` source — means the SwiftUI views never see
/// `UIInputViewController` at all.
@MainActor
final class KeyboardState: ObservableObject {
    @Published var layer: KeyboardLayer = .letters
    @Published var isShifted = false
    @Published var isCapsLocked = false
    @Published var isBusy = false
    @Published var statusMessage: String?
    @Published var hasFullAccess: Bool
    @Published var needsInputModeSwitchKey: Bool
    @Published var returnKeyLabel: String = "return"
    @Published var availableDeeds: [Deed]
    @Published var suggestions: [String] = []

    weak var delegate: KeyboardStateDelegate?

    init(hasFullAccess: Bool, needsInputModeSwitchKey: Bool) {
        self.hasFullAccess = hasFullAccess
        self.needsInputModeSwitchKey = needsInputModeSwitchKey
        self.availableDeeds = DeedsRepository.shared.allIncludingBuiltIns()
    }

    func showStatus(_ message: String, autoDismissAfter seconds: Double = 2.5) {
        statusMessage = message
        let token = UUID()
        currentStatusToken = token
        Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if currentStatusToken == token {
                statusMessage = nil
            }
        }
    }

    private var currentStatusToken: UUID?
}

/// The narrow surface `KeyboardViewController` implements so SwiftUI code
/// never touches `UITextDocumentProxy` directly.
@MainActor
protocol KeyboardStateDelegate: AnyObject {
    func keyboardDidTapKey(_ key: KeyboardKey)
    func keyboardDidTapDeedChip(_ deed: Deed)
    func keyboardDidTapHeurika()
    func keyboardDidTapSuggestion(_ suggestion: String)
    func keyboardDidTapGlobe()
}
