import SwiftUI

@Observable
@MainActor
final class AppState {
    var scanSession = ScanSession()
    var selectedTab: Tab = .dashboard
    var isShowModeActive: Bool = false

    // Deep link navigation targets
    var pendingDeepLink: DeepLink?

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case inventory = "Inventory"
        case scan = "Scan"
        case tools = "Tools"

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .inventory: return "archivebox.fill"
            case .scan: return "camera.fill"
            case .tools: return "wrench.and.screwdriver.fill"
            }
        }
    }

    /// Deep link destinations that can navigate across tabs
    enum DeepLink: Equatable {
        case eventHistory
        case createEvent
        case contacts
        case wishlist
        case transactions
        case settings
        case search
        case analytics
        case taxSummary
    }

    /// Navigate to a specific deep link destination
    func navigate(to link: DeepLink) {
        pendingDeepLink = link

        // Switch to the correct tab based on destination
        switch link {
        case .eventHistory, .createEvent, .contacts, .wishlist, .analytics, .taxSummary:
            selectedTab = .tools
        case .transactions, .settings, .search:
            selectedTab = .dashboard
        }
    }
}
