import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Large result card displaying Recommended Sale Price for Reverse Mode
/// Hero metric with copy-to-clipboard functionality
struct PriceResultCard: View {
    let result: CalculationResult
    @Bindable var model: SalesCalculatorModel
    @State private var showCopyToast = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Text("RECOMMENDED SALE PRICE")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Button {
                    copyToClipboard()
                    withAnimation {
                        showCopyToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showCopyToast = false
                        }
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxxs) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy")
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.electricBlue)
                }
                .accessibilityLabel("Copy price to clipboard")
            }

            // HERO: Recommended Price
            Text(result.listPrice.asCurrency)
                .font(DesignSystem.Typography.displayLarge.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.thunderYellow)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.lg)
                .accessibilityLabel("Recommended sale price: \(result.listPrice.asCurrency)")
                .accessibilityAddTraits(.updatesFrequently)

            // Explanation Text
            ExplanationText(result: result)

            // Profit Breakdown
            ProfitBreakdown(result: result)

            // Copy Toast
            if showCopyToast {
                CopyToast()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
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
                        colors: [
                            DesignSystem.Colors.thunderYellow.opacity(0.5),
                            DesignSystem.Colors.thunderYellow
                        ],
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
        // Yellow accent bar on left
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(DesignSystem.Colors.thunderYellow)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        }
    }

    // MARK: - Copy to Clipboard

    private func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = result.listPrice.asCurrency
        #endif
    }
}

// MARK: - Explanation Text

private struct ExplanationText: View {
    let result: CalculationResult

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxxs) {
            Text("To achieve your profit goal")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                Text("Net Profit: \(result.netProfit.asCurrency)")
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.success)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("To achieve your profit goal, net profit will be \(result.netProfit.asCurrency)")
    }
}

// MARK: - Profit Breakdown

private struct ProfitBreakdown: View {
    let result: CalculationResult

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("BREAKDOWN")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()
            }

            VStack(spacing: DesignSystem.Spacing.xxs) {
                BreakdownRow(
                    label: "Net Profit",
                    value: result.netProfit.asCurrency,
                    color: DesignSystem.Colors.success
                )

                BreakdownRow(
                    label: "Profit Margin",
                    value: result.profitMarginPercent.asPercentage,
                    color: DesignSystem.Colors.success
                )

                Divider()
                    .background(DesignSystem.Colors.borderPrimary)

                BreakdownRow(
                    label: "Platform Fees",
                    value: result.platformFee.asCurrency,
                    color: DesignSystem.Colors.textSecondary,
                    isSubtle: true
                )

                BreakdownRow(
                    label: "Payment Fees",
                    value: result.paymentFee.asCurrency,
                    color: DesignSystem.Colors.textSecondary,
                    isSubtle: true
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundTertiary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
}

// MARK: - Breakdown Row

private struct BreakdownRow: View {
    let label: String
    let value: String
    let color: Color
    var isSubtle: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isSubtle ? DesignSystem.Typography.bodySmall : DesignSystem.Typography.body)
                .foregroundStyle(isSubtle ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.textPrimary)

            Spacer()

            Text(value)
                .font(isSubtle ? DesignSystem.Typography.labelSmall.monospacedDigit() : DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Copy Toast

private struct CopyToast: View {
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)

            Text("Price Copied!")
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.success)
        .clipShape(Capsule())
        .shadow(
            color: DesignSystem.Shadows.level3.color,
            radius: DesignSystem.Shadows.level3.radius,
            x: DesignSystem.Shadows.level3.x,
            y: DesignSystem.Shadows.level3.y
        )
        .accessibilityLabel("Price copied to clipboard")
    }
}

#Preview("Price Result - Standard") {
    @Previewable @State var model = SalesCalculatorModel()

    let result = CalculationResult(
        listPrice: 71.65,
        platformFee: 9.28,
        platformFeePercentage: 0.1295,
        paymentFee: 2.38,
        paymentFeePercentage: 0.029,
        shippingCost: 5.00,
        totalFees: 16.66,
        netProfit: 15.00,
        profitMarginPercent: 20.93
    )

    return PriceResultCard(result: result, model: model)
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Price Result - High Value") {
    @Previewable @State var model = SalesCalculatorModel()

    let result = CalculationResult(
        listPrice: 356.32,
        platformFee: 46.14,
        platformFeePercentage: 0.1295,
        paymentFee: 10.64,
        paymentFeePercentage: 0.029,
        shippingCost: 0.00,
        totalFees: 56.78,
        netProfit: 100.00,
        profitMarginPercent: 28.07
    )

    return PriceResultCard(result: result, model: model)
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}
