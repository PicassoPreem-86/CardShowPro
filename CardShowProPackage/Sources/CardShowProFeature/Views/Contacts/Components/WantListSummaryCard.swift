import SwiftUI

/// Summary card showing want list overview in ContactDetailView
struct WantListSummaryCard: View {
    let contact: Contact
    let onViewAll: () -> Void

    @State private var isExpanded = true  // Expanded by default for better discoverability

    private var itemCount: Int {
        contact.wantListItems.count
    }

    private var topItems: [WantListItem] {
        Array(contact.wantListItems.prefix(3))
    }

    private var hasMatches: Bool {
        // TODO: Implement match detection logic in future
        false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header with count and expand/collapse
            HStack {
                Text("WANT LIST (\(itemCount))")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: DesignSystem.Animation.fast)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.electricBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)

            // Content (only shown when expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    if itemCount == 0 {
                        // Empty state
                        emptyState
                    } else {
                        // Match indicator (placeholder)
                        if hasMatches {
                            matchIndicator
                        }

                        // Top items list
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            ForEach(topItems, id: \.id) { item in
                                itemBullet(item)
                            }
                        }

                        // View All button
                        if itemCount > 0 {
                            Button(action: onViewAll) {
                                HStack {
                                    Text("View All (\(itemCount))")
                                        .font(DesignSystem.Typography.labelLarge)
                                        .foregroundStyle(DesignSystem.Colors.electricBlue)

                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(DesignSystem.Colors.electricBlue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .background(DesignSystem.Colors.backgroundTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 32))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No want list items")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Button(action: onViewAll) {
                Text("Add Items")
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.electricBlue)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }

    // MARK: - Match Indicator

    @ViewBuilder
    private var matchIndicator: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "target")
                .font(.system(size: 16))
                .foregroundStyle(DesignSystem.Colors.success)

            Text("3 matches available!")
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.success)

            Spacer()
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
    }

    // MARK: - Item Bullet

    @ViewBuilder
    private func itemBullet(_ item: WantListItem) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(DesignSystem.Colors.electricBlue)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.cardName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.xs) {
                    if let setName = item.setName, !setName.isEmpty {
                        Text(setName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    if let maxPrice = item.maxPrice {
                        Text("•")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)

                        Text("Up to \(formatCurrency(maxPrice))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Previews

#Preview("Want List Summary - Collapsed") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            WantListSummaryCard(
                contact: Contact(
                    name: "John Smith",
                    wantListItems: [
                        WantListItem(cardName: "Charizard", setName: "Base Set", maxPrice: 5000.00),
                        WantListItem(cardName: "Pikachu Illustrator", setName: "CoroCoro", maxPrice: nil),
                        WantListItem(cardName: "Blastoise", setName: "Base Set", maxPrice: 150.00)
                    ]
                ),
                onViewAll: { }
            )
        }
        .padding(DesignSystem.Spacing.md)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Want List Summary - Expanded") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            WantListSummaryCard(
                contact: Contact(
                    name: "John Smith",
                    wantListItems: [
                        WantListItem(cardName: "Charizard", setName: "Base Set 1st Edition", maxPrice: 5000.00),
                        WantListItem(cardName: "Pikachu Illustrator", setName: "CoroCoro Comic Promo", maxPrice: nil),
                        WantListItem(cardName: "Blastoise", setName: "Base Set Shadowless", maxPrice: 150.00),
                        WantListItem(cardName: "Venusaur", setName: "Base Set", maxPrice: 100.00)
                    ]
                ),
                onViewAll: { }
            )
        }
        .padding(DesignSystem.Spacing.md)
        .onAppear {
            // Auto-expand for preview
        }
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Want List Summary - Empty") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            WantListSummaryCard(
                contact: Contact(name: "Sarah Johnson", wantListItems: []),
                onViewAll: { }
            )
        }
        .padding(DesignSystem.Spacing.md)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}
