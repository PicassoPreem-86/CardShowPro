import Foundation

/// Mock data generator for analytics dashboard
/// Provides realistic Pokemon card collection data for testing and UI development
@MainActor
enum AnalyticsMockData {

    /// Generate complete analytics data with realistic values
    static func generateMockData() -> AnalyticsData {
        let metrics = AnalyticsMetrics(
            totalValue: 5432.50,
            cardCount: 150,
            averageValue: 36.22,
            topCardValue: 485.00,
            topCardName: "Charizard VSTAR",
            valueChange: 0.087 // +8.7%
        )

        let categoryBreakdown = [
            CategoryBreakdown(
                category: "Raw Singles",
                cardCount: 105,
                totalValue: 3802.75,
                percentage: 0.70
            ),
            CategoryBreakdown(
                category: "Graded Cards",
                cardCount: 30,
                totalValue: 1086.50,
                percentage: 0.20
            ),
            CategoryBreakdown(
                category: "Sealed Products",
                cardCount: 15,
                totalValue: 543.25,
                percentage: 0.10
            )
        ]

        let setBreakdown = [
            SetBreakdown(
                setName: "Crown Zenith",
                cardCount: 25,
                totalValue: 892.50,
                averageValue: 35.70
            ),
            SetBreakdown(
                setName: "Obsidian Flames",
                cardCount: 20,
                totalValue: 734.00,
                averageValue: 36.70
            ),
            SetBreakdown(
                setName: "151",
                cardCount: 18,
                totalValue: 1245.00,
                averageValue: 69.17
            ),
            SetBreakdown(
                setName: "Paldean Fates",
                cardCount: 22,
                totalValue: 658.00,
                averageValue: 29.91
            ),
            SetBreakdown(
                setName: "Temporal Forces",
                cardCount: 15,
                totalValue: 425.00,
                averageValue: 28.33
            ),
            SetBreakdown(
                setName: "Twilight Masquerade",
                cardCount: 18,
                totalValue: 534.00,
                averageValue: 29.67
            ),
            SetBreakdown(
                setName: "Shrouded Fable",
                cardCount: 12,
                totalValue: 378.00,
                averageValue: 31.50
            ),
            SetBreakdown(
                setName: "Stellar Crown",
                cardCount: 20,
                totalValue: 566.00,
                averageValue: 28.30
            )
        ]

        let rarityDistribution = [
            RarityDistribution(
                rarity: "Common",
                cardCount: 45,
                totalValue: 225.00
            ),
            RarityDistribution(
                rarity: "Uncommon",
                cardCount: 35,
                totalValue: 350.00
            ),
            RarityDistribution(
                rarity: "Rare",
                cardCount: 30,
                totalValue: 750.00
            ),
            RarityDistribution(
                rarity: "Ultra Rare",
                cardCount: 25,
                totalValue: 1875.00
            ),
            RarityDistribution(
                rarity: "Secret Rare",
                cardCount: 15,
                totalValue: 2232.50
            )
        ]

        let topCards = [
            TopCard(
                cardName: "Charizard VSTAR",
                setName: "151",
                value: 485.00,
                change: 0.112
            ),
            TopCard(
                cardName: "Umbreon VMAX",
                setName: "Crown Zenith",
                value: 342.00,
                change: 0.085
            ),
            TopCard(
                cardName: "Mew VMAX",
                setName: "151",
                value: 298.50,
                change: 0.067
            ),
            TopCard(
                cardName: "Pikachu VMAX",
                setName: "Obsidian Flames",
                value: 245.00,
                change: -0.032
            ),
            TopCard(
                cardName: "Lugia VSTAR",
                setName: "Crown Zenith",
                value: 212.00,
                change: 0.045
            )
        ]

        // Generate 90 days of trend data with realistic growth
        let calendar = Calendar.current
        let today = Date()
        var dataPoints: [TimeSeriesDataPoint] = []

        let startValue = 4800.0
        let endValue = 5432.50
        let totalDays = 90

        for dayOffset in 0..<totalDays {
            guard let date = calendar.date(byAdding: .day, value: -totalDays + dayOffset, to: today) else {
                continue
            }

            // Add some realistic volatility
            let progress = Double(dayOffset) / Double(totalDays)
            let baseValue = startValue + (endValue - startValue) * progress
            let volatility = Double.random(in: -100...100)
            let value = baseValue + volatility

            dataPoints.append(TimeSeriesDataPoint(date: date, value: value))
        }

        let portfolioTrend = PortfolioTrend(
            dataPoints: dataPoints,
            totalChange: 0.132, // +13.2%
            periodLabel: "90 days"
        )

        let insights = [
            AnalyticsInsight(
                title: "Strong Growth in 151 Set",
                description: "Your 151 set cards have appreciated 15.2% in the last 30 days. Consider acquiring more from this set.",
                category: .opportunity,
                priority: .high
            ),
            AnalyticsInsight(
                title: "Diversify Graded Cards",
                description: "Only 20% of your portfolio is graded. PSA 10 cards typically appreciate faster.",
                category: .recommendation,
                priority: .medium
            ),
            AnalyticsInsight(
                title: "Market Cooling on Pikachu VMAX",
                description: "Pikachu VMAX from Obsidian Flames down 3.2%. Consider holding or selling.",
                category: .warning,
                priority: .low
            ),
            AnalyticsInsight(
                title: "Ultra Rare Performance",
                description: "Your Ultra Rare cards are outperforming the market by 8.5%.",
                category: .trend,
                priority: .medium
            )
        ]

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
