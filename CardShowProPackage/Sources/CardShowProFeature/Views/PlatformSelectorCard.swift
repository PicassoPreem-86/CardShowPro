import SwiftUI

/// Platform selector card at top of calculator
struct PlatformSelectorCard: View {
    @Bindable var model: SalesCalculatorModel

    var body: some View {
        Button {
            model.showPlatformPicker = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Platform Icon
                Image(systemName: model.selectedPlatform.icon)
                    .font(DesignSystem.Typography.heading2)
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
                    .frame(width: 56, height: 56)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

                // Platform Details
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text(model.selectedPlatform.rawValue)
                        .font(DesignSystem.Typography.heading4)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(model.selectedPlatform.feeStructure.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.thunderYellow, lineWidth: 2)
            )
            .shadow(
                color: DesignSystem.Shadows.level3.color,
                radius: DesignSystem.Shadows.level3.radius,
                x: DesignSystem.Shadows.level3.x,
                y: DesignSystem.Shadows.level3.y
            )
        }
        .buttonStyle(.plain)
    }
}
