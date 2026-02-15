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
