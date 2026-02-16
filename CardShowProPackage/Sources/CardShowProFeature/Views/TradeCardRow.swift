import SwiftUI

/// Individual card row in trade comparison
struct TradeCardRow: View {
    let card: TradeCard
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Card Thumbnail
            cardThumbnail

            // Card Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(card.name)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)

                if let setName = card.setName {
                    Text(setName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    Text(formatCurrency(card.marketValue))
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundStyle(DesignSystem.Colors.thunderYellow)

                    // Condition badge for inventory-sourced cards
                    if let condition = card.condition {
                        Text(condition)
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.cyan)
                            .padding(.horizontal, DesignSystem.Spacing.xxxs + 2)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.cyan.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Delete Button
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(DesignSystem.Colors.textTertiary, DesignSystem.Colors.backgroundTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }

    @ViewBuilder
    private var cardThumbnail: some View {
        if let imageData = card.imageData,
           let uiImage = UIImage(data: imageData) {
            // Inventory card with stored image
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
        } else if let imageURL = card.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    placeholderImage
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                case .failure:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
            .fill(DesignSystem.Colors.backgroundSecondary)
            .frame(width: 60, height: 84)
            .overlay {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSNumber) ?? "$0.00"
    }
}
