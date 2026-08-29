import SwiftUI

/// App entry: onboarding until the household is described, then the tab shell.
struct ContentView: View {
    @State private var store = AppStore()
    @State private var subscriptions = SubscriptionStore()

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
    }
}

#Preview {
    ContentView()
}
