import Foundation

/// Time range filter options for analytics
enum AnalyticsTimeRange: String, CaseIterable, Sendable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case allTime = "All Time"

    var displayName: String { rawValue }
}

/// Category filter options for analytics
enum AnalyticsCategoryFilter: String, CaseIterable, Sendable {
    case all = "All"
    case rawSingles = "Raw"
    case graded = "Graded"
    case sealed = "Sealed"

    var displayName: String { rawValue }
}

/// Observable state for the Advanced Analytics feature
/// Manages analytics data, filters, and computed properties
@Observable
@MainActor
final class AnalyticsState: Sendable {

    // MARK: - Published State

    /// Current analytics data
    private(set) var data: AnalyticsData

    /// Selected time range filter
    var selectedTimeRange: AnalyticsTimeRange = .ninetyDays

    /// Selected category filter
    var selectedCategoryFilter: AnalyticsCategoryFilter = .all

    /// Loading state
    var isLoading: Bool = false

    // MARK: - Initialization

    init(data: AnalyticsData = AnalyticsMockData.generateMockData()) {
        self.data = data
    }

    // MARK: - Computed Properties

    /// Filtered metrics based on current filters
    var filteredMetrics: AnalyticsMetrics {
        // In Phase 1, we return unfiltered data
        // Future: Apply time range and category filters
        data.metrics
    }

    /// Filtered category breakdown
    var filteredCategoryBreakdown: [CategoryBreakdown] {
        if selectedCategoryFilter == .all {
            return data.categoryBreakdown
        }

        // Filter by selected category
        let categoryName: String
        switch selectedCategoryFilter {
        case .all:
            return data.categoryBreakdown
        case .rawSingles:
            categoryName = "Raw Singles"
        case .graded:
            categoryName = "Graded Cards"
        case .sealed:
            categoryName = "Sealed Products"
        }

        return data.categoryBreakdown.filter { $0.category == categoryName }
    }

    /// Filtered set breakdown
    var filteredSetBreakdown: [SetBreakdown] {
        // In Phase 1, we return unfiltered data
        // Future: Apply filters
        data.setBreakdown
    }

    /// Filtered rarity distribution
    var filteredRarityDistribution: [RarityDistribution] {
        // In Phase 1, we return unfiltered data
        // Future: Apply filters
        data.rarityDistribution
    }

    /// Filtered top cards
    var filteredTopCards: [TopCard] {
        // In Phase 1, we return unfiltered data
        // Future: Apply filters
        data.topCards
    }

    /// Filtered portfolio trend based on time range
    var filteredPortfolioTrend: PortfolioTrend {
        let dataPoints: [TimeSeriesDataPoint]

        switch selectedTimeRange {
        case .sevenDays:
            dataPoints = Array(data.portfolioTrend.dataPoints.suffix(7))
        case .thirtyDays:
            dataPoints = Array(data.portfolioTrend.dataPoints.suffix(30))
        case .ninetyDays:
            dataPoints = Array(data.portfolioTrend.dataPoints.suffix(90))
        case .allTime:
            dataPoints = data.portfolioTrend.dataPoints
        }

        // Recalculate change for filtered period
        let totalChange: Double
        if let first = dataPoints.first, let last = dataPoints.last {
            totalChange = (last.value - first.value) / first.value
        } else {
            totalChange = 0
        }

        return PortfolioTrend(
            dataPoints: dataPoints,
            totalChange: totalChange,
            periodLabel: selectedTimeRange.displayName
        )
    }

    /// Filtered insights
    var filteredInsights: [AnalyticsInsight] {
        // In Phase 1, we return all insights
        // Future: Filter by priority or category
        data.insights
    }

    /// Whether the collection is empty
    var isEmpty: Bool {
        data.metrics.cardCount == 0
    }

    // MARK: - Actions

    /// Refresh analytics data
    func refreshData() async {
        isLoading = true

        // Simulate network delay
        try? await Task.sleep(for: .milliseconds(500))

        // In Phase 1, we regenerate mock data
        // Future: Fetch from real data source
        data = AnalyticsMockData.generateMockData()

        isLoading = false
    }

    /// Reset filters to defaults
    func resetFilters() {
        selectedTimeRange = .ninetyDays
        selectedCategoryFilter = .all
    }
}
