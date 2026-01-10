import SwiftUI

/// Reusable metric card component for analytics dashboard
/// Displays a single metric with icon, value, label, and optional change indicator
@MainActor
struct AnalyticsMetricCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let change: String?
    let isPositive: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(iconColor)

            // Value with monospaced digits for currency alignment
            Text(value)
                .font(DesignSystem.Typography.displaySmall)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            // Label
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            // Change indicator (if provided)
            if let change = change, let isPositive = isPositive {
                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(DesignSystem.Typography.captionSmall)

                    Text(change)
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(isPositive ? DesignSystem.Colors.success : DesignSystem.Colors.error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(
            LinearGradient(
                colors: [
                    iconColor.opacity(0.1),
                    DesignSystem.Colors.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(iconColor.opacity(0.2), lineWidth: 1)
        )
        .shadowElevation(2)
    }
}

// MARK: - Previews

#Preview("Total Value Metric") {
    AnalyticsMetricCard(
        icon: "dollarsign.circle.fill",
        iconColor: DesignSystem.Colors.thunderYellow,
        value: "$5,432.50",
        label: "Total Value",
        change: "+8.7%",
        isPositive: true
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Card Count Metric") {
    AnalyticsMetricCard(
        icon: "square.stack.3d.up.fill",
        iconColor: DesignSystem.Colors.electricBlue,
        value: "150",
        label: "Total Cards",
        change: nil,
        isPositive: nil
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Top Card Metric") {
    VStack {
        AnalyticsMetricCard(
            icon: "star.fill",
            iconColor: DesignSystem.Colors.premium,
            value: "$485.00",
            label: "Charizard VSTAR",
            change: "+11.2%",
            isPositive: true
        )

        AnalyticsMetricCard(
            icon: "chart.bar.fill",
            iconColor: DesignSystem.Colors.cyan,
            value: "$36.22",
            label: "Average Value",
            change: "-2.3%",
            isPositive: false
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
