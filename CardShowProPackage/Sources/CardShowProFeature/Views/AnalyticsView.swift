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
                            cumulativeProfitChartSection
                            salesVelocityChartSection
                            platformBreakdownSection
                            inventoryAgeSection
                            periodComparisonSection
                            sellThroughGaugeSection
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

    // MARK: - Cumulative Profit Chart

    private var cumulativeProfitChartSection: some View {
        let profitTimeline = analyticsService.cumulativeProfitTimeline(transactions: transactions)

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Realized Profit", subtitle: "Cumulative profit from sales")

            if profitTimeline.isEmpty {
                Text("Complete sales to see profit trend")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(profitTimeline) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Profit", point.value)
                    )
                    .foregroundStyle(DesignSystem.Colors.success)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Profit", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.success.opacity(0.3),
                                DesignSystem.Colors.success.opacity(0.05)
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
                .frame(height: 180)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Sales Velocity Chart

    private var salesVelocityChartSection: some View {
        let weeklyData = analyticsService.weeklySalesCounts(transactions: transactions, weeks: 12)

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Sales Velocity", subtitle: "Cards sold per week")

            if weeklyData.isEmpty || weeklyData.allSatisfy({ $0.count == 0 }) {
                Text("Complete sales to see velocity")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(Array(weeklyData.enumerated()), id: \.offset) { _, item in
                    BarMark(
                        x: .value("Week", item.weekLabel),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.electricBlue, DesignSystem.Colors.cyan],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let val = value.as(Int.self) {
                                Text("\(val)")
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
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Platform Breakdown

    private var platformBreakdownSection: some View {
        let platforms = analyticsService.platformProfitability(transactions: transactions)

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Platform Breakdown", subtitle: "Net profit by platform")

            if platforms.isEmpty {
                Text("Complete sales to see platform data")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                // Horizontal bar chart
                Chart(platforms) { platform in
                    BarMark(
                        x: .value("Profit", platform.netProfit),
                        y: .value("Platform", platform.platform)
                    )
                    .foregroundStyle(platform.netProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { value in
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
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(max(platforms.count * 44, 100)))

                // Detail rows
                ForEach(platforms) { platform in
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(platform.platform)
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                            Text("\(platform.saleCount) sales - Avg \(formatCurrency(platform.averageSale))")
                                .font(DesignSystem.Typography.captionSmall)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatCurrency(platform.netProfit))
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(platform.netProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)

                            Text("Fees: \(formatCurrency(platform.fees))")
                                .font(DesignSystem.Typography.captionSmall)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
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

    // MARK: - Inventory Age Distribution

    private var inventoryAgeSection: some View {
        let buckets = analyticsService.inventoryAgeBuckets(cards: inventoryCards)
        let colors: [Color] = [DesignSystem.Colors.success, DesignSystem.Colors.thunderYellow, DesignSystem.Colors.warning, DesignSystem.Colors.error]

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Inventory Age", subtitle: "Distribution by days in stock")

            if buckets.allSatisfy({ $0.count == 0 }) {
                Text("Add cards to see age distribution")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                    BarMark(
                        x: .value("Age", bucket.label),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(colors[index])
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let val = value.as(Int.self) {
                                Text("\(val)")
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
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                            }
                        }
                    }
                }
                .frame(height: 160)

                // Legend
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                        HStack(spacing: DesignSystem.Spacing.xxxs) {
                            Circle()
                                .fill(colors[index])
                                .frame(width: 8, height: 8)
                            Text("\(bucket.label): \(bucket.count)")
                                .font(DesignSystem.Typography.captionSmall)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Period Comparison

    private var periodComparisonSection: some View {
        let comparison = analyticsService.periodComparison(transactions: transactions, periodDays: 30)

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Period Comparison", subtitle: "Last 30 days vs previous 30 days")

            HStack(spacing: DesignSystem.Spacing.sm) {
                // Current Period
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("This Period")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.cyan)

                    comparisonMetric(label: "Revenue", value: formatCurrency(comparison.currentRevenue))
                    comparisonMetric(label: "Profit", value: formatCurrency(comparison.currentProfit))
                    comparisonMetric(label: "Cards Sold", value: "\(comparison.currentCardsSold)")
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

                // Previous Period
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Previous Period")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    comparisonMetric(label: "Revenue", value: formatCurrency(comparison.previousRevenue))
                    comparisonMetric(label: "Profit", value: formatCurrency(comparison.previousProfit))
                    comparisonMetric(label: "Cards Sold", value: "\(comparison.previousCardsSold)")
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }

            // Change indicators
            HStack(spacing: DesignSystem.Spacing.lg) {
                changeIndicator(label: "Revenue", change: comparison.revenueChange)
                changeIndicator(label: "Profit", change: comparison.profitChange)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    private func comparisonMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(DesignSystem.Typography.captionSmall)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            Text(value)
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .monospacedDigit()
        }
    }

    private func changeIndicator(label: String, change: Double) -> some View {
        HStack(spacing: DesignSystem.Spacing.xxxs) {
            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(DesignSystem.Typography.captionSmall)
            Text("\(label): \(formatPercentage(change))")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(change >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
    }

    // MARK: - Sell-Through Rate Gauge

    private var sellThroughGaugeSection: some View {
        let rate = analyticsService.sellThroughRate(cards: inventoryCards)
        let percentage = Int(rate * 100)
        let gaugeColor: Color = rate > 0.7 ? DesignSystem.Colors.success : rate > 0.4 ? DesignSystem.Colors.thunderYellow : DesignSystem.Colors.warning

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            AnalyticsSectionHeader(title: "Sell-Through Rate", subtitle: "Sold / (Sold + Listed)")

            HStack(spacing: DesignSystem.Spacing.lg) {
                // Circular gauge
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.backgroundTertiary, lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: rate)
                        .stroke(gaugeColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: rate)

                    VStack(spacing: 2) {
                        Text("\(percentage)%")
                            .font(DesignSystem.Typography.heading2)
                            .fontWeight(.bold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .monospacedDigit()
                    }
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    let soldCount = inventoryCards.filter { $0.isSold }.count
                    let listedCount = inventoryCards.filter { $0.cardStatus == .listed }.count

                    gaugeDetailRow(label: "Sold", value: "\(soldCount)", color: DesignSystem.Colors.success)
                    gaugeDetailRow(label: "Listed", value: "\(listedCount)", color: DesignSystem.Colors.electricBlue)
                    gaugeDetailRow(label: "Rate", value: "\(percentage)%", color: gaugeColor)
                }

                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    private func gaugeDetailRow(label: String, value: String, color: Color) -> some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .monospacedDigit()
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
