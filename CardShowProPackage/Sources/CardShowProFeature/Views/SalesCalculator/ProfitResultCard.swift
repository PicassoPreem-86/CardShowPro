import SwiftUI

/// Large result card displaying Net Profit for Forward Mode
/// Hero metric with color-coded status and detailed breakdown
struct ProfitResultCard: View {
    let result: ForwardCalculationResult

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Text("NET PROFIT")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                StatusBadge(status: result.profitStatus)
            }

            // HERO: Net Profit Amount
            Text(result.netProfit.asCurrency)
                .font(DesignSystem.Typography.displayLarge.monospacedDigit())
                .foregroundStyle(profitColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.lg)
                .accessibilityLabel("Net profit: \(result.netProfit.asCurrency)")
                .accessibilityAddTraits(.updatesFrequently)
                .accessibilityIdentifier("profit-amount-label")

            // Warning Banner for Negative Profit
            if !result.isProfitable {
                WarningBanner(result: result)
            }

            // Metrics Grid
            HStack(spacing: DesignSystem.Spacing.sm) {
                MetricCard(
                    label: "MARGIN",
                    value: result.profitMarginPercent.asPercentage,
                    color: profitColor,
                    icon: "chart.line.uptrend.xyaxis"
                )

                MetricCard(
                    label: "ROI",
                    value: result.roiPercent.asPercentage,
                    color: profitColor,
                    icon: "arrow.up.right.circle.fill"
                )
            }

            // Quick Summary
            QuickSummary(result: result)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.cardBackground,
                    DesignSystem.Colors.premiumCardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [borderColor.opacity(0.5), borderColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(
            color: DesignSystem.Shadows.level4.color,
            radius: DesignSystem.Shadows.level4.radius,
            x: DesignSystem.Shadows.level4.x,
            y: DesignSystem.Shadows.level4.y
        )
        // Colored accent bar on left
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(profitColor)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        }
    }

    // MARK: - Color Logic

    private var profitColor: Color {
        switch result.profitStatus {
        case .profitable:
            return DesignSystem.Colors.success
        case .breakeven:
            return DesignSystem.Colors.textSecondary
        case .loss:
            return DesignSystem.Colors.error
        }
    }

    private var borderColor: Color {
        switch result.profitStatus {
        case .profitable:
            return DesignSystem.Colors.success
        case .breakeven:
            return DesignSystem.Colors.textSecondary
        case .loss:
            return DesignSystem.Colors.error
        }
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: ProfitStatus

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxxs) {
            Image(systemName: iconName)
                .font(.caption2)

            Text(statusText)
                .font(DesignSystem.Typography.captionBold)
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, DesignSystem.Spacing.xxxs)
        .background(statusColor.opacity(0.2))
        .clipShape(Capsule())
        .accessibilityLabel("Status: \(statusText)")
    }

    private var statusText: String {
        switch status {
        case .profitable: return "PROFITABLE"
        case .breakeven: return "BREAK EVEN"
        case .loss: return "LOSS"
        }
    }

    private var statusColor: Color {
        switch status {
        case .profitable: return DesignSystem.Colors.success
        case .breakeven: return DesignSystem.Colors.textSecondary
        case .loss: return DesignSystem.Colors.error
        }
    }

    private var iconName: String {
        switch status {
        case .profitable: return "checkmark.circle.fill"
        case .breakeven: return "minus.circle.fill"
        case .loss: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Warning Banner

private struct WarningBanner: View {
    let result: ForwardCalculationResult

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DesignSystem.Colors.error)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(warningTitle)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.error)

                Text(warningMessage)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var warningTitle: String {
        result.profitStatus == .breakeven ? "Break Even" : "You Will Lose Money"
    }

    private var warningMessage: String {
        if result.profitStatus == .breakeven {
            return "No profit after fees and costs"
        } else {
            let loss = abs(result.netProfit)
            return "You will lose \(loss.asCurrency) on this sale"
        }
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let label: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(DesignSystem.Typography.captionBold)
            }
            .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(value)
                .font(DesignSystem.Typography.heading2.monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Quick Summary

private struct QuickSummary: View {
    let result: ForwardCalculationResult

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Divider()
                .background(DesignSystem.Colors.borderPrimary)

            SummaryRow(label: "Sale Price", value: result.salePrice.asCurrency)
            SummaryRow(label: "Total Costs", value: result.totalCosts.asCurrency, isNegative: true)
            SummaryRow(label: "Total Fees", value: result.totalFees.asCurrency, isNegative: true)

            Divider()
                .background(DesignSystem.Colors.borderPrimary)

            SummaryRow(
                label: "Net Profit",
                value: result.netProfit.asCurrency,
                isBold: true,
                valueColor: result.netProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error
            )
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundTertiary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
}

// MARK: - Summary Row

private struct SummaryRow: View {
    let label: String
    let value: String
    var isNegative: Bool = false
    var isBold: Bool = false
    var valueColor: Color?

    var body: some View {
        HStack {
            Text(label)
                .font(isBold ? DesignSystem.Typography.labelLarge : DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Text(displayValue)
                .font(isBold ? DesignSystem.Typography.labelLarge.monospacedDigit() : DesignSystem.Typography.body.monospacedDigit())
                .foregroundStyle(valueColor ?? DesignSystem.Colors.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var displayValue: String {
        isNegative ? "- \(value)" : value
    }
}

#Preview("Profit Result - Profitable") {
    let result = ForwardCalculationResult(
        salePrice: 100.00,
        itemCost: 50.00,
        shippingCost: 5.00,
        suppliesCost: 2.00,
        totalCosts: 57.00,
        platformFee: 12.95,
        platformFeePercentage: 0.1295,
        paymentFee: 3.20,
        paymentFeePercentage: 0.029,
        totalFees: 21.15,
        netProfit: 21.85,
        profitMarginPercent: 21.85,
        roiPercent: 38.33
    )

    ProfitResultCard(result: result)
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Profit Result - Loss") {
    let result = ForwardCalculationResult(
        salePrice: 50.00,
        itemCost: 45.00,
        shippingCost: 5.00,
        suppliesCost: 2.00,
        totalCosts: 52.00,
        platformFee: 6.48,
        platformFeePercentage: 0.1295,
        paymentFee: 1.75,
        paymentFeePercentage: 0.029,
        totalFees: 13.23,
        netProfit: -15.23,
        profitMarginPercent: -30.46,
        roiPercent: -29.29
    )

    ProfitResultCard(result: result)
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}
