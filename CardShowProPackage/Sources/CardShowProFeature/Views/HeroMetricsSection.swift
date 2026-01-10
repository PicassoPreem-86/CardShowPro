import SwiftUI

/// Hero metrics section for analytics dashboard
/// Displays 4 key metrics in a 2x2 grid layout
@MainActor
struct HeroMetricsSection: View {
    let metrics: AnalyticsMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Section header
            Text("Portfolio Overview")
                .font(DesignSystem.Typography.heading3)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // 2x2 Grid of metrics
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
                ],
                spacing: DesignSystem.Spacing.sm
            ) {
                // Total Value
                AnalyticsMetricCard(
                    icon: "dollarsign.circle.fill",
                    iconColor: DesignSystem.Colors.thunderYellow,
                    value: formatCurrency(metrics.totalValue),
                    label: "Total Value",
                    change: formatPercentage(metrics.valueChange),
                    isPositive: metrics.valueChange >= 0
                )

                // Total Cards
                AnalyticsMetricCard(
                    icon: "square.stack.3d.up.fill",
                    iconColor: DesignSystem.Colors.electricBlue,
                    value: "\(metrics.cardCount)",
                    label: "Total Cards",
                    change: nil,
                    isPositive: nil
                )

                // Average Value
                AnalyticsMetricCard(
                    icon: "chart.bar.fill",
                    iconColor: DesignSystem.Colors.cyan,
                    value: formatCurrency(metrics.averageValue),
                    label: "Average Value",
                    change: nil,
                    isPositive: nil
                )

                // Top Card
                AnalyticsMetricCard(
                    icon: "star.fill",
                    iconColor: DesignSystem.Colors.premium,
                    value: formatCurrency(metrics.topCardValue),
                    label: metrics.topCardName,
                    change: nil,
                    isPositive: nil
                )
            }
        }
    }

    // MARK: - Formatting Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatPercentage(_ value: Double) -> String {
        let percentage = value * 100
        let sign = percentage >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, percentage)
    }
}

// MARK: - Previews

#Preview("Hero Metrics Section") {
    let mockMetrics = AnalyticsMetrics(
        totalValue: 5432.50,
        cardCount: 150,
        averageValue: 36.22,
        topCardValue: 485.00,
        topCardName: "Charizard VSTAR",
        valueChange: 0.087
    )

    return ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HeroMetricsSection(metrics: mockMetrics)
        }
        .padding()
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Empty State") {
    let emptyMetrics = AnalyticsMetrics(
        totalValue: 0,
        cardCount: 0,
        averageValue: 0,
        topCardValue: 0,
        topCardName: "N/A",
        valueChange: 0
    )

    return ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HeroMetricsSection(metrics: emptyMetrics)
        }
        .padding()
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}
