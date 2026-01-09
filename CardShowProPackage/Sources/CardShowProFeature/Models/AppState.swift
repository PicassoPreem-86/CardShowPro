import SwiftUI

@Observable
@MainActor
final class AppState {
    var scanSession = ScanSession()
    var selectedTab: Tab = .dashboard
    var isShowModeActive: Bool = false

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
}
