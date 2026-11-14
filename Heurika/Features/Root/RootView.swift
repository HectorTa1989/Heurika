import SwiftUI
import HeurikaCore

struct RootView: View {
    @State private var hasCompletedOnboarding = SharedDefaults.shared.hasCompletedOnboarding

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    SharedDefaults.shared.hasCompletedOnboarding = true
                    withAnimation(.easeInOut) { hasCompletedOnboarding = true }
                }
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "quill.and.inkwell") }

            DeedsListView()
                .tabItem { Label("Deeds", systemImage: "sparkles") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(HeurikaColor.espresso)
    }
}
