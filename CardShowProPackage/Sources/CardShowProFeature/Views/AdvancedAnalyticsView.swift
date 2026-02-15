import SwiftUI
import SwiftData
import Charts

/// Advanced Analytics Dashboard View
/// Displays real computed analytics from SwiftData inventory and transactions
@MainActor
struct AdvancedAnalyticsView: View {
    @Query private var inventoryCards: [InventoryCard]
    @Query private var transactions: [Transaction]
    @State private var analyticsService = AnalyticsService()
    @State private var selectedTimeRange: AnalyticsTimeRange = .ninetyDays
    @State private var selectedCategoryFilter: AnalyticsCategoryFilter = .all

    private var analyticsData: AnalyticsData {
        analyticsService.computeAnalytics(cards: inventoryCards, transactions: transactions)
    }

    private var isEmpty: Bool {
        inventoryCards.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            selectedTimeRange = .ninetyDays
                            selectedCategoryFilter = .all
                        } label: {
                            Label("Reset Filters", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(DesignSystem.Colors.electricBlue)
                    }
                }
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Hero Metrics
                HeroMetricsSection(metrics: analyticsData.metrics)
                    .padding(.horizontal)

                // Time range filter
                timeRangeSelector
                    .padding(.horizontal)

                // Portfolio Value Chart
                portfolioChartSection
                    .padding(.horizontal)

                // Top Performers
                topPerformersSection
                    .padding(.horizontal)

                // Category Breakdown
                categoryBreakdownSection
                    .padding(.horizontal)

                // Set Breakdown
                setBreakdownSection
                    .padding(.horizontal)

                // Insights
                insightsSection
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
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
                        .foregroundStyle(selectedTimeRange == range ? DesignSystem.Colors.backgroundPrimary : DesignSystem.Colors.textSecondary)
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
        let points = filteredTrendPoints

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Portfolio Value", subtitle: "Value over time")

            if points.count > 1 {
                Chart(points) { point in
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
                .frame(height: 220)
            } else {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignSystem.Colors.electricBlue.opacity(0.3))
                    Text("Not enough data for trend chart")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
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
            AnalyticsSectionHeader(title: "Top Performers", subtitle: "Your highest value cards")

            let topCards = analyticsData.topCards
            if topCards.isEmpty {
                placeholderContent(icon: "chart.bar.horizontal.fill", text: "No cards yet")
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
                placeholderContent(icon: "chart.pie.fill", text: "No categories yet")
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
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Set Breakdown

    private var setBreakdownSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Set Breakdown", subtitle: "Performance by set")

            let sets = Array(analyticsData.setBreakdown.prefix(8))
            if sets.isEmpty {
                placeholderContent(icon: "chart.bar.fill", text: "No sets yet")
            } else {
                ForEach(sets) { setItem in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(setItem.setName)
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .lineLimit(1)
                            Text("\(setItem.cardCount) cards")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatCurrency(setItem.totalValue))
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.bold)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text("avg \(formatCurrency(setItem.averageValue))")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xxxs)
                }
            }
        }
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
                    AnalyticsSectionHeader(title: "Insights & Opportunities", subtitle: "Smart recommendations")

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

            Text("No Analytics Available")
                .font(DesignSystem.Typography.heading2)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Start scanning cards to see portfolio insights and analytics")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundPrimary)
    }

    // MARK: - Helpers

    private var filteredTrendPoints: [TimeSeriesDataPoint] {
        let points = analyticsData.portfolioTrend.dataPoints
        switch selectedTimeRange {
        case .sevenDays: return Array(points.suffix(7))
        case .thirtyDays: return Array(points.suffix(30))
        case .ninetyDays: return Array(points.suffix(90))
        case .allTime: return points
        }
    }

    private func placeholderContent(icon: String, text: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.electricBlue.opacity(0.3))
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

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

// MARK: - Previews

#Preview("Analytics - With Data") {
    AdvancedAnalyticsView()
}
