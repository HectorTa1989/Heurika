import SwiftUI
import HeurikaCore

/// The circular gold-ringed icon badge used everywhere a Deed is listed —
/// Home's quick row, the Deeds tab, the Deed editor preview.
struct DeedIconBadge: View {
    let symbol: String
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(HeurikaColor.parchmentDeep)
            Circle()
                .strokeBorder(HeurikaColor.antiqueGold.opacity(0.5), lineWidth: 1.5)
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(HeurikaColor.espresso)
        }
        .frame(width: size, height: size)
    }
}

/// Small "PRO" wax-seal-style badge, used next to Pro-gated rows.
struct ProSealBadge: View {
    var body: some View {
        Text("PRO")
            .font(HeurikaFont.body(10, weight: .bold))
            .tracking(1)
            .foregroundStyle(HeurikaColor.parchment)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(HeurikaColor.crimsonAccent, in: Capsule())
    }
}

#Preview {
    HStack(spacing: 12) {
        DeedIconBadge(symbol: "checkmark.seal")
        DeedIconBadge(symbol: "globe")
        ProSealBadge()
    }
    .padding()
    .background(HeurikaColor.parchment)
}
