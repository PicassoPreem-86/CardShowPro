import SwiftUI

/// Itemized fee breakdown
struct FeeBreakdownSection: View {
    let result: CalculationResult

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            SectionHeader(title: "Fee Breakdown")

            VStack(spacing: 0) {
                FeeRow(
                    label: "Platform Fee",
                    percentage: result.platformFeePercentage,
                    amount: result.platformFee
                )

                Divider()
                    .background(DesignSystem.Colors.borderPrimary)

                FeeRow(
                    label: "Payment Fee",
                    percentage: result.paymentFeePercentage,
                    amount: result.paymentFee
                )

                Divider()
                    .background(DesignSystem.Colors.borderPrimary)

                FeeRow(
                    label: "Shipping Cost",
                    percentage: nil,
                    amount: result.shippingCost
                )

                Divider()
                    .background(DesignSystem.Colors.borderPrimary)
                    .padding(.vertical, DesignSystem.Spacing.xs)

                // Total Fees
                HStack {
                    Text("Total Fees")
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Spacer()

                    Text(result.totalFees.asCurrency)
                        .font(DesignSystem.Typography.heading4.monospacedDigit())
                        .foregroundStyle(DesignSystem.Colors.error)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
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
}

// MARK: - Fee Row

struct FeeRow: View {
    let label: String
    let percentage: Double?
    let amount: Decimal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(label)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if let percentage = percentage {
                    Text((percentage * 100).asPercentage)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer()

            Text(amount.asCurrency)
                .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}
