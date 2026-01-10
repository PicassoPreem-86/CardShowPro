import SwiftUI

/// Reusable column component for trade comparison
struct TradeColumnView: View {
    let title: String
    let accentColor: Color
    let cards: [TradeCard]
    let total: Decimal
    let onAddCard: () -> Void
    let onRemoveCard: (TradeCard) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(accentColor)

                Text("\(cards.count) card\(cards.count == 1 ? "" : "s")")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.backgroundSecondary)

            // Card List
            if cards.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(cards) { card in
                            TradeCardRow(card: card) {
                                withAnimation(DesignSystem.Animation.springSmooth) {
                                    onRemoveCard(card)
                                }
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                }
            }

            Spacer()

            // Total
            VStack(spacing: DesignSystem.Spacing.xxxs) {
                Text("TOTAL")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Text(formatCurrency(total))
                    .font(DesignSystem.Typography.heading2)
                    .foregroundStyle(accentColor)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.backgroundSecondary)

            // Add Button
            Button {
                onAddCard()
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(DesignSystem.Typography.heading4)

                    Text("Add Card")
                        .font(DesignSystem.Typography.labelLarge)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(accentColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
            .buttonStyle(.plain)
            .padding(DesignSystem.Spacing.sm)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()

            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.xxxs) {
                Text("No Cards Yet")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text("Tap 'Add Card' to begin")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSNumber) ?? "$0.00"
    }
}
