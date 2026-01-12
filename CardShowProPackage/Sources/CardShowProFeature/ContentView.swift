import SwiftUI

public struct ContentView: View {
    @State private var appState = AppState()

    public var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .environment(appState)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(AppState.Tab.dashboard)

            CardPriceLookupView()
                .environment(appState)
                .tabItem {
                    Label("Scan", systemImage: "text.magnifyingglass")
                }
                .tag(AppState.Tab.scan)

            CardListView()
                .environment(appState.scanSession)
                .tabItem {
                    Label("Inventory", systemImage: "archivebox.fill")
                }
                .tag(AppState.Tab.inventory)

            ToolsView()
                .environment(appState)
                .tabItem {
                    Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(AppState.Tab.tools)
        }
        .toolbarBackground(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
    }

    public init() {
        // CRITICAL FIX: Make TabView container transparent
        // TabView uses UITabBarController under the hood, which applies
        // an opaque system background that blocks ZStack backgrounds.
        // We must configure UITabBar appearance to be transparent.
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear

        // Apply to all TabBar states
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
