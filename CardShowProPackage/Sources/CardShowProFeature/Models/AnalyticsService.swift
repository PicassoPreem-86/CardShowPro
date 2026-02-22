import Foundation

/// Service that computes analytics from real SwiftData inventory and transaction data.
/// Replaces hardcoded mock data with live computed metrics.
@Observable
@MainActor
final class AnalyticsService: Sendable {

    /// Compute full analytics from real inventory cards and transactions
    func computeAnalytics(cards: [InventoryCard], transactions: [Transaction]) -> AnalyticsData {
        let activeCards = cards.filter { $0.isAvailable }
        let soldCards = cards.filter { $0.isSold }

        let metrics = computeMetrics(activeCards: activeCards, soldCards: soldCards, transactions: transactions)
        let categoryBreakdown = computeCategoryBreakdown(activeCards: activeCards)
        let setBreakdown = computeSetBreakdown(activeCards: activeCards)
        let rarityDistribution = computeRarityDistribution(activeCards: activeCards)
        let topCards = computeTopCards(activeCards: activeCards)
        let portfolioTrend = computePortfolioTrend(cards: cards, transactions: transactions)
        let insights = computeInsights(activeCards: activeCards, soldCards: soldCards, transactions: transactions)

        return AnalyticsData(
            metrics: metrics,
            categoryBreakdown: categoryBreakdown,
            setBreakdown: setBreakdown,
            rarityDistribution: rarityDistribution,
            topCards: topCards,
            portfolioTrend: portfolioTrend,
            insights: insights
        )
    }

    // MARK: - Hero Metrics

    private func computeMetrics(
        activeCards: [InventoryCard],
        soldCards: [InventoryCard],
        transactions: [Transaction]
    ) -> AnalyticsMetrics {
        let totalValue = activeCards.reduce(0.0) { $0 + $1.marketValue }
        let cardCount = activeCards.count
        let averageValue = cardCount > 0 ? totalValue / Double(cardCount) : 0

        let topCard = activeCards.max(by: { $0.marketValue < $1.marketValue })
        let topCardValue = topCard?.marketValue ?? 0
        let topCardName = topCard?.cardName ?? "N/A"

        // Value change: compare total invested vs current value for unrealized gain %
        let totalInvested = activeCards.reduce(0.0) { $0 + ($1.purchaseCost ?? 0) }
        let valueChange: Double
        if totalInvested > 0 {
            valueChange = (totalValue - totalInvested) / totalInvested
        } else {
            valueChange = 0
        }

        return AnalyticsMetrics(
            totalValue: totalValue,
            cardCount: cardCount,
            averageValue: averageValue,
            topCardValue: topCardValue,
            topCardName: topCardName,
            valueChange: valueChange
        )
    }

    // MARK: - Category Breakdown

    private func computeCategoryBreakdown(activeCards: [InventoryCard]) -> [CategoryBreakdown] {
        let totalValue = activeCards.reduce(0.0) { $0 + $1.marketValue }
        guard totalValue > 0 else { return [] }

        let grouped = Dictionary(grouping: activeCards, by: { $0.category })
        return grouped.map { category, cards in
            let catValue = cards.reduce(0.0) { $0 + $1.marketValue }
            return CategoryBreakdown(
                category: category,
                cardCount: cards.count,
                totalValue: catValue,
                percentage: catValue / totalValue
            )
        }
        .sorted { $0.totalValue > $1.totalValue }
    }

    // MARK: - Set Breakdown

    private func computeSetBreakdown(activeCards: [InventoryCard]) -> [SetBreakdown] {
        let grouped = Dictionary(grouping: activeCards, by: { $0.setName })
        return grouped.map { setName, cards in
            let setTotal = cards.reduce(0.0) { $0 + $1.marketValue }
            return SetBreakdown(
                setName: setName,
                cardCount: cards.count,
                totalValue: setTotal,
                averageValue: cards.isEmpty ? 0 : setTotal / Double(cards.count)
            )
        }
        .sorted { $0.totalValue > $1.totalValue }
    }

    // MARK: - Rarity Distribution (by condition as proxy)

    private func computeRarityDistribution(activeCards: [InventoryCard]) -> [RarityDistribution] {
        let grouped = Dictionary(grouping: activeCards, by: { $0.condition })
        return grouped.map { condition, cards in
            RarityDistribution(
                rarity: condition,
                cardCount: cards.count,
                totalValue: cards.reduce(0.0) { $0 + $1.marketValue }
            )
        }
        .sorted { $0.totalValue > $1.totalValue }
    }

    // MARK: - Top Cards

