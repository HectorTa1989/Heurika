import Foundation
import HeurikaCore

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isKeyboardActivated = SharedDefaults.shared.keyboardHasBeenActivated
    @Published var remainingFreeToday = UsageTracker.shared.remainingFreeActionsToday()
    @Published var isPro = SharedDefaults.shared.subscriptionStatus.effectiveIsPro

    @Published var scratchpadText = ""
    @Published var scratchpadResult: String?
    @Published var scratchpadError: String?
    @Published var isRunningScratchpad = false
    @Published var selectedDeed: Deed = BuiltInDeeds.rewrites[0]

    let quickDeeds: [Deed] = Array(BuiltInDeeds.rewrites.prefix(4))
    private let actionService = AIActionService()

    func refresh() {
        isKeyboardActivated = SharedDefaults.shared.keyboardHasBeenActivated
        remainingFreeToday = UsageTracker.shared.remainingFreeActionsToday()
        isPro = SharedDefaults.shared.subscriptionStatus.effectiveIsPro
    }

    func runScratchpad() {
        guard !scratchpadText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        scratchpadError = nil
        isRunningScratchpad = true
        Task {
            do {
                let result = try await actionService.runRewrite(deed: selectedDeed, inputText: scratchpadText)
                scratchpadResult = result
            } catch let error as AIActionError {
                scratchpadError = error.friendlyMessage
            } catch {
                scratchpadError = "Something went wrong — try again"
            }
            isRunningScratchpad = false
            refresh()
        }
    }
}
