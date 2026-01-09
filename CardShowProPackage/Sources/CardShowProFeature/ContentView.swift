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

            CardListView()
                .environment(appState.scanSession)
                .tabItem {
                    Label("Inventory", systemImage: "archivebox.fill")
                }
                .tag(AppState.Tab.inventory)

            CameraView()
                .environment(appState.scanSession)
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(AppState.Tab.scan)

            ToolsView()
                .environment(appState)
                .tabItem {
                    Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(AppState.Tab.tools)
        }
        .preferredColorScheme(.dark)
    }

    public init() {}
}
