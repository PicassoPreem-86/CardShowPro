import SwiftUI

/// Individual want list item card displaying item details
struct WantListItemRow: View {
    let item: WantListItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Card name and priority badge
            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                Text(item.cardName)
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)

                Spacer()

                // Priority badge
                PriorityBadge(priority: item.priorityEnum)
            }

            // Set name if available
            if let setName = item.setName, !setName.isEmpty {
                Text(setName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Condition and budget row
            HStack(spacing: DesignSystem.Spacing.md) {
                if let condition = item.condition, !condition.isEmpty {
                    Label {
                        Text(condition)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    } icon: {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.Colors.goldAmber)
                    }
                }

                if let maxPrice = item.maxPrice {
                    Label {
                        Text("Up to \(formatCurrency(maxPrice))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    } icon: {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.Colors.electricBlue)
                    }
                } else {
                    Label {
                        Text("No budget limit")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    } icon: {
                        Image(systemName: "infinity.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.Colors.electricBlue)
                    }
                }
            }

            // Date added
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Text("Added \(item.dateAdded.formatted(date: .abbreviated, time: .omitted))")
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            // Optional match indicator (placeholder for future)
            if false { // TODO: Add match logic in future
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "target")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.success)

                    Text("3 matches available")
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.success)
                }
                .padding(.top, DesignSystem.Spacing.xxs)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(DesignSystem.Colors.electricBlue)
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Priority Badge Component

private struct PriorityBadge: View {
    let priority: ContactPriority

    var body: some View {
        Text(priority.rawValue)
            .font(DesignSystem.Typography.captionBold)
            .foregroundStyle(.white)
            .padding(.horizontal, DesignSystem.Spacing.xxs)
            .padding(.vertical, DesignSystem.Spacing.xxxs)
            .background(priorityColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs))
    }

    private var priorityColor: Color {
        switch priority {
        case .vip:
            return DesignSystem.Colors.thunderYellow
        case .high:
            return DesignSystem.Colors.warning
        case .normal:
            return DesignSystem.Colors.textSecondary
        case .low:
            return DesignSystem.Colors.textTertiary
        }
    }
}

// MARK: - Previews

#Preview("Want List Item Row - Full Details") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.sm) {
            WantListItemRow(
                item: WantListItem(
                    cardName: "Charizard",
                    setName: "Base Set 1st Edition",
                    condition: "PSA 10",
                    maxPrice: 5000.00,
                    priority: .vip
                ),
                onEdit: { },
                onDelete: { }
            )

            WantListItemRow(
                item: WantListItem(
                    cardName: "Pikachu Illustrator",
                    setName: "CoroCoro Comic Promo",
                    condition: "Raw Near Mint",
                    maxPrice: nil,
                    priority: .high
                ),
                onEdit: { },
                onDelete: { }
            )

            WantListItemRow(
                item: WantListItem(
                    cardName: "Blastoise",
                    setName: nil,
                    condition: nil,
                    maxPrice: 150.00,
                    priority: .normal
                ),
                onEdit: { },
                onDelete: { }
            )

            WantListItemRow(
                item: WantListItem(
                    cardName: "Venusaur Holo",
                    setName: "Base Set Unlimited",
                    condition: "Lightly Played",
                    maxPrice: 75.50,
                    priority: .low
                ),
                onEdit: { },
                onDelete: { }
            )
        }
        .padding(DesignSystem.Spacing.md)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}
