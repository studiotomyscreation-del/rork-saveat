import SwiftUI

nonisolated enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case home, stock, meals, scanner, profile

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .home: "Accueil"
        case .stock: "Stock"
        case .meals: "Repas"
        case .scanner: "Scanner"
        case .profile: "Profil"
        }
    }

    nonisolated var symbol: String {
        switch self {
        case .home: "house.fill"
        case .stock: "shippingbox.fill"
        case .meals: "sparkles"
        case .scanner: "barcode.viewfinder"
        case .profile: "person.fill"
        }
    }
}

/// Tab shell with a soft floating bar and a prominent scanner button.
/// The bar hides on pushed detail screens so bottom CTAs own the bottom edge.
struct RootView: View {
    @Environment(AppStore.self) private var store

    @State private var selection: AppTab = .home
    @State private var homePath = NavigationPath()
    @State private var stockPath = NavigationPath()
    @State private var mealsPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    @State private var isScannerPresented = false
    @State private var mealPrompt: MealPrompt?

    private var activeDepth: Int {
        switch selection {
        case .home: homePath.count
        case .stock: stockPath.count
        case .meals: mealsPath.count
        case .profile: profilePath.count
        case .scanner: 0
        }
    }

    private var showsTabBar: Bool { activeDepth == 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.cream.ignoresSafeArea()

            Group {
                switch selection {
                case .home:
                    NavigationStack(path: $homePath) {
                        HomeView(path: $homePath, onScan: openScanner, onAskAI: openAssistant)
                            .saveatRoutes()
                    }
                case .stock:
                    NavigationStack(path: $stockPath) {
                        InventoryView(path: $stockPath, onScan: openScanner)
                            .saveatRoutes()
                    }
                case .meals:
                    NavigationStack(path: $mealsPath) {
                        MealAssistantView(path: $mealsPath, prompt: $mealPrompt)
                            .saveatRoutes()
                    }
                case .profile:
                    NavigationStack(path: $profilePath) {
                        ProfileView(path: $profilePath)
                            .saveatRoutes()
                    }
                case .scanner:
                    Color.clear
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: showsTabBar ? 78 : 0)
            }

            if showsTabBar {
                tabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: showsTabBar)
        .fullScreenCover(isPresented: $isScannerPresented) {
            GroceryScanView()
        }
        .overlay(alignment: .top) { bannerOverlay }
        .onChange(of: NotificationService.shared.rescueRequest) { _, request in
            guard request != nil else { return }
            openRescue()
            NotificationService.shared.clearRescueRequest()
        }
    }

    /// Opens "À sauver" from a reminder, wherever the user currently is.
    private func openRescue() {
        isScannerPresented = false
        homePath = NavigationPath()
        homePath.append(Route.rescue)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            selection = .home
        }
    }

    private func openScanner() {
        Haptics.soft()
        isScannerPresented = true
    }

    /// Jumps to the assistant tab with an optional pre-filled request.
    private func openAssistant(_ prompt: MealPrompt) {
        mealPrompt = prompt
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            selection = .meals
        }
        Haptics.soft()
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    if tab == .scanner {
                        openScanner()
                    } else if tab == selection {
                        resetPath(for: tab)
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selection = tab }
                        Haptics.light()
                    }
                } label: {
                    tabItem(tab)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(Theme.surface)
                .shadow(color: Theme.ink.opacity(0.10), radius: 18, y: 6)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private func tabItem(_ tab: AppTab) -> some View {
        let isSelected = tab == selection && tab != .scanner
        let isScanner = tab == .scanner

        return VStack(spacing: 3) {
            ZStack {
                if isScanner {
                    Circle()
                        .fill(
                            LinearGradient(colors: [Theme.sage, Theme.sageDeep],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Theme.sageDeep.opacity(0.4), radius: 10, y: 4)
                }
                Image(systemName: tab.symbol)
                    .font(.system(size: isScanner ? 21 : 17, weight: .semibold))
                    .foregroundStyle(isScanner ? .white : (isSelected ? Theme.sageDeep : Theme.inkSoft.opacity(0.7)))
            }
            .frame(height: 44)

            Text(tab.title)
                .font(.system(size: 10, weight: isSelected || isScanner ? .semibold : .medium, design: .rounded))
                .foregroundStyle(isSelected || isScanner ? Theme.sageDeep : Theme.inkSoft.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .contentShape(.rect)
    }

    private func resetPath(for tab: AppTab) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .stock: stockPath = NavigationPath()
        case .meals: mealsPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        case .scanner: break
        }
    }

    @ViewBuilder
    private var bannerOverlay: some View {
        if let banner = store.banner {
            BannerView(message: banner)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: banner.id) {
                    try? await Task.sleep(for: .seconds(2.6))
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                        store.banner = nil
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.9), value: banner.id)
        }
    }
}
