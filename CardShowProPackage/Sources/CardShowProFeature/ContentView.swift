import SwiftUI

public struct ContentView: View {
    @State private var appState = AppState()

    public var body: some View {
        ZStack {
            // Background layer - renders first, always visible
            NebulaBackgroundView()

            // TabView layer - on top, made transparent
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
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Configure tab bar appearance with TRANSPARENT background to show nebula
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.5)

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    public init() {}
}
