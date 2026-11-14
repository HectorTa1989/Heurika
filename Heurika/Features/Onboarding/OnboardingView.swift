import SwiftUI
import HeurikaCore

struct OnboardingPage {
    let symbol: String
    let title: String
    let body: String
}

struct OnboardingView: View {
    let onFinished: () -> Void

    @State private var pageIndex = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "quill.and.inkwell",
            title: "Your keyboard,\nreconsidered",
            body: "For years the keyboard has only ever done one thing: type. Heurika turns that third of your screen into something that can act, not just spell."
        ),
        OnboardingPage(
            symbol: "text.bubble",
            title: "Type your intent,\ntap Heurika",
            body: "Type what you need and tap the dedicated Heurika action. It can rewrite your words or insert a useful search, map, or workspace link without leaving the keyboard."
        ),
        OnboardingPage(
            symbol: "sparkles.rectangle.stack",
            title: "Deeds within reach",
            body: "Choose a focused Deed from the action row for grammar, tone, translation, search links, and more. Your normal letter and space keys always behave like keyboard keys."
        ),
        OnboardingPage(
            symbol: "hammer",
            title: "Build your own",
            body: "Describe a rewrite in plain English and Heurika drafts it as a Deed you can save, tweak, and share with a tap — no backend, no account required."
        ),
    ]

    var body: some View {
        ZStack {
            HeurikaColor.parchmentGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $pageIndex) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                    AIPrivacyConsentView {
                        withAnimation { pageIndex += 1 }
                    }
                    .tag(pages.count)
                    KeyboardSetupGuideView(onFinished: onFinished)
                        .tag(pages.count + 1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: pageIndex)

                HStack(spacing: 8) {
                    ForEach(0...(pages.count + 1), id: \.self) { index in
                        Capsule()
                            .fill(index == pageIndex ? HeurikaColor.antiqueGold : HeurikaColor.espresso.opacity(0.2))
                            .frame(width: index == pageIndex ? 22 : 7, height: 7)
                            .animation(.easeInOut, value: pageIndex)
                    }
                }
                .padding(.bottom, HeurikaTheme.Spacing.md)

                if pageIndex < pages.count {
                    VintageButton(title: pageIndex == pages.count - 1 ? "Set Up Keyboard" : "Continue", systemImage: "arrow.right") {
                        withAnimation { pageIndex += 1 }
                    }
                    .padding(.horizontal, HeurikaTheme.Spacing.lg)
                    .padding(.bottom, HeurikaTheme.Spacing.lg)
                }
            }
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: HeurikaTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(HeurikaColor.goldGradient)
                    .frame(width: 110, height: 110)
                    .shadow(color: HeurikaColor.antiqueGold.opacity(0.35), radius: 20, y: 8)
                Image(systemName: page.symbol)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(HeurikaColor.ink)
            }

            Text(page.title)
                .font(HeurikaFont.display(30, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(HeurikaColor.ink)

            Text(page.body)
                .font(HeurikaFont.body(16))
                .multilineTextAlignment(.center)
                .foregroundStyle(HeurikaColor.espressoSoft)
                .padding(.horizontal, HeurikaTheme.Spacing.xl)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
