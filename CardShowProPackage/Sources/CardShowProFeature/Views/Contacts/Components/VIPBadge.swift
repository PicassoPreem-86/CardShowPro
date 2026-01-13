import SwiftUI

/// Star badge overlay for VIP contacts
/// Positioned as top-right overlay on avatar
@MainActor
struct VIPBadge: View {
    /// Size of the VIP badge circle
    private let size: CGFloat = 20

    var body: some View {
        ZStack {
            // Background circle with Thunder Yellow gradient
            Circle()
                .fill(DesignSystem.Colors.premiumGradient)
                .frame(width: size, height: size)
                .shadow(
                    color: DesignSystem.Shadows.level3.color,
                    radius: DesignSystem.Shadows.level3.radius,
                    x: DesignSystem.Shadows.level3.x,
                    y: DesignSystem.Shadows.level3.y
                )

            // White star icon
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview Helper

/// Helper view showing VIP badge positioned on an avatar
@MainActor
private struct VIPBadgePreviewContainer: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Mock avatar circle
            Circle()
                .fill(DesignSystem.Colors.backgroundTertiary)
                .frame(width: 60, height: 60)
                .overlay {
                    Text("VIP")
                        .font(DesignSystem.Typography.heading4)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }

            // VIP badge positioned at top-right
            VIPBadge()
                .offset(x: 2, y: -2) // Slight offset for better positioning
        }
    }
}

// MARK: - Previews

#Preview("VIP Badge Standalone") {
    VIPBadge()
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("VIP Badge on Avatar") {
    VIPBadgePreviewContainer()
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Multiple Sizes") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        // Small avatar
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(DesignSystem.Colors.backgroundTertiary)
                .frame(width: 40, height: 40)

            VIPBadge()
                .offset(x: 2, y: -2)
        }

        // Medium avatar
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(DesignSystem.Colors.backgroundTertiary)
                .frame(width: 60, height: 60)

            VIPBadge()
                .offset(x: 2, y: -2)
        }

        // Large avatar
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(DesignSystem.Colors.backgroundTertiary)
                .frame(width: 100, height: 100)

            VIPBadge()
                .offset(x: 4, y: -4)
        }
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
