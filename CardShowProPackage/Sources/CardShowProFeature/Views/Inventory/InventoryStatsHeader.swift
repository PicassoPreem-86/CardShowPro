import SwiftUI

struct InventoryStatsHeader: View {
    let cardCount: Int
    let totalValue: Double
    let totalInvested: Double
    let totalProfit: Double
    let averageROI: Double

    private var profitMarginPercent: Double {
        totalInvested > 0 ? (totalProfit / totalInvested * 100) : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Row: Cards and Value
            HStack(spacing: 16) {
                // Total Cards
                InventoryStatBox(
                    label: "Cards",
                    value: "\(cardCount)",
                    color: .white
                )

                // Total Value
                InventoryStatBox(
                    label: "Value",
                    value: "$\(String(format: "%.0f", totalValue))",
                    color: DesignSystem.Colors.cyan
                )

                // Total Invested
                InventoryStatBox(
                    label: "Invested",
                    value: "$\(String(format: "%.0f", totalInvested))",
                    color: DesignSystem.Colors.goldAmber
                )
            }
            .padding(.horizontal)
            .padding(.top, DesignSystem.Spacing.md)

            Divider()
                .padding(.vertical, DesignSystem.Spacing.xs)
                .padding(.horizontal)

            // Bottom Row: Profit Metrics
            HStack(spacing: 16) {
                // Total Profit
                InventoryStatBox(
                    label: "Profit",
                    value: "$\(String(format: "%.0f", totalProfit))",
                    color: totalProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error
                )

                // Average ROI
                InventoryStatBox(
                    label: "Avg ROI",
                    value: "\(String(format: "%.0f", averageROI))%",
                    color: averageROI >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error
                )

                // Profit Margin
                InventoryStatBox(
                    label: "Margin",
                    value: "\(String(format: "%.0f", profitMarginPercent))%",
                    color: profitMarginPercent >= 0 ? DesignSystem.Colors.electricBlue : DesignSystem.Colors.error
                )
            }
            .padding(.horizontal)
            .padding(.bottom, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.cardBackground)
    }
}
