import SwiftUI
import HeurikaCore

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HeurikaTheme.Spacing.lg) {
                    header

                    if !viewModel.isKeyboardActivated {
                        keyboardNotSetUpBanner
                    }

                    statusRow

                    scratchpadSection

                    quickDeedsSection
                }
                .padding(HeurikaTheme.Spacing.lg)
            }
            .background(HeurikaColor.parchmentGradient.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear { viewModel.refresh() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Heurika")
                    .font(HeurikaFont.display(30, weight: .bold))
                    .foregroundStyle(HeurikaColor.ink)
                Text("Type naturally. Tap when you want help.")
                    .font(HeurikaFont.quote)
                    .foregroundStyle(HeurikaColor.espressoSoft)
            }
            Spacer()
            if !viewModel.isPro {
                Button {
                    showingPaywall = true
                } label: {
                    Text("Upgrade")
                        .font(HeurikaFont.body(13, weight: .bold))
                        .foregroundStyle(HeurikaColor.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(HeurikaColor.goldGradient, in: Capsule())
                }
            }
        }
        .padding(.top, HeurikaTheme.Spacing.sm)
    }

    private var keyboardNotSetUpBanner: some View {
        HStack(spacing: HeurikaTheme.Spacing.md) {
            Image(systemName: "keyboard.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(HeurikaColor.crimsonAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Keyboard not detected yet")
                    .font(HeurikaFont.body(15, weight: .semibold))
                Text("Open Settings › Keyboards to add Heurika")
                    .font(HeurikaFont.caption)
                    .foregroundStyle(HeurikaColor.espressoSoft)
            }
            Spacer()
        }
        .heurikaCard(padding: HeurikaTheme.Spacing.md)
    }

    private var statusRow: some View {
        HStack(spacing: HeurikaTheme.Spacing.md) {
            statCard(
                title: viewModel.isPro ? "Unlimited" : "\(viewModel.remainingFreeToday)/\(HeurikaConstants.freeDailyDeedLimit)",
                subtitle: viewModel.isPro ? "Deeds today · Pro" : "free Deeds left today"
            )
            statCard(
                title: viewModel.isKeyboardActivated ? "Active" : "Not set up",
                subtitle: "Heurika keyboard"
            )
        }
    }

    private func statCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(HeurikaFont.display(20, weight: .semibold))
                .foregroundStyle(HeurikaColor.ink)
            Text(subtitle)
                .font(HeurikaFont.caption)
                .foregroundStyle(HeurikaColor.espressoSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .heurikaCard(padding: HeurikaTheme.Spacing.md)
    }

    private var scratchpadSection: some View {
        VStack(alignment: .leading, spacing: HeurikaTheme.Spacing.sm) {
            Text("Scratchpad")
                .font(HeurikaFont.sectionHeader)
                .foregroundStyle(HeurikaColor.ink)
            Text("Try a Deed here before you trust it in a real conversation.")
                .font(HeurikaFont.caption)
                .foregroundStyle(HeurikaColor.espressoSoft)

            TextField("Type something…", text: $viewModel.scratchpadText, axis: .vertical)
                .accessibilityIdentifier("previewScratchpad")
                .lineLimit(3...6)
                .font(HeurikaFont.body(16))
                .padding(HeurikaTheme.Spacing.md)
                .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: HeurikaTheme.Radius.sm))
                .overlay(RoundedRectangle(cornerRadius: HeurikaTheme.Radius.sm).strokeBorder(HeurikaColor.antiqueGold.opacity(0.3)))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HeurikaTheme.Spacing.sm) {
                    ForEach(BuiltInDeeds.rewrites) { deed in
                        deedChip(deed)
                    }
                }
            }

            if viewModel.isRunningScratchpad {
                ProgressView().padding(.vertical, HeurikaTheme.Spacing.sm)
            } else if let result = viewModel.scratchpadResult {
                Text(result)
                    .font(HeurikaFont.body(15))
                    .foregroundStyle(HeurikaColor.ink)
                    .padding(HeurikaTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HeurikaColor.parchmentDeep, in: RoundedRectangle(cornerRadius: HeurikaTheme.Radius.sm))
            } else if let error = viewModel.scratchpadError {
                Text(error)
                    .font(HeurikaFont.caption)
                    .foregroundStyle(HeurikaColor.crimsonAccent)
            }
        }
        .heurikaCard()
    }

    private func deedChip(_ deed: Deed) -> some View {
        Button {
            viewModel.selectedDeed = deed
            viewModel.scratchpadResult = nil
            viewModel.scratchpadError = nil
            viewModel.runScratchpad()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: deed.symbol)
                Text(deed.name)
            }
            .font(HeurikaFont.body(13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                viewModel.selectedDeed.id == deed.id ? AnyShapeStyle(HeurikaColor.goldGradient) : AnyShapeStyle(HeurikaColor.parchmentDeep),
                in: Capsule()
            )
            .foregroundStyle(HeurikaColor.ink)
        }
    }

    private var quickDeedsSection: some View {
        VStack(alignment: .leading, spacing: HeurikaTheme.Spacing.sm) {
            Text("Built-in Deeds")
                .font(HeurikaFont.sectionHeader)
                .foregroundStyle(HeurikaColor.ink)

            VStack(spacing: 1) {
                ForEach(BuiltInDeeds.all) { deed in
                    HStack(spacing: HeurikaTheme.Spacing.md) {
                        DeedIconBadge(symbol: deed.symbol, size: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(deed.name)
                                .font(HeurikaFont.body(15, weight: .medium))
                            Text(deed.kind == .rewrite ? "Rewrites your text" : "Inserts a link or action result")
                                .font(HeurikaFont.caption)
                                .foregroundStyle(HeurikaColor.espressoSoft)
                        }
                        Spacer()
                    }
                    .padding(.vertical, HeurikaTheme.Spacing.sm)
                }
            }
            .heurikaCard(padding: HeurikaTheme.Spacing.md)
        }
    }
}

#Preview {
    HomeView()
}
