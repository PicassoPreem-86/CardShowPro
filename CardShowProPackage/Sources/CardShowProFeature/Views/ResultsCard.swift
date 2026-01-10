import SwiftUI

/// Large results card with list price display
struct ResultsCard: View {
    @Bindable var model: SalesCalculatorModel
    @Binding var showCopyToast: Bool

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Text("LIST PRICE")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Button {
                    model.copyListPrice()
                    withAnimation {
                        showCopyToast = true
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxxs) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy")
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.electricBlue)
                }
            }

            // Large List Price
            Text(model.calculationResult.listPrice.asCurrency)
                .font(DesignSystem.Typography.displayMedium.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.thunderYellow)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.lg)

            // Net Profit Display
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text("NET PROFIT")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text(model.calculationResult.netProfit.asCurrency)
                        .font(DesignSystem.Typography.heading3.monospacedDigit())
                        .foregroundStyle(profitColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxxs) {
                    Text("MARGIN")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text(model.calculationResult.profitMarginPercent.asPercentage)
                        .font(DesignSystem.Typography.heading3.monospacedDigit())
                        .foregroundStyle(profitColor)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
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
                        colors: [DesignSystem.Colors.thunderYellow.opacity(0.5), DesignSystem.Colors.thunderYellow],
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

    private var profitColor: Color {
        if model.calculationResult.netProfit > 0 {
            return DesignSystem.Colors.success
        } else if model.calculationResult.netProfit < 0 {
            return DesignSystem.Colors.error
        } else {
            return DesignSystem.Colors.textSecondary
        }
    }
}