    private func computeTopCards(activeCards: [InventoryCard]) -> [TopCard] {
        activeCards
            .sorted { $0.marketValue > $1.marketValue }
            .prefix(5)
            .map { card in
                let change: Double
                if let cost = card.purchaseCost, cost > 0 {
                    change = (card.marketValue - cost) / cost
                } else {
                    change = 0
                }
                return TopCard(
                    cardName: card.cardName,
                    setName: card.setName,
                    value: card.marketValue,
                    change: change
                )
            }
    }

    // MARK: - Portfolio Trend

    private func computePortfolioTrend(cards: [InventoryCard], transactions: [Transaction]) -> PortfolioTrend {
        let calendar = Calendar.current
        let today = Date()

        // Build a timeline of cumulative portfolio value based on card acquisition dates
        // and sale dates over the past 90 days
        let daysBack = 90
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: today) else {
            return PortfolioTrend(dataPoints: [], totalChange: 0, periodLabel: "90 days")
        }

        var dataPoints: [TimeSeriesDataPoint] = []

        for dayOffset in 0...daysBack {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            // Cards that were in inventory on this date:
            // acquired before or on this date AND (not sold OR sold after this date)
            let activeOnDate = cards.filter { card in
                let acquired = card.acquisitionDate ?? card.timestamp
                let acquiredBefore = acquired <= date
                if let soldDate = card.soldDate {
                    return acquiredBefore && soldDate > date
                }
                return acquiredBefore
            }

            let dayValue = activeOnDate.reduce(0.0) { $0 + $1.marketValue }
            dataPoints.append(TimeSeriesDataPoint(date: date, value: dayValue))
        }

        let totalChange: Double
        if let first = dataPoints.first, let last = dataPoints.last, first.value > 0 {
            totalChange = (last.value - first.value) / first.value
        } else {
            totalChange = 0
        }

