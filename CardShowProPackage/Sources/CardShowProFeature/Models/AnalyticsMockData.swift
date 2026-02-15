import Foundation

/// Previously provided mock data for analytics. Now replaced by AnalyticsService
/// computing real data from SwiftData. Kept for empty state generation only.
@MainActor
enum AnalyticsMockData {

    /// Generate empty analytics data for zero state
    static func generateEmptyData() -> AnalyticsData {
        let metrics = AnalyticsMetrics(
            totalValue: 0,
            cardCount: 0,
            averageValue: 0,
            topCardValue: 0,
            topCardName: "N/A",
            valueChange: 0
        )

        let portfolioTrend = PortfolioTrend(
            dataPoints: [],
            totalChange: 0,
            periodLabel: "No data"
        )

        return AnalyticsData(
            metrics: metrics,
            categoryBreakdown: [],
            setBreakdown: [],
            rarityDistribution: [],
            topCards: [],
            portfolioTrend: portfolioTrend,
            insights: []
        )
    }
}
