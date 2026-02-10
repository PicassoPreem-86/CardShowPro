import SwiftUI

struct PriceLookupResultsView: View {
    let lookupState: PriceLookupState
    let onCopyPrices: () -> Void
    let onAddToInventory: () -> Void
    let onNewLookup: () -> Void
    let onShowPriceHistory: () -> Void
    let canAddToInventory: Bool

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Cache Indicator (if from cache)
            if lookupState.isFromCache {
                cacheIndicatorBadge
            }

            // Large Card Image
            if let selectedMatch = lookupState.selectedMatch {
                cardImageSection(selectedMatch)

                // Card Details
                cardDetailsSection(selectedMatch)
            }

            // JustTCG Condition Pricing (if available)
            if lookupState.hasJustTCGPricing {
                conditionPricingSection
            }

            // TCGPlayer Section (variant pricing)
            if let tcgPrices = lookupState.tcgPlayerPrices, tcgPrices.hasAnyPricing {
                TCGPlayerPriceCard(pricing: tcgPrices)
            } else if !lookupState.hasJustTCGPricing {
                noPricingAvailableSection
            }

            // eBay Section (Placeholder)
            ebayPlaceholderSection

            // Bottom Actions
            bottomActionsSection
        }
    }

    // MARK: - Cache Indicator

    private var cacheIndicatorBadge: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "bolt.fill")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.thunderYellow)

            Text("Cached")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("•")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text(lookupState.cacheAge)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.thunderYellow.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.thunderYellow.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Card Image Section

    private func cardImageSection(_ match: CardMatch) -> some View {
        VStack {
            if let imageURL = match.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(DesignSystem.Colors.cyan)
                            .scaleEffect(1.5)
                            .frame(width: 280, height: 390)
                            .background(DesignSystem.Colors.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                            .shadow(radius: 8)
                            .accessibilityLabel("\(match.cardName) card image")

                    case .failure:
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(DesignSystem.Colors.textTertiary)

                            Text("Image Unavailable")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        .frame(width: 280, height: 390)
                        .background(DesignSystem.Colors.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // No image URL provided
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text("No Image Available")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .frame(width: 280, height: 390)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Card Details Section

    private func cardDetailsSection(_ match: CardMatch) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Card Name
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text("Card Name")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(match.cardName)
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            Divider()

            // Card Number and Set Info
            HStack(spacing: DesignSystem.Spacing.lg) {
                // Card Number
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text("Card Number")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text("#\(match.cardNumber)")
                        .font(DesignSystem.Typography.bodyLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }

                Spacer()

                // Set Name
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxxs) {
                    Text("Set")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text(match.setName)
                        .font(DesignSystem.Typography.bodyLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: - JustTCG Condition Pricing Section

    private var conditionPricingSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Header with JustTCG label
            HStack {
                Image(systemName: "tag.fill")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.cyan)

                Text("Condition Pricing")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                // JustTCG badge
                Text("JustTCG")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.cyan)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(DesignSystem.Colors.cyan.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
            }

            // Condition Price Selector
            @Bindable var state = lookupState
            ConditionPriceSelector(
                selectedCondition: $state.selectedCondition,
                conditionPrices: lookupState.conditionPrices,
                priceChange7d: lookupState.priceChange7d,
                onPriceHistoryTap: lookupState.priceHistory != nil ? {
                    onShowPriceHistory()
                } : nil
            )
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }

    private var noPricingAvailableSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 36))
                .foregroundStyle(DesignSystem.Colors.warning)

            Text("No Pricing Available")
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("This card doesn't have TCGPlayer pricing data")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .cardStyle()
    }

    private var ebayPlaceholderSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Text("eBay Last Sold")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()
            }

            Text("Coming Soon")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text("eBay integration will be added in a future update")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }

    // MARK: - Bottom Actions

    private var bottomActionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Button {
                onCopyPrices()
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "doc.on.doc")
                        .font(DesignSystem.Typography.labelLarge)
                    Text("Copy Prices")
                        .font(DesignSystem.Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
            }
            .secondaryButtonStyle()
            .accessibilityLabel("Copy all prices to clipboard")

            Button {
                onAddToInventory()
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(DesignSystem.Typography.labelLarge)
                    Text("Add to Inventory")
                        .font(DesignSystem.Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .disabled(!canAddToInventory)
            .opacity(canAddToInventory ? 1.0 : 0.5)
            .accessibilityLabel("Add card to inventory")
            .accessibilityHint("Opens card entry form with pre-filled data from this lookup")

            Button {
                onNewLookup()
            } label: {
                Text("New Lookup")
                    .font(DesignSystem.Typography.labelLarge)
                    .frame(maxWidth: .infinity)
            }
            .secondaryButtonStyle()
        }
    }
}
