import SwiftUI

// MARK: - Inventory Card Row (List View)
struct InventoryCardRow: View {
    let card: InventoryCard
    let category: CardCategory

    var body: some View {
        HStack(spacing: 16) {
            // Card Image
            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("\(card.cardName) card image")
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 80)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityHidden(true)
            }

            // Card Info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.cardName)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(card.setName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    // Category Badge
                    HStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.caption2)
                        Text(category.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(category.color.opacity(0.15))
                    .foregroundStyle(category.color)
                    .clipShape(Capsule())

                    Text(card.cardNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            // Value and Profit Section
            VStack(alignment: .trailing, spacing: 6) {
                // Market Value
                Text("$\(String(format: "%.2f", card.marketValue))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)

                // Profit Badge (if purchase cost exists)
                if card.purchaseCost != nil {
                    ProfitBadge(profit: card.profit, roi: card.roi)
                } else {
                    // No purchase cost indicator
                    Text("No Cost")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.backgroundTertiary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
