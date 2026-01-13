import SwiftUI

/// Pulsing badge showing match count for card want lists
/// Features: Thunder Yellow background, dark text for contrast, 2s pulse animation
@MainActor
struct MatchCountBadge: View {
    let count: Int

    /// Minimum size for the badge
    private let minSize: CGFloat = 24

    /// Border width
    private let borderWidth: CGFloat = 2

    /// Animation state for pulsing effect
    @State private var isPulsing = false

    var body: some View {
        Text("\(count)")
            .font(DesignSystem.Typography.captionBold)
            .foregroundStyle(darkColor)
            .frame(minWidth: minSize, minHeight: minSize)
            .padding(.horizontal, DesignSystem.Spacing.xxxs)
            .background(DesignSystem.Colors.thunderYellow)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(darkColor, lineWidth: borderWidth)
            }
            .scaleEffect(isPulsing ? 1.08 : 1.0)
            .animation(
                .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }

    // MARK: - Colors

    /// Dark color for text and border (#0A0E27)
    private var darkColor: Color {
        Color(hex: "#0A0E27")
    }
}

// MARK: - Previews

#Preview("Single Digit") {
    MatchCountBadge(count: 5)
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Double Digit") {
    MatchCountBadge(count: 42)
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Triple Digit") {
    MatchCountBadge(count: 127)
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Multiple Counts") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        HStack(spacing: DesignSystem.Spacing.md) {
            MatchCountBadge(count: 3)
            MatchCountBadge(count: 12)
            MatchCountBadge(count: 99)
        }

        Divider()
            .background(DesignSystem.Colors.borderPrimary)

        // Show in context with contact name
        HStack {
            Text("John Smith")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            MatchCountBadge(count: 8)
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Animation Test") {
    ZStack {
        DesignSystem.Colors.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: DesignSystem.Spacing.xl) {
            Text("Watch the pulse animation")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            MatchCountBadge(count: 15)
                .padding()
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

            Text("2 second cycle: 1.0 → 1.08 → 1.0")
                .font(DesignSystem.Typography.captionSmall)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
    }
}
