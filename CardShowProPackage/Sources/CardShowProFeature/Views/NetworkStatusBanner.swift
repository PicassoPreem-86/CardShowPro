import SwiftUI
import Network

/// Network status banner shown when device is offline
/// Appears at top of screen with animated slide-in transition
@MainActor
struct NetworkStatusBanner: View {
    @State private var isOnline = true
    private let monitor = NWPathMonitor()

    var body: some View {
        if !isOnline {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "wifi.slash")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Offline Mode")
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(.white)

                    Text("Using cached data when available")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            .background(Color.orange)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("No internet connection. Offline mode active.")
        }
    }

    /// Start monitoring network connectivity
    func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                withAnimation(.spring(response: 0.3)) {
                    isOnline = path.status == .satisfied
                }
            }
        }
        let queue = DispatchQueue(label: "com.cardshowpro.networkmonitor")
        monitor.start(queue: queue)
    }

    /// Stop monitoring network connectivity
    func stopMonitoring() {
        monitor.cancel()
    }
}

#Preview {
    @Previewable @State var banner = NetworkStatusBanner()
    VStack {
        banner
            .onAppear { banner.startMonitoring() }

        Spacer()

        Text("Preview: Toggle Airplane Mode to see banner")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .background(Color.gray.opacity(0.1))
}
