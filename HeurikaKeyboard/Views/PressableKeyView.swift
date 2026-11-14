import SwiftUI
import HeurikaCore

/// A standard keyboard key. Agent actions intentionally live in the dedicated
/// action row instead of changing the behavior of letters, space, or return.
struct PressableKeyView<Label: View>: View {
    let onTap: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: onTap) {
            label()
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableKeyButtonStyle())
    }
}

private struct PressableKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.08 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
