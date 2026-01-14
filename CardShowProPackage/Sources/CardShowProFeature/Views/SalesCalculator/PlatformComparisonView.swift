import SwiftUI

/// Platform Comparison View - Side-by-side comparison of all selling platforms
/// Shows which platform gives the best profit for a given sale scenario
struct PlatformComparisonView: View {
    let salePrice: Decimal
    let itemCost: Decimal
    let shippingCost: Decimal
    let suppliesCost: Decimal

    @State private var comparisons: [PlatformComparison] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Input Summary Card
                    inputSummaryCard

                    // Comparison Table
                    comparisonTable

                    // Legend
                    legendCard
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Platform Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
                }
            }
            .task {
                calculateComparisons()
            }
        }
    }

    // MARK: - Input Summary Card

    private var inputSummaryCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("YOUR SCENARIO")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                summaryRow(label: "Sale Price:", value: salePrice.asCurrency, isHighlighted: true)
                summaryRow(label: "Item Cost:", value: itemCost.asCurrency)
                summaryRow(label: "Shipping Cost:", value: shippingCost.asCurrency)
                summaryRow(label: "Supplies Cost:", value: suppliesCost.asCurrency)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }

    private func summaryRow(label: String, value: String, isHighlighted: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isHighlighted ? DesignSystem.Typography.labelLarge : DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(isHighlighted ? DesignSystem.Typography.heading4.monospacedDigit() : DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(isHighlighted ? DesignSystem.Colors.thunderYellow : DesignSystem.Colors.textPrimary)
        }
    }

    // MARK: - Comparison Table

    private var comparisonTable: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("ALL PLATFORMS")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text("Ranked by profit")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            // Header Row
            comparisonHeader

            Divider()
                .background(DesignSystem.Colors.borderPrimary)

            // Platform Rows (sorted by net profit, descending)
            ForEach(comparisons.sorted { $0.netProfit > $1.netProfit }) { comparison in
                PlatformComparisonRow(
                    comparison: comparison,
                    isBestDeal: comparison.id == comparisons.max(by: { $0.netProfit < $1.netProfit })?.id
                )

                if comparison.id != comparisons.last?.id {
                    Divider()
                        .background(DesignSystem.Colors.borderPrimary.opacity(0.5))
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }

    private var comparisonHeader: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text("Platform")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Fees")
                .frame(width: 70, alignment: .trailing)

            Text("Profit")
                .frame(width: 70, alignment: .trailing)

            Text("ROI")
                .frame(width: 55, alignment: .trailing)
        }
        .font(DesignSystem.Typography.captionSmall)
        .foregroundStyle(DesignSystem.Colors.textTertiary)
        .padding(.horizontal, DesignSystem.Spacing.sm)
    }

    // MARK: - Legend Card

    private var legendCard: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)

                Text("Best platform (highest profit)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.electricBlue)

                Text("ROI = Return on Investment (profit ÷ costs)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }

    // MARK: - Calculation Logic

    private func calculateComparisons() {
        comparisons = SellingPlatform.allCases.map { platform in
            let fees = platform.feeStructure
            let platformFee = salePrice * Decimal(fees.platformFeePercentage)
            let paymentFee = (salePrice * Decimal(fees.paymentFeePercentage)) + Decimal(fees.paymentFeeFixed)
            let totalFees = platformFee + paymentFee

            let totalCosts = itemCost + shippingCost + suppliesCost
            let netProfit = salePrice - totalCosts - totalFees

            let roiPercent = totalCosts > 0
                ? Double(truncating: ((netProfit / totalCosts) * 100) as NSNumber)
                : 0.0

            return PlatformComparison(
                platform: platform,
                totalFees: totalFees,
                netProfit: netProfit,
                roiPercent: roiPercent
            )
        }
    }
}

// MARK: - Platform Comparison Model

struct PlatformComparison: Identifiable {
    let id = UUID()
    let platform: SellingPlatform
    let totalFees: Decimal
    let netProfit: Decimal
    let roiPercent: Double
}

// MARK: - Platform Comparison Row

private struct PlatformComparisonRow: View {
    let comparison: PlatformComparison
    let isBestDeal: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Platform name with best deal indicator
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isBestDeal {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignSystem.Colors.thunderYellow)
                }

                Text(comparison.platform.rawValue)
                    .font(isBestDeal ? DesignSystem.Typography.labelLarge : DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Total Fees
            Text(comparison.totalFees.asCurrency)
                .font(DesignSystem.Typography.bodySmall.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.error)
                .frame(width: 70, alignment: .trailing)

            // Net Profit
            Text(comparison.netProfit.asCurrency)
                .font(isBestDeal ? DesignSystem.Typography.labelLarge.monospacedDigit() : DesignSystem.Typography.body.monospacedDigit())
                .foregroundStyle(
                    comparison.netProfit > 0
                        ? (isBestDeal ? DesignSystem.Colors.success : DesignSystem.Colors.success.opacity(0.8))
                        : DesignSystem.Colors.error
                )
                .frame(width: 70, alignment: .trailing)

            // ROI
            Text(comparison.roiPercent.asPercentage)
                .font(DesignSystem.Typography.bodySmall.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(width: 55, alignment: .trailing)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            isBestDeal
                ? DesignSystem.Colors.thunderYellow.opacity(0.1)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(comparison.platform.rawValue): \(comparison.netProfit.asCurrency) profit, \(comparison.totalFees.asCurrency) fees, \(comparison.roiPercent.asPercentage) ROI\(isBestDeal ? ", best deal" : "")")
    }
}

#Preview("Platform Comparison - Standard") {
    PlatformComparisonView(
        salePrice: 100.00,
        itemCost: 50.00,
        shippingCost: 3.00,
        suppliesCost: 2.00
    )
}

#Preview("Platform Comparison - High Value") {
    PlatformComparisonView(
        salePrice: 500.00,
        itemCost: 200.00,
        shippingCost: 0.00,
        suppliesCost: 5.00
    )
}

#Preview("Platform Comparison - Negative Profit") {
    PlatformComparisonView(
        salePrice: 50.00,
        itemCost: 100.00,
        shippingCost: 5.00,
        suppliesCost: 2.00
    )
}
