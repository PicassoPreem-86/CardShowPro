import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var inventoryCards: [InventoryCard]
    @Query private var transactions: [Transaction]
    @State private var analyticsService = AnalyticsService()
    @State private var selectedTimeRange: AnalyticsTimeRange = .ninetyDays

    private var analyticsData: AnalyticsData {
        analyticsService.computeAnalytics(cards: inventoryCards, transactions: transactions)
    }

    private var filteredTrendPoints: [TimeSeriesDataPoint] {
        let points = analyticsData.portfolioTrend.dataPoints
        switch selectedTimeRange {
        case .sevenDays: return Array(points.suffix(7))
        case .thirtyDays: return Array(points.suffix(30))
        case .ninetyDays: return Array(points.suffix(90))
        case .allTime: return points
        }
    }

    private var totalProfit: Double {
        let activeCards = inventoryCards.filter { $0.isAvailable }
        return activeCards.reduce(0.0) { $0 + $1.profit }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NebulaBackgroundView()

                if inventoryCards.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            heroMetricsSection
                            timeRangeSelector
                            portfolioChartSection
                            topPerformersSection
                            categoryBreakdownSection
                            quickStatsGrid
                            insightsSection
                        }
                        .padding(.horizontal)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Hero Metrics

    private var heroMetricsSection: some View {
        let metrics = analyticsData.metrics
        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
            ],
            spacing: DesignSystem.Spacing.sm
        ) {
            AnalyticsMetricCard(
                icon: "dollarsign.circle.fill",
                iconColor: DesignSystem.Colors.thunderYellow,
                value: formatCurrency(metrics.totalValue),
                label: "Total Value",
                change: formatPercentage(metrics.valueChange),
                isPositive: metrics.valueChange >= 0
            )

            AnalyticsMetricCard(
                icon: "square.stack.3d.up.fill",
                iconColor: DesignSystem.Colors.electricBlue,
                value: "\(metrics.cardCount)",
                label: "Total Cards",
                change: nil,
                isPositive: nil
            )

            AnalyticsMetricCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: DesignSystem.Colors.success,
                value: formatCurrency(totalProfit),
                label: "Unrealized Profit",
                change: nil,
                isPositive: nil
            )

            AnalyticsMetricCard(
                icon: "chart.bar.fill",
                iconColor: DesignSystem.Colors.cyan,
                value: formatCurrency(metrics.averageValue),
                label: "Avg Card Value",
                change: nil,
                isPositive: nil
            )
        }
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                    }
                } label: {
                    Text(range.displayName)
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(selectedTimeRange == range ? .bold : .regular)
                        .foregroundStyle(selectedTimeRange == range ? .black : DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(selectedTimeRange == range ? DesignSystem.Colors.cyan : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Portfolio Chart

    private var portfolioChartSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Portfolio Value")
                .font(DesignSystem.Typography.heading3)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if filteredTrendPoints.isEmpty {
                Text("Add cards to see your portfolio trend")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart(filteredTrendPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(DesignSystem.Colors.cyan)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.cyan.opacity(0.3),
                                DesignSystem.Colors.cyan.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text(formatCompactCurrency(val))
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                        }
                        AxisGridLine()
                            .foregroundStyle(DesignSystem.Colors.borderPrimary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Top Performers

    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Top Performers", subtitle: "Highest value cards")

            let topCards = analyticsData.topCards
            if topCards.isEmpty {
                Text("No cards in inventory yet")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            } else {
                ForEach(Array(topCards.enumerated()), id: \.element.id) { index, card in
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Text("\(index + 1)")
                            .font(DesignSystem.Typography.heading4)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(DesignSystem.Colors.electricBlue.gradient)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.cardName)
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .lineLimit(1)

                            Text(card.setName)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatCurrency(card.value))
                                .font(DesignSystem.Typography.heading4)
                                .fontWeight(.bold)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                            if card.change != 0 {
                                Text(formatPercentage(card.change))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(card.change >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
            }
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Category Breakdown", subtitle: "Distribution by type")

            let categories = analyticsData.categoryBreakdown
            if categories.isEmpty {
                Text("No category data yet")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            } else {
                ForEach(categories) { cat in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        HStack {
                            Text(cat.category)
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                            Spacer()

                            Text(formatCurrency(cat.totalValue))
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                            Text("\(Int(cat.percentage * 100))%")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .frame(width: 36, alignment: .trailing)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DesignSystem.Colors.backgroundTertiary)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DesignSystem.Colors.cyan.gradient)
                                    .frame(width: geometry.size.width * cat.percentage)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xxxs)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Quick Stats

    private var quickStatsGrid: some View {
        let activeCards = inventoryCards.filter { $0.isAvailable }
        let gradedCount = activeCards.filter { $0.isGraded }.count
        let saleTxns = transactions.filter { $0.transactionType == .sale }
        let totalRevenue = saleTxns.reduce(0.0) { $0 + $1.netAmount }

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Quick Stats")

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: DesignSystem.Spacing.sm
            ) {
                quickStatCard(title: "Total Revenue", value: formatCurrency(totalRevenue), icon: "dollarsign.circle.fill", color: DesignSystem.Colors.success)
                quickStatCard(title: "Sales Count", value: "\(saleTxns.count)", icon: "cart.fill", color: DesignSystem.Colors.electricBlue)
                quickStatCard(title: "Graded Cards", value: "\(gradedCount)", icon: "rosette", color: DesignSystem.Colors.thunderYellow)
                quickStatCard(title: "Unique Sets", value: "\(Set(activeCards.map { $0.setName }).count)", icon: "square.stack.fill", color: DesignSystem.Colors.cyan)
            }
        }
    }

    private func quickStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(color)

            Text(value)
                .font(DesignSystem.Typography.heading3)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .monospacedDigit()

            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Insights

    private var insightsSection: some View {
        let insights = analyticsData.insights
        return Group {
            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    AnalyticsSectionHeader(title: "Insights", subtitle: "Smart recommendations")

                    ForEach(insights) { insight in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: insightIcon(for: insight.category))
                                .font(DesignSystem.Typography.heading4)
                                .foregroundStyle(insightColor(for: insight.category))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                                Text(insight.title)
                                    .font(DesignSystem.Typography.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                                Text(insight.description)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 80))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No Analytics Yet")
                .font(DesignSystem.Typography.heading2)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Add cards to your inventory to see portfolio insights and analytics")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func insightIcon(for category: InsightCategory) -> String {
        switch category {
        case .opportunity: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .trend: return "chart.line.uptrend.xyaxis"
        case .recommendation: return "hand.thumbsup.fill"
        }
    }

    private func insightColor(for category: InsightCategory) -> Color {
        switch category {
        case .opportunity: return DesignSystem.Colors.thunderYellow
        case .warning: return DesignSystem.Colors.warning
        case .trend: return DesignSystem.Colors.cyan
        case .recommendation: return DesignSystem.Colors.electricBlue
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatCompactCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.0fK", value / 1000)
        }
        return String(format: "$%.0f", value)
    }

    private func formatPercentage(_ value: Double) -> String {
        let percentage = value * 100
        let sign = percentage >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, percentage)
    }
}
