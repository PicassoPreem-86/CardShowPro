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
