import SwiftUI

// MARK: - Inventory Card Row (List View)
struct InventoryCardRow: View {
    let card: InventoryCard

    private var category: CardCategory { card.cardCategory }

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

                    // Variant Badge
                    if let variant = card.variantType, variant != .normal {
                        VariantBadge(variant: variant)
                    }

                    // Status Badge (only for non-inStock)
                    if card.cardStatus != .inStock {
                        StatusBadge(status: card.cardStatus)
                    }

                    Text(card.cardNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            // Value and Profit Section
            VStack(alignment: .trailing, spacing: 6) {
                if card.isSold, let soldPrice = card.soldPrice {
                    // Sold price
                    Text("$\(String(format: "%.2f", soldPrice))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.success)

                    // Sold badge
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("Sold")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(DesignSystem.Colors.success)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DesignSystem.Colors.success.opacity(0.15))
                    .clipShape(Capsule())
                } else {
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
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: CardStatus

    private var badgeColor: Color {
        switch status {
        case .inStock: return DesignSystem.Colors.cyan
        case .listed: return DesignSystem.Colors.electricBlue
        case .sold: return DesignSystem.Colors.success
        case .shipped: return DesignSystem.Colors.textSecondary
        case .returned: return DesignSystem.Colors.error
        case .disputed: return DesignSystem.Colors.warning
        }
    }

    private var badgeIcon: String {
        switch status {
        case .inStock: return "shippingbox.fill"
        case .listed: return "tag.fill"
        case .sold: return "checkmark.circle.fill"
        case .shipped: return "paperplane.fill"
        case .returned: return "arrow.uturn.backward.circle.fill"
        case .disputed: return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: badgeIcon)
                .font(.system(size: 9))
            Text(status.rawValue)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(badgeColor.opacity(0.15))
        .foregroundStyle(badgeColor)
        .clipShape(Capsule())
    }
}

// MARK: - Variant Badge

struct VariantBadge: View {
    let variant: InventoryCardVariant

    private var badgeColor: Color {
        switch variant {
        case .normal: return DesignSystem.Colors.textSecondary
        case .holofoil, .reverseHolofoil: return .cyan
        case .firstEdition: return DesignSystem.Colors.thunderYellow
        case .unlimited: return DesignSystem.Colors.textSecondary
        case .secretRare, .hyperRare, .goldRare: return DesignSystem.Colors.thunderYellow
        case .fullArt, .altArt, .specialArtRare: return .purple
        case .illustrationRare: return .pink
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkles")
                .font(.system(size: 8))
            Text(variant.displayName)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(badgeColor.opacity(0.15))
        .foregroundStyle(badgeColor)
        .clipShape(Capsule())
    }
}
