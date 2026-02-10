import SwiftUI

struct InventoryEmptyState: View {
    let category: CardCategory
    let message: String
    let onScanTap: () -> Void
    let onAddManualTap: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Category icon with colored circle background
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: category.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(category.color)
            }
            .padding(.bottom, DesignSystem.Spacing.xs)

            Text("No Cards Found")
                .font(DesignSystem.Typography.heading2)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)

            VStack(spacing: DesignSystem.Spacing.xs) {
                // Primary action - Scan Cards
                Button {
                    onScanTap()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "camera.fill")
                        Text("Scan Cards")
                    }
                    .font(DesignSystem.Typography.labelLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .shadow(
                        color: DesignSystem.Shadows.level2.color,
                        radius: DesignSystem.Shadows.level2.radius,
                        x: DesignSystem.Shadows.level2.x,
                        y: DesignSystem.Shadows.level2.y
                    )
                }

                // Secondary action - Add Manually
                Button {
                    onAddManualTap()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "plus.circle")
                        Text("Add Manually")
                    }
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.cyan)
                    .frame(maxWidth: 280)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.cyan.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
        .frame(maxHeight: .infinity)
    }
}
