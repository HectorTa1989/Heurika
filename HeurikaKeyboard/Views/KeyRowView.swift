import SwiftUI
import HeurikaCore

struct KeyRowView: View {
    let keys: [KeyboardKey]
    @ObservedObject var state: KeyboardState

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                keyView(for: key)
            }
        }
    }

    @ViewBuilder
    private func keyView(for key: KeyboardKey) -> some View {
        switch key {
        case .character(let text):
            letterKey(text)

        case .backspace:
            PressableKeyView(onTap: { state.delegate?.keyboardDidTapKey(.backspace) }) {
                KeyCapView(content: .symbol("delete.left"))
            }
            .frame(width: 40)

        case .shift:
            PressableKeyView(onTap: { state.delegate?.keyboardDidTapKey(.shift) }) {
                KeyCapView(content: .symbol(state.isCapsLocked ? "capslock.fill" : (state.isShifted ? "shift.fill" : "shift")), isActive: state.isShifted || state.isCapsLocked)
            }
            .frame(width: 40)

        case .space:
            PressableKeyView(onTap: { state.delegate?.keyboardDidTapKey(.space) }) {
                KeyCapView(content: .text("space"))
            }
            .frame(maxWidth: .infinity)

        case .returnKey:
            PressableKeyView(onTap: { state.delegate?.keyboardDidTapKey(.returnKey) }) {
                KeyCapView(content: .text(state.returnKeyLabel))
            }
            .frame(width: 84)

        case .switchToNumbers:
            PressableKeyView(onTap: { state.delegate?.keyboardDidTapKey(.switchToNumbers) }) {
                KeyCapView(content: .text("123"))
            }
            .frame(width: 44)

        case .switchToSymbols:
            PressableKeyView(onTap: { state.delegate?.keyboardDidTapKey(.switchToSymbols) }) {
                KeyCapView(content: .text("#+="))
            }
            .frame(width: 44)

        case .switchToLetters:
            PressableKeyView(onTap: { state.delegate?.keyboardDidTapKey(.switchToLetters) }) {
                KeyCapView(content: .text("ABC"))
            }
            .frame(width: 44)

        case .globe:
            if state.needsInputModeSwitchKey {
                PressableKeyView(onTap: { state.delegate?.keyboardDidTapGlobe() }) {
                    KeyCapView(content: .symbol("globe"))
                }
                .frame(width: 40)
            }
        }
    }

    private func letterKey(_ text: String) -> some View {
        PressableKeyView(onTap: { state.delegate?.keyboardDidTapKey(.character(text)) }) {
            KeyCapView(content: .text(text))
        }
    }
}
