import SwiftUI

/// Full-screen dark gradient background used across the app
struct NebulaBackgroundView: View {
    var body: some View {
        DesignSystem.Colors.backgroundGradient
            .ignoresSafeArea()
    }
}
