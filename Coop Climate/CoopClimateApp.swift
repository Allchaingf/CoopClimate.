import SwiftUI

@main
struct CoopClimateApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.preferredColorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var splashDone = false

    var body: some View {
        ZStack {
            if !splashDone {
                SplashView(onComplete: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        splashDone = true
                    }
                })
                .transition(.asymmetric(
                    insertion: .identity,
                    removal: .scale(scale: 1.15).combined(with: .opacity)
                ))
                .zIndex(1)
            } else if !hasCompletedOnboarding {
                OnboardingView(onComplete: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        hasCompletedOnboarding = true
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .zIndex(0)
            } else {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .identity
                    ))
                    .zIndex(0)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: splashDone)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: hasCompletedOnboarding)
    }
}