        return PortfolioTrend(
            dataPoints: dataPoints,
            totalChange: totalChange,
            periodLabel: "90 days"
        )
    }

    // MARK: - Sales Velocity

    /// Cards sold and revenue per week over a given period
    func salesVelocity(transactions: [Transaction], period: Int = 30) -> (cardsPerWeek: Double, revenuePerWeek: Double) {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -period, to: Date()) else {
            return (0, 0)
        }
        let recentSales = transactions.filter { $0.transactionType == .sale && $0.date >= cutoff }
        let weeks = max(Double(period) / 7.0, 1.0)
        let cardsPerWeek = Double(recentSales.count) / weeks
        let revenuePerWeek = recentSales.reduce(0.0) { $0 + $1.netAmount } / weeks
        return (cardsPerWeek: cardsPerWeek, revenuePerWeek: revenuePerWeek)
    }

    // MARK: - Sell-Through Rate

    /// Ratio of sold cards to sold + listed cards
    func sellThroughRate(cards: [InventoryCard]) -> Double {
        let soldCount = cards.filter { $0.isSold }.count
        let listedCount = cards.filter { $0.cardStatus == .listed }.count
        let total = soldCount + listedCount
        guard total > 0 else { return 0 }
        return Double(soldCount) / Double(total)
    }

    // MARK: - Average Days to Sale

    /// Average number of days between listing and sale for sold cards
    func averageDaysToSale(cards: [InventoryCard]) -> Double? {
        let soldWithDates = cards.filter { $0.isSold && $0.listedDate != nil && $0.soldDate != nil }
        guard !soldWithDates.isEmpty else { return nil }
        let calendar = Calendar.current
        let totalDays = soldWithDates.reduce(0) { sum, card in
            let days = calendar.dateComponents([.day], from: card.listedDate!, to: card.soldDate!).day ?? 0
            return sum + max(days, 0)
        }
        return Double(totalDays) / Double(soldWithDates.count)
    }

    // MARK: - Inventory Turnover

    /// Revenue divided by average inventory value
    func inventoryTurnover(cards: [InventoryCard], transactions: [Transaction]) -> Double {
        let revenue = transactions.filter { $0.transactionType == .sale }.reduce(0.0) { $0 + $1.netAmount }
        let currentValue = cards.filter { $0.isAvailable }.reduce(0.0) { $0 + $1.marketValue }
        let soldValue = cards.filter { $0.isSold }.reduce(0.0) { $0 + ($1.purchaseCost ?? 0) }
        let avgInventory = (currentValue + soldValue) / 2.0
        guard avgInventory > 0 else { return 0 }
        return revenue / avgInventory
    }

    // MARK: - Realized Profit

    /// Sum of profit from completed sale transactions only
    func realizedProfit(transactions: [Transaction]) -> Double {
        transactions.filter { $0.transactionType == .sale }.reduce(0.0) { $0 + $1.profit }
    }

    // MARK: - Platform Profitability

    struct PlatformMetrics: Sendable, Identifiable {
        let id = UUID()
        let platform: String
        let revenue: Double
        let fees: Double
        let netProfit: Double
        let saleCount: Int
        let averageSale: Double
    }

    /// Profitability breakdown by sales platform
    func platformProfitability(transactions: [Transaction]) -> [PlatformMetrics] {
        let sales = transactions.filter { $0.transactionType == .sale }
        let grouped = Dictionary(grouping: sales, by: { $0.platform ?? "Unknown" })
        return grouped.map { platform, txns in
            let revenue = txns.reduce(0.0) { $0 + $1.amount }
            let fees = txns.reduce(0.0) { $0 + $1.platformFees }
            let netProfit = txns.reduce(0.0) { $0 + $1.profit }
            let avgSale = txns.isEmpty ? 0 : revenue / Double(txns.count)
            return PlatformMetrics(
                platform: platform,
                revenue: revenue,
                fees: fees,
                netProfit: netProfit,
                saleCount: txns.count,
                averageSale: avgSale
            )
        }
        .sorted { $0.netProfit > $1.netProfit }
    }

    // MARK: - Acquisition Source ROI

    /// Average ROI grouped by acquisition source
    func acquisitionSourceROI(cards: [InventoryCard]) -> [(source: String, avgROI: Double, cardCount: Int)] {
        let cardsWithSource = cards.filter { $0.acquisitionSource != nil && $0.purchaseCost != nil }
        let grouped = Dictionary(grouping: cardsWithSource, by: { $0.acquisitionSource ?? "Unknown" })
        return grouped.map { source, group in
            let avgROI = group.isEmpty ? 0 : group.reduce(0.0) { $0 + $1.roi } / Double(group.count)
            return (source: source, avgROI: avgROI, cardCount: group.count)
        }
        .sorted { $0.avgROI > $1.avgROI }
    }

    // MARK: - Period Comparison

    struct PeriodComparison: Sendable {
        let currentRevenue: Double
        let previousRevenue: Double
        let currentProfit: Double
        let previousProfit: Double
        let currentCardsSold: Int
        let previousCardsSold: Int

        var revenueChange: Double {
            guard previousRevenue > 0 else { return 0 }
            return (currentRevenue - previousRevenue) / previousRevenue
        }

        var profitChange: Double {
            guard previousProfit != 0 else { return 0 }
            return (currentProfit - previousProfit) / abs(previousProfit)
        }
    }

    /// Compare current period vs previous period of the same length
    func periodComparison(transactions: [Transaction], periodDays: Int = 30) -> PeriodComparison {
        let calendar = Calendar.current
        let now = Date()
        guard let periodStart = calendar.date(byAdding: .day, value: -periodDays, to: now),
              let previousStart = calendar.date(byAdding: .day, value: -(periodDays * 2), to: now) else {
            return PeriodComparison(currentRevenue: 0, previousRevenue: 0, currentProfit: 0, previousProfit: 0, currentCardsSold: 0, previousCardsSold: 0)
        }

        let sales = transactions.filter { $0.transactionType == .sale }
        let currentSales = sales.filter { $0.date >= periodStart && $0.date <= now }
        let previousSales = sales.filter { $0.date >= previousStart && $0.date < periodStart }

        return PeriodComparison(
            currentRevenue: currentSales.reduce(0.0) { $0 + $1.netAmount },
            previousRevenue: previousSales.reduce(0.0) { $0 + $1.netAmount },
            currentProfit: currentSales.reduce(0.0) { $0 + $1.profit },
            previousProfit: previousSales.reduce(0.0) { $0 + $1.profit },
            currentCardsSold: currentSales.count,
            previousCardsSold: previousSales.count
        )
    }

    // MARK: - Inventory Age Buckets

    /// Group inventory cards by age into buckets
    func inventoryAgeBuckets(cards: [InventoryCard]) -> [(label: String, count: Int, value: Double)] {
        let active = cards.filter { $0.isAvailable }

        let bucket0to30 = active.filter { $0.daysInInventory <= 30 }
        let bucket31to60 = active.filter { $0.daysInInventory > 30 && $0.daysInInventory <= 60 }
        let bucket61to90 = active.filter { $0.daysInInventory > 60 && $0.daysInInventory <= 90 }
        let bucket90plus = active.filter { $0.daysInInventory > 90 }

        return [
            (label: "0-30d", count: bucket0to30.count, value: bucket0to30.reduce(0.0) { $0 + $1.marketValue }),
            (label: "31-60d", count: bucket31to60.count, value: bucket31to60.reduce(0.0) { $0 + $1.marketValue }),
            (label: "61-90d", count: bucket61to90.count, value: bucket61to90.reduce(0.0) { $0 + $1.marketValue }),
            (label: "90d+", count: bucket90plus.count, value: bucket90plus.reduce(0.0) { $0 + $1.marketValue })
        ]
    }

    // MARK: - Refund Rate

    /// Ratio of refund transactions to sale transactions
    func refundRate(transactions: [Transaction]) -> Double {
        let saleCount = transactions.filter { $0.transactionType == .sale }.count
        let refundCount = transactions.filter { $0.transactionType == .refund }.count
        guard saleCount > 0 else { return 0 }
        return Double(refundCount) / Double(saleCount)
    }

    // MARK: - Cumulative Profit Timeline

    /// Returns a time series of cumulative realized profit from sales
    func cumulativeProfitTimeline(transactions: [Transaction]) -> [TimeSeriesDataPoint] {
        let sales = transactions.filter { $0.transactionType == .sale }.sorted { $0.date < $1.date }
        var runningTotal = 0.0
        return sales.map { txn in
            runningTotal += txn.profit
            return TimeSeriesDataPoint(date: txn.date, value: runningTotal)
        }
    }

    // MARK: - Weekly Sales Counts

    /// Returns cards sold per week as a time series
    func weeklySalesCounts(transactions: [Transaction], weeks: Int = 12) -> [(weekLabel: String, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -weeks, to: now) else { return [] }

        let sales = transactions.filter { $0.transactionType == .sale && $0.date >= startDate }

        var result: [(weekLabel: String, count: Int)] = []
        for weekOffset in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate),
                  let weekEnd = calendar.date(byAdding: .weekOfYear, value: weekOffset + 1, to: startDate) else { continue }
            let count = sales.filter { $0.date >= weekStart && $0.date < weekEnd }.count
            let label = weekStart.formatted(.dateTime.month(.abbreviated).day())
            result.append((weekLabel: label, count: count))
        }
        return result
    }

    // MARK: - Insights

    private func computeInsights(
        activeCards: [InventoryCard],
        soldCards: [InventoryCard],
        transactions: [Transaction]
    ) -> [AnalyticsInsight] {
        var insights: [AnalyticsInsight] = []

        // Slow movers: cards in stock 90+ days
        let slowMovers = activeCards.filter { $0.daysInInventory >= 90 }
        if !slowMovers.isEmpty {
            insights.append(AnalyticsInsight(
                title: "Slow-Moving Inventory",
                description: "\(slowMovers.count) card\(slowMovers.count == 1 ? " has" : "s have") been in stock for 90+ days. Consider repricing or bundling.",
                category: .warning,
                priority: .high
            ))
        }

        // Graded vs raw comparison
        let gradedCards = activeCards.filter { $0.isGraded }
        let rawCards = activeCards.filter { !$0.isGraded }
        if !gradedCards.isEmpty && !rawCards.isEmpty {
            let gradedAvg = gradedCards.reduce(0.0) { $0 + $1.marketValue } / Double(gradedCards.count)
            let rawAvg = rawCards.reduce(0.0) { $0 + $1.marketValue } / Double(rawCards.count)
            if gradedAvg > rawAvg {
                let multiplier = String(format: "%.1fx", gradedAvg / rawAvg)
                insights.append(AnalyticsInsight(
                    title: "Graded Cards Outperform",
                    description: "Your graded cards average \(multiplier) the value of raw singles. Consider grading high-value raw cards.",
                    category: .opportunity,
                    priority: .medium
                ))
            }
        }

        // Top set concentration
        let grouped = Dictionary(grouping: activeCards, by: { $0.setName })
        if let topSet = grouped.max(by: { $0.value.count < $1.value.count }), activeCards.count > 5 {
            let pct = Int(Double(topSet.value.count) / Double(activeCards.count) * 100)
            if pct > 40 {
                insights.append(AnalyticsInsight(
                    title: "Portfolio Concentration",
                    description: "\(pct)% of your cards are from \(topSet.key). Consider diversifying across sets.",
                    category: .recommendation,
                    priority: .medium
                ))
            }
        }

        // Profitable sales trend
        let saleTxns = transactions.filter { $0.transactionType == .sale }
        let profitableSales = saleTxns.filter { $0.profit > 0 }
        if saleTxns.count >= 3 {
            let winRate = Int(Double(profitableSales.count) / Double(saleTxns.count) * 100)
            insights.append(AnalyticsInsight(
                title: "Sales Win Rate",
                description: "\(winRate)% of your \(saleTxns.count) sales were profitable.",
                category: .trend,
                priority: .low
            ))
        }

        // High ROI cards
        let highROI = activeCards.filter { $0.roi > 50 }
        if !highROI.isEmpty {
            insights.append(AnalyticsInsight(
                title: "High ROI Opportunity",
                description: "\(highROI.count) card\(highROI.count == 1 ? " has" : "s have") over 50% ROI. Consider selling to lock in gains.",
                category: .opportunity,
                priority: .high
            ))
        }

        return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}
