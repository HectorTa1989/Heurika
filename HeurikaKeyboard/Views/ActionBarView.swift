import SwiftUI
import HeurikaCore

struct ActionBarView: View {
    @ObservedObject var state: KeyboardState

    var body: some View {
        VStack(spacing: 2) {
            if let message = state.statusMessage {
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HeurikaColor.espressoSoft)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(state.suggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            state.delegate?.keyboardDidTapSuggestion(suggestion)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HeurikaColor.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(HeurikaColor.parchmentDeep, in: Capsule())
                        .accessibilityLabel("Replace current word with \(suggestion)")
                    }

                    if state.hasFullAccess {
                        Button {
                            state.delegate?.keyboardDidTapHeurika()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: state.isBusy ? "hourglass" : "sparkles")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(state.isBusy ? "Working…" : "Heurika")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(HeurikaColor.ink)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(HeurikaColor.goldGradient, in: Capsule())
                        }
                        .disabled(state.isBusy)
                        .accessibilityLabel("Run Heurika on the text before the cursor")

                        ForEach(state.availableDeeds) { deed in
                            Button {
                                state.delegate?.keyboardDidTapDeedChip(deed)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: deed.symbol)
                                        .font(.system(size: 11, weight: .medium))
                                    Text(deed.name)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(HeurikaColor.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.6), in: Capsule())
                            }
                            .disabled(state.isBusy)
                            .accessibilityLabel("Run \(deed.name)")
                        }
                    } else if state.suggestions.isEmpty {
                        Text("Enable Full Access for AI Deeds")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(HeurikaColor.espressoSoft)
                            .padding(.horizontal, 10)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: 40)
        .animation(.easeInOut(duration: 0.2), value: state.statusMessage)
    }
}
