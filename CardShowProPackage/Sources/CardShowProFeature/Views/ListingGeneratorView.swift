import SwiftUI
import SwiftData

/// Listing generator view that produces copy-paste listing descriptions
/// for eBay, TCGPlayer, Facebook, Mercari, and generic platforms.
struct ListingGeneratorView: View {
    @Query(filter: #Predicate<InventoryCard> { $0.status == "In Stock" },
           sort: \InventoryCard.cardName)
    private var inStockCards: [InventoryCard]

    @State private var selectedCard: InventoryCard?
    @State private var selectedPlatform: ListingPlatform = .ebay
    @State private var includePrice: Bool = true
    @State private var includeShipping: Bool = true
    @State private var showCardPicker: Bool = false
    @State private var copied: Bool = false

    private var generatedText: String {
        guard let card = selectedCard else { return "" }
        return ListingGeneratorService.generateListing(
            for: card,
            platform: selectedPlatform,
            includePrice: includePrice,
            includeShipping: includeShipping
        )
    }

    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    cardSelectionSection
                    platformSelector
                    togglesSection
                    if selectedCard != nil {
                        listingPreview
                        actionButtons
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
        }
        .navigationTitle("Listing Generator")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCardPicker) {
            CardPickerSheet(
                cards: inStockCards,
                onSelect: { card in
                    withAnimation(DesignSystem.Animation.springSmooth) {
                        selectedCard = card
                    }
                    showCardPicker = false
                }
            )
        }
    }

    // MARK: - Card Selection

    @ViewBuilder
    private var cardSelectionSection: some View {
        if let card = selectedCard {
            selectedCardHeader(card: card)
        } else {
            selectCardButton
        }
    }

    private func selectedCardHeader(card: InventoryCard) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.backgroundTertiary)
                    .frame(width: 56, height: 78)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(card.cardName)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                Text(card.setName)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)

                if card.estimatedValue > 0 {
                    Text("$\(String(format: "%.2f", card.estimatedValue))")
                        .font(DesignSystem.Typography.label)
                        .foregroundStyle(DesignSystem.Colors.success)
                }
            }

            Spacer()

            Button {
                showCardPicker = true
            } label: {
                Text("Change")
                    .font(DesignSystem.Typography.label)
                    .foregroundStyle(DesignSystem.Colors.cyan)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }

    private var selectCardButton: some View {
        Button {
            showCardPicker = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(DesignSystem.Colors.cyan)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text("Select Card")
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("\(inStockCards.count) in-stock cards")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            .shadow(
                color: DesignSystem.Shadows.level2.color,
                radius: DesignSystem.Shadows.level2.radius,
                x: DesignSystem.Shadows.level2.x,
                y: DesignSystem.Shadows.level2.y
            )
        }
    }

    // MARK: - Platform Selector

    private var platformSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Platform")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xxxs)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(ListingPlatform.allCases) { platform in
                        PlatformChip(
                            platform: platform,
                            isSelected: selectedPlatform == platform,
                            onTap: {
                                withAnimation(DesignSystem.Animation.springSnappy) {
                                    selectedPlatform = platform
                                    copied = false
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xxxs)
            }
        }
    }

    // MARK: - Toggles

    private var togglesSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $includePrice) {
                Label("Include Price", systemImage: "dollarsign.circle")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .tint(DesignSystem.Colors.cyan)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .onChange(of: includePrice) { _, _ in copied = false }

            Divider()
                .background(DesignSystem.Colors.borderPrimary)

            Toggle(isOn: $includeShipping) {
                Label("Include Shipping Info", systemImage: "shippingbox")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .tint(DesignSystem.Colors.cyan)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .onChange(of: includeShipping) { _, _ in copied = false }
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }

    // MARK: - Listing Preview

    private var listingPreview: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("Preview")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text("\(generatedText.count) chars")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, DesignSystem.Spacing.xxxs)

            ScrollView {
                Text(generatedText)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignSystem.Spacing.sm)
            }
            .frame(minHeight: 160, maxHeight: 320)
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Copy to Clipboard
            Button {
                UIPasteboard.general.string = generatedText
                withAnimation(DesignSystem.Animation.springSmooth) {
                    copied = true
                }
                // Reset after 2 seconds
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation(DesignSystem.Animation.springSmooth) {
                        copied = false
                    }
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc.fill")
                        .font(.body)
                        .contentTransition(.symbolEffect(.replace))
                    Text(copied ? "Copied!" : "Copy to Clipboard")
                        .font(DesignSystem.Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cyan)
                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .shadow(
                    color: DesignSystem.Shadows.level3.color,
                    radius: DesignSystem.Shadows.level3.radius,
                    x: DesignSystem.Shadows.level3.x,
                    y: DesignSystem.Shadows.level3.y
                )
            }

            // Share
            ShareLink(item: generatedText) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                    Text("Share")
                        .font(DesignSystem.Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.backgroundTertiary)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }
}

// MARK: - Platform Chip

private struct PlatformChip: View {
    let platform: ListingPlatform
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: platform.iconName)
                    .font(.caption)
                Text(platform.rawValue)
                    .font(DesignSystem.Typography.label)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(isSelected ? DesignSystem.Colors.cyan.opacity(0.2) : DesignSystem.Colors.backgroundTertiary)
            .foregroundStyle(isSelected ? DesignSystem.Colors.cyan : DesignSystem.Colors.textSecondary)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        isSelected ? DesignSystem.Colors.cyan : Color.clear,
                        lineWidth: 1.5
                    )
            }
        }
        .accessibilityLabel("\(platform.rawValue) platform")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Card Picker Sheet

private struct CardPickerSheet: View {
    let cards: [InventoryCard]
    let onSelect: (InventoryCard) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    private var filteredCards: [InventoryCard] {
        if searchText.isEmpty { return cards }
        let query = searchText.lowercased()
        return cards.filter {
            $0.cardName.lowercased().contains(query)
            || $0.setName.lowercased().contains(query)
            || $0.cardNumber.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundPrimary
                    .ignoresSafeArea()

                if cards.isEmpty {
                    emptyState
                } else {
                    cardList
                }
            }
            .navigationTitle("Select Card")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search cards...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            Text("No In-Stock Cards")
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text("Add cards to your inventory to generate listings.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
    }

    private var cardList: some View {
        List {
            ForEach(filteredCards, id: \.id) { card in
                Button {
                    onSelect(card)
                } label: {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if let image = card.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 62)
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs))
                        } else {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                                .fill(DesignSystem.Colors.backgroundTertiary)
                                .frame(width: 44, height: 62)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.caption)
                                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                                }
                        }

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                            Text(card.cardName)
                                .font(DesignSystem.Typography.labelLarge)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .lineLimit(1)

                            Text("\(card.setName) #\(card.cardNumber)")
                                .font(DesignSystem.Typography.bodySmall)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        if card.estimatedValue > 0 {
                            Text("$\(String(format: "%.2f", card.estimatedValue))")
                                .font(DesignSystem.Typography.label)
                                .foregroundStyle(DesignSystem.Colors.success)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xxxs)
                }
                .listRowBackground(DesignSystem.Colors.cardBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
