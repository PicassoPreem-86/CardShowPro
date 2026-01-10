import SwiftUI

/// Bottom indicator showing trade fairness analysis
struct FairnessIndicatorView: View {
    let analysis: TradeAnalysis

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Fairness Badge
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: fairnessIcon)
                    .font(DesignSystem.Typography.labelLarge)

                Text(fairnessText)
                    .font(DesignSystem.Typography.labelLarge)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(fairnessColor)
            .clipShape(Capsule())

            // Difference Details
            if analysis.yourTotal > 0 || analysis.theirTotal > 0 {
                VStack(spacing: DesignSystem.Spacing.xxxs) {
                    if analysis.difference != 0 {
                        Text(differenceText)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        Text("\(String(format: "%.1f", analysis.percentageDifference))% difference")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    } else {
                        Text("Values are exactly equal")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundStyle(DesignSystem.Colors.success)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level3.color,
            radius: DesignSystem.Shadows.level3.radius,
            x: DesignSystem.Shadows.level3.x,
            y: DesignSystem.Shadows.level3.y
        )
    }

    private var fairnessIcon: String {
        switch analysis.fairnessLevel {
        case .fair:
            return "checkmark.seal.fill"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .unfair:
            return "xmark.octagon.fill"
        }
    }

    private var fairnessText: String {
        switch analysis.fairnessLevel {
        case .fair:
            return "Fair Trade"
        case .caution:
            return "Review Carefully"
        case .unfair:
            return "Unfair Trade"
        }
    }

    private var fairnessColor: Color {
        switch analysis.fairnessLevel {
        case .fair:
            return DesignSystem.Colors.success
        case .caution:
            return DesignSystem.Colors.warning
        case .unfair:
            return DesignSystem.Colors.error
        }
    }

    private var differenceText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2

        let absValue = abs(Double(truncating: analysis.difference as NSNumber))
        let formattedValue = formatter.string(from: NSNumber(value: absValue)) ?? "$0.00"

        if analysis.difference > 0 {
            return "You gain \(formattedValue)"
        } else if analysis.difference < 0 {
            return "You lose \(formattedValue)"
        } else {
            return "Equal value"
        }
    }
}
