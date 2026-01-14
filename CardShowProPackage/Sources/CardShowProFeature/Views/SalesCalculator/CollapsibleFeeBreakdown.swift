import SwiftUI

/// Collapsible fee breakdown card for Forward Mode
/// Shows detailed platform and payment fees with expand/collapse functionality
struct CollapsibleFeeBreakdown: View {
    let result: ForwardCalculationResult
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .frame(width: 12)

                        Text("FEE BREAKDOWN")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    Spacer()

                    Text("Total: \(result.totalFees.asCurrency)")
                        .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                        .foregroundStyle(DesignSystem.Colors.error)
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fee breakdown, total fees: \(result.totalFees.asCurrency)")
            .accessibilityHint(isExpanded ? "Collapse fee details" : "Expand fee details")

            // Expanded Content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .background(DesignSystem.Colors.borderPrimary)

                    VStack(spacing: 0) {
                        FeeDetailRow(
                            label: "Platform Fee",
                            percentage: result.platformFeePercentage,
                            amount: result.platformFee
                        )

                        Divider()
                            .background(DesignSystem.Colors.borderPrimary)
                            .padding(.horizontal, DesignSystem.Spacing.md)

                        FeeDetailRow(
                            label: "Payment Fee",
                            percentage: result.paymentFeePercentage,
                            amount: result.paymentFee
                        )

                        if result.shippingCost > 0 {
                            Divider()
                                .background(DesignSystem.Colors.borderPrimary)
                                .padding(.horizontal, DesignSystem.Spacing.md)

                            FeeDetailRow(
                                label: "Shipping Cost",
                                percentage: nil,
                                amount: result.shippingCost
                            )
                        }

                        Divider()
                            .background(DesignSystem.Colors.borderPrimary)
                            .padding(.vertical, DesignSystem.Spacing.xs)

                        // Total Fees Row
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

                        // Fee Percentage of Sale
                        FeePercentageIndicator(result: result)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }
                .background(DesignSystem.Colors.cardBackground)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }
}

// MARK: - Fee Detail Row

private struct FeeDetailRow: View {
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
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Fee Percentage Indicator

private struct FeePercentageIndicator: View {
    let result: ForwardCalculationResult

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("Fees as % of Sale")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Spacer()

                Text(feePercentage.asPercentage)
                    .font(DesignSystem.Typography.labelSmall.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.warning)
            }

            // Visual bar indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.backgroundTertiary)

                    // Fee percentage
                    RoundedRectangle(cornerRadius: 2)
                        .fill(feeColor)
                        .frame(width: geometry.size.width * CGFloat(feePercentage / 100))
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fees are \(feePercentage.asPercentage) of sale price")
    }

    private var feePercentage: Double {
        guard result.salePrice > 0 else { return 0 }
        return Double(truncating: ((result.totalFees / result.salePrice) * 100) as NSNumber)
    }

    private var feeColor: Color {
        if feePercentage < 10 {
            return DesignSystem.Colors.success
        } else if feePercentage < 20 {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.error
        }
    }
}

#Preview("Fee Breakdown - Collapsed") {
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

    return CollapsibleFeeBreakdown(result: result)
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Fee Breakdown - Expanded") {
    @Previewable @State var breakdown = CollapsibleFeeBreakdown(result: ForwardCalculationResult(
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
    ))

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

    return VStack {
        CollapsibleFeeBreakdown(result: result)
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
    .onAppear {
        // Expand on preview
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Preview with expanded state
        }
    }
}
