import SwiftUI

/// Nebula Space Background View
///
/// A reusable component that displays a stunning nebula space background
/// covering the entire screen. The background scales to fill the available
/// space while maintaining its aspect ratio.
///
/// ## Usage
/// ```swift
/// TabView {
///     // Your content here
/// }
/// .background(NebulaBackgroundView())
/// ```
@MainActor
public struct NebulaBackgroundView: View {
    public var body: some View {
        ZStack {
            // Fallback gradient background (visible if image fails to load)
            LinearGradient(
                colors: [.black, Color.blue.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            // Main nebula image background with dark overlay for text readability
            // CRITICAL: Must use bundle: .main because this component is in the Swift Package
            // but the image asset is in the main app bundle
            Image("NebulaBackground", bundle: .main)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(Color.black.opacity(0.3))
                .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    public init() {}
}

#Preview {
    NebulaBackgroundView()
}
