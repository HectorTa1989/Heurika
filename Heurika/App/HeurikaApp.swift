import SwiftUI
import HeurikaCore

@main
struct HeurikaApp: App {
    @StateObject private var purchasesManager = PurchasesManager.shared

    init() {
        PurchasesManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(purchasesManager)
                .tint(HeurikaColor.espresso)
        }
    }
}
