import SwiftUI
import HeurikaCore

/// A labeled text field styled to match the parchment/espresso/gold system.
/// Used anywhere the person enters a name, instruction, or API key.
struct VintageTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: HeurikaTheme.Spacing.xs) {
            Text(label.uppercased())
                .font(HeurikaFont.caption)
                .foregroundStyle(HeurikaColor.espressoSoft)
                .tracking(0.6)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else if axis == .vertical {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(HeurikaFont.body(16))
            .foregroundStyle(HeurikaColor.ink)
            .padding(.horizontal, HeurikaTheme.Spacing.md)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: HeurikaTheme.Radius.sm, style: .continuous)
                    .fill(Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: HeurikaTheme.Radius.sm, style: .continuous)
                    .strokeBorder(HeurikaColor.antiqueGold.opacity(0.3), lineWidth: 1)
            )
            .autocorrectionDisabled(isSecure)
            #if os(iOS)
            .textInputAutocapitalization(isSecure ? .never : .sentences)
            #endif
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        VintageTextField(label: "Deed name", text: .constant(""), placeholder: "Polite Decline")
        VintageTextField(label: "Groq API key", text: .constant(""), placeholder: "gsk_...", isSecure: true)
    }
    .padding()
    .background(HeurikaColor.parchment)
}
