import SwiftUI
import HeurikaCore

struct KeyboardRootView: View {
    @ObservedObject var state: KeyboardState

    var body: some View {
        VStack(spacing: 6) {
            ActionBarView(state: state)

            ForEach(Array(KeyboardLayoutProvider.rows(for: state.layer, shifted: state.isShifted || state.isCapsLocked).enumerated()), id: \.offset) { _, row in
                KeyRowView(keys: row, state: state)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .background(HeurikaColor.parchment)
        .opacity(state.isBusy ? 0.85 : 1.0)
    }
}
