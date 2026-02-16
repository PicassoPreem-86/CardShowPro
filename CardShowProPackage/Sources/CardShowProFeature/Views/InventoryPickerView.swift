import SwiftUI
import SwiftData

/// Reusable sheet for selecting a card from the user's inventory
struct InventoryPickerView: View {
    let onSelect: (InventoryCard) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(
        filter: #Predicate<InventoryCard> { $0.status == "In Stock" },
        sort: \InventoryCard.cardName
    )
    private var cards: [InventoryCard]
    @State private var searchText = ""

    private var filteredCards: [InventoryCard] {
        guard !searchText.isEmpty else { return cards }
        let query = searchText.lowercased()
        return cards.filter { card in
            card.cardName.lowercased().contains(query)
            || card.setName.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    emptyState
                } else if filteredCards.isEmpty {
                    noResultsState
                } else {
                    cardList
                }
            }
            .navigationTitle("Select Card")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by name or set"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .background(DesignSystem.Colors.backgroundPrimary)
        }
    }

    // MARK: - Card List

    private var cardList: some View {
        List {
            ForEach(filteredCards) { card in
                Button {
                    onSelect(card)
                    dismiss()
                } label: {
                    inventoryRow(for: card)
                }
                .listRowBackground(DesignSystem.Colors.backgroundSecondary)
                .listRowSeparatorTint(DesignSystem.Colors.borderPrimary)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.backgroundPrimary)
    }

    // MARK: - Row

    private func inventoryRow(for card: InventoryCard) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Thumbnail
            cardThumbnail(for: card)

            // Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(card.cardName)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)

                Text(card.setName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.xxs) {
                    // Value
                    Text(formatCurrency(card.estimatedValue))
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundStyle(DesignSystem.Colors.thunderYellow)

                    // Condition badge
                    Text(card.condition)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.cyan)
                        .padding(.horizontal, DesignSystem.Spacing.xxxs + 2)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.cyan.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(DesignSystem.Colors.electricBlue)
        }
        .padding(.vertical, DesignSystem.Spacing.xxxs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.cardName), \(card.setName), \(formatCurrency(card.estimatedValue)), \(card.condition)")
        .accessibilityHint("Tap to add to your trade cards")
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private func cardThumbnail(for card: InventoryCard) -> some View {
        if let imageData = card.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs))
        } else {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                .fill(DesignSystem.Colors.backgroundTertiary)
                .frame(width: 40, height: 56)
                .overlay {
                    Image(systemName: "photo")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()

            Image(systemName: "shippingbox")
                .font(.system(size: 56))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.xxxs) {
                Text("No In-Stock Cards")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text("Add cards to your inventory first, then you can select them for trades.")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.xxxs) {
                Text("No Results")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text("No cards match \"\(searchText)\"")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
