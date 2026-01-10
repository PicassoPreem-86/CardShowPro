import Foundation

// MARK: - Analytics Metrics

/// Hero metrics displayed at the top of the analytics dashboard
struct AnalyticsMetrics: Sendable {
    let totalValue: Double
    let cardCount: Int
    let averageValue: Double
    let topCardValue: Double
    let topCardName: String
    let valueChange: Double // Percentage change (e.g., 0.087 for +8.7%)
}

// MARK: - Category Breakdown

/// Distribution of cards and value by category
struct CategoryBreakdown: Sendable, Identifiable {
    let id = UUID()
    let category: String
    let cardCount: Int
    let totalValue: Double
    let percentage: Double // Percentage of total value
}

// MARK: - Set Breakdown

/// Performance metrics for a specific Pokemon set
struct SetBreakdown: Sendable, Identifiable {
    let id = UUID()
    let setName: String
    let cardCount: Int
    let totalValue: Double
    let averageValue: Double
}

// MARK: - Rarity Distribution

/// Distribution of cards by rarity level
struct RarityDistribution: Sendable, Identifiable {
    let id = UUID()
    let rarity: String
    let cardCount: Int
    let totalValue: Double
}

// MARK: - Top Card

/// Top performing card in the collection
struct TopCard: Sendable, Identifiable {
    let id = UUID()
    let cardName: String
    let setName: String
    let value: Double
    let change: Double // Percentage change
}

// MARK: - Time Series Data Point

/// Data point for trend charts
struct TimeSeriesDataPoint: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Portfolio Trend

/// Portfolio value trend over time
struct PortfolioTrend: Sendable {
    let dataPoints: [TimeSeriesDataPoint]
    let totalChange: Double // Percentage change over period
    let periodLabel: String // e.g., "90 days"
}

// MARK: - Analytics Insight

/// Smart recommendation or insight
struct AnalyticsInsight: Sendable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: InsightCategory
    let priority: InsightPriority
}

enum InsightCategory: String, Sendable {
    case opportunity = "Opportunity"
    case warning = "Warning"
    case trend = "Trend"
    case recommendation = "Recommendation"
}

enum InsightPriority: Int, Sendable {
    case low = 1
    case medium = 2
    case high = 3
}

// MARK: - Analytics Data Container

/// Container for all analytics data
struct AnalyticsData: Sendable {
    let metrics: AnalyticsMetrics
    let categoryBreakdown: [CategoryBreakdown]
    let setBreakdown: [SetBreakdown]
    let rarityDistribution: [RarityDistribution]
    let topCards: [TopCard]
    let portfolioTrend: PortfolioTrend
    let insights: [AnalyticsInsight]
}
