import SwiftUI
import HeurikaCore

/// The visual key cap. Text stays on the system font deliberately — see
/// HeurikaFont's doc comment for why custom serif faces aren't used here:
/// legibility at ~15pt and the extension's memory budget both favor it.
struct KeyCapView: View {
    let content: KeyCapContent
    var isActive = false

    var body: some View {
        Group {
            switch content {
            case .text(let text):
                Text(text)
                    .font(.system(size: 20, weight: .regular))
            case .symbol(let name):
                Image(systemName: name)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .foregroundStyle(HeurikaColor.ink)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isActive ? HeurikaColor.antiqueGold.opacity(0.55) : Color.white.opacity(0.7))
        )
        .shadow(color: .black.opacity(0.15), radius: 0.5, y: 1)
    }
}

enum KeyCapContent {
    case text(String)
    case symbol(String)
}
