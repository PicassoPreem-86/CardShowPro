import SwiftUI

// MARK: - Inventory Card Grid Item
struct InventoryCardGridItem: View {
    let card: InventoryCard

    private var category: CardCategory { card.cardCategory }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Card Image
            ZStack(alignment: .topTrailing) {
                if let image = card.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("\(card.cardName) card image")
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 180)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }

                // Category Badge
                HStack(spacing: 4) {
                    Image(systemName: category.icon)
                        .font(.caption2)
                }
                .padding(8)
                .background(category.color)
                .foregroundStyle(.white)
                .clipShape(Circle())
                .padding(8)

                // Status Badge (non-inStock only)
                if card.cardStatus != .inStock {
                    VStack {
                        Spacer()
                        HStack {
                            StatusBadge(status: card.cardStatus)
                                .padding(8)
                            Spacer()
                        }
                    }
                }
            }

            // Card Info
            VStack(alignment: .leading, spacing: 6) {
                Text(card.cardName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                HStack(spacing: 4) {
                    Text(card.setName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if let variant = card.variantType, variant != .normal {
                        VariantBadge(variant: variant)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("$\(String(format: "%.2f", card.marketValue))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.cyan)

                        // Profit display
                        if card.purchaseCost != nil {
                            HStack(spacing: 4) {
                                Image(systemName: card.profit >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption2)
                                Text("$\(String(format: "%.0f", abs(card.profit)))")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(card.profit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                        }
                    }

                    Spacer()

                    if card.purchaseCost != nil {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(String(format: "%.0f", card.roi))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(card.roi >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                            Text("ROI")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
        .accessibilityElement(children: .combine)
    }
}
