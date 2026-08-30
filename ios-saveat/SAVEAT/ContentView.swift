import SwiftUI

/// App entry: onboarding until the household is described, then the tab shell.
struct ContentView: View {
    @State private var store = AppStore()
    @State private var subscriptions = SubscriptionStore()
    @State private var isLaunching = true

    var body: some View {
        Group {
            if store.profile.hasCompletedOnboarding {
                RootView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .environment(store)
        .environment(subscriptions)
        .animation(.easeInOut(duration: 0.35), value: store.profile.hasCompletedOnboarding)
        .tint(Theme.sageDeep)
        .preferredColorScheme(.light)
        .overlay {
            if isLaunching { launchScreen }
        }
        .task {
            // Reminders are re-planned from the stock restored at launch.
            await NotificationService.shared.refreshAuthorization()
            store.scheduleReminders()

            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.easeOut(duration: 0.35)) { isLaunching = false }
        }
    }

    /// Calm launch state on the SAVEAT cream background, showing the official icon.
    private var launchScreen: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            VStack(spacing: 16) {
                BrandMark(size: 104)
                Text("SAVEAT")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(Theme.sageDeep)
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    ContentView()
}
