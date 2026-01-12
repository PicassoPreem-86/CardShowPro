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

            ManualEntryFlow()
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
        .preferredColorScheme(.dark)
        .onAppear {
            // Configure tab bar appearance for better visibility
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    public init() {}
}
