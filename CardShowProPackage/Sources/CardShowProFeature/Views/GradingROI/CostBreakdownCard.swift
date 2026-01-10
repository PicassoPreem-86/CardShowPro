import SwiftUI

/// Displays itemized cost breakdown
struct CostBreakdownCard: View {
    let costs: GradingCosts

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Text("Cost Breakdown")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Image(systemName: "dollarsign.circle.fill")
                    .font(.title3)
                    .foregroundStyle(DesignSystem.Colors.electricBlue)
            }

            Divider()
                .background(DesignSystem.Colors.borderPrimary)

            // Cost Items
            VStack(spacing: DesignSystem.Spacing.sm) {
                costRow(label: "Grading Fee", amount: costs.gradingFee)
                costRow(label: "Shipping", amount: costs.shippingCost)
                costRow(label: "Insurance", amount: costs.insuranceCost)

                Divider()
                    .background(DesignSystem.Colors.borderSecondary)
                    .padding(.vertical, DesignSystem.Spacing.xxs)

                HStack {
                    Text("Total Cost")
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Spacer()

                    Text(costs.totalCost.asCurrency)
                        .font(DesignSystem.Typography.heading3)
                        .foregroundStyle(DesignSystem.Colors.electricBlue)
                        .fontWeight(.bold)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.electricBlue.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: DesignSystem.Shadows.level3.color,
            radius: DesignSystem.Shadows.level3.radius,
            x: DesignSystem.Shadows.level3.x,
            y: DesignSystem.Shadows.level3.y
        )
    }

    private func costRow(label: String, amount: Double) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(amount.asCurrency)
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .monospacedDigit()
        }
    }
}

#Preview {
    CostBreakdownCard(
        costs: GradingCosts(
            gradingFee: 19.99,
            shippingCost: 15.00,
            insuranceCost: 5.00
        )
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
