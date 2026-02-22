import SwiftUI
import SwiftData

public struct ContentView: View {
    @State private var appState = AppState()
    @Environment(\.modelContext) private var modelContext

    public var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .environment(appState)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(AppState.Tab.dashboard)

            ScanView(showBackButton: false)
                .environment(appState)
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
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
        .task {
            await NotificationService.shared.performLaunchChecks(modelContext: modelContext)
        }
    }

    public init() {
        // Configure opaque tab bar with frosted glass effect
        let appearance = UITabBarAppearance()

        // Use opaque background instead of transparent
        appearance.configureWithOpaqueBackground()

        // Set background to dark card color at 95% opacity for frosted effect
        // #1E2442 = rgb(30, 36, 66) = rgb(0.118, 0.141, 0.259)
        appearance.backgroundColor = UIColor(red: 0.118, green: 0.141, blue: 0.259, alpha: 0.95)

        // Add native blur effect for glassmorphism
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)

        // Add subtle shadow for depth
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.3)

        // Style tab items
        let itemAppearance = UITabBarItemAppearance()

        // Normal state (unselected) - Gray
        itemAppearance.normal.iconColor = UIColor(white: 0.6, alpha: 1.0)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        // Selected state - Thunder Yellow (#FFD700 = rgb(255, 215, 0) = rgb(1.0, 0.843, 0.0))
        itemAppearance.selected.iconColor = UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        // Apply to all TabBar states
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
