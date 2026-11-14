import SwiftUI
import RevenueCat
import HeurikaCore

struct PaywallView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HeurikaTheme.Spacing.lg) {
                    header
                    featureList

                    if !viewModel.isConfigured {
                        Text("Subscriptions are not configured for this build.")
                            .font(HeurikaFont.caption)
                            .foregroundStyle(HeurikaColor.crimsonAccent)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else if viewModel.isLoading {
                        ProgressView().padding(.vertical, HeurikaTheme.Spacing.xl)
                    } else if viewModel.packages.isEmpty {
                        Text("Subscription options aren't available right now — check your connection and try again.")
                            .font(HeurikaFont.caption)
                            .foregroundStyle(HeurikaColor.espressoSoft)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        packageOptions
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(HeurikaFont.caption)
                            .foregroundStyle(HeurikaColor.crimsonAccent)
                            .multilineTextAlignment(.center)
                    }

                    VintageButton(
                        title: viewModel.isPurchasing ? "Please wait…" : "Unlock Heurika Pro",
                        systemImage: "seal",
                        isLoading: viewModel.isPurchasing
                    ) {
                        Task {
                            if await viewModel.purchase() { dismiss() }
                        }
                    }
                    .disabled(!viewModel.isConfigured || viewModel.selectedPackage == nil || viewModel.isPurchasing)

                    Button("Restore Purchases") {
                        Task {
                            if await viewModel.restore() { dismiss() }
                        }
                    }
                    .disabled(!viewModel.isConfigured || viewModel.isPurchasing)
                    .font(HeurikaFont.caption)
                    .foregroundStyle(HeurikaColor.espressoSoft)

                    legalLinks
                }
                .padding(HeurikaTheme.Spacing.lg)
            }
            .background(HeurikaColor.parchmentGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { viewModel.onAppear() }
        }
    }

    private var header: some View {
        VStack(spacing: HeurikaTheme.Spacing.sm) {
            Image(systemName: "seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(HeurikaColor.antiqueGold)
            Text("Heurika Pro")
                .font(HeurikaFont.display(30, weight: .bold))
                .foregroundStyle(HeurikaColor.ink)
            Text("Unlimited Deeds, every provider, your own Deed Builder.")
                .font(HeurikaFont.body(15))
                .foregroundStyle(HeurikaColor.espressoSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, HeurikaTheme.Spacing.md)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: HeurikaTheme.Spacing.sm) {
            featureRow("infinity", "Unlimited Deeds every day")
            featureRow("cpu", "OpenAI & Anthropic, bring your own key")
            featureRow("hammer", "Unlimited custom Deeds + AI drafting")
            featureRow("doc.text.magnifyingglass", "Notion Search Deed")
            featureRow("square.and.arrow.up", "Share Deeds with anyone, no account needed")
        }
        .heurikaCard()
    }

    private func featureRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: HeurikaTheme.Spacing.sm) {
            Image(systemName: symbol)
                .foregroundStyle(HeurikaColor.antiqueGold)
                .frame(width: 22)
            Text(text)
                .font(HeurikaFont.body(14))
                .foregroundStyle(HeurikaColor.ink)
            Spacer()
        }
    }

    private var packageOptions: some View {
        VStack(spacing: HeurikaTheme.Spacing.sm) {
            ForEach(viewModel.packages, id: \.identifier) { package in
                packageRow(package)
            }
        }
    }

    private func packageRow(_ package: Package) -> some View {
        let isSelected = viewModel.selectedPackage?.identifier == package.identifier
        return Button {
            viewModel.select(package)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(package.storeProduct.localizedTitle)
                        .font(HeurikaFont.body(15, weight: .semibold))
                        .foregroundStyle(HeurikaColor.ink)
                    if let trial = viewModel.trialText(for: package) {
                        Text(trial)
                            .font(HeurikaFont.caption)
                            .foregroundStyle(HeurikaColor.sage)
                    }
                    Text(viewModel.renewalText(for: package))
                        .font(HeurikaFont.caption)
                        .foregroundStyle(HeurikaColor.espressoSoft)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? HeurikaColor.antiqueGold : HeurikaColor.espressoSoft.opacity(0.4))
            }
            .padding(HeurikaTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: HeurikaTheme.Radius.md, style: .continuous)
                    .fill(isSelected ? HeurikaColor.parchmentDeep : Color.white.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: HeurikaTheme.Radius.md, style: .continuous)
                    .strokeBorder(isSelected ? HeurikaColor.antiqueGold : HeurikaColor.espresso.opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var legalLinks: some View {
        VStack(spacing: HeurikaTheme.Spacing.sm) {
            Text("Payment renews automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel in your App Store account settings.")
                .multilineTextAlignment(.center)
            HStack(spacing: HeurikaTheme.Spacing.md) {
                if let termsURL = AppConfiguration.termsOfUseURL {
                    Link("Terms", destination: termsURL)
                }
                if let privacyURL = AppConfiguration.privacyPolicyURL {
                    Link("Privacy", destination: privacyURL)
                }
            }
        }
        .font(HeurikaFont.caption)
        .foregroundStyle(HeurikaColor.espressoSoft.opacity(0.7))
    }
}

#Preview {
    PaywallView()
}
