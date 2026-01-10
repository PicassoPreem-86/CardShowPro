import SwiftUI

/// Clean, minimal loading view with glassmorphic design
///
/// Displays a simple circular progress indicator during card recognition
/// with a professional, muted aesthetic matching Collectr's design language.
struct CleanLoadingView: View {
    let status: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Semi-transparent dark overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {} // Prevent interaction passthrough

            // Glassmorphic loading card
            VStack(spacing: DesignSystem.Spacing.md) {
                // Circular progress spinner
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round
                        )
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(rotation))

                // Status text
                Text(status)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(DesignSystem.Spacing.xl)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            guard !reduceMotion else { return }

            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading. \(status)")
        .accessibilityHint("Please wait")
    }
}

// MARK: - Preview
#Preview("Loading") {
    CleanLoadingView(status: "Analyzing card...")
        .preferredColorScheme(.dark)
}

#Preview("With Content") {
    ZStack {
        // Mock camera view
        Color.black.ignoresSafeArea()

        CleanLoadingView(status: "Analyzing card...")
    }
    .preferredColorScheme(.dark)
}
