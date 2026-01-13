import SwiftUI
import SwiftData

/// Input phase view for selecting card and configuring listing settings
struct InputPhaseView: View {
    @Bindable var state: ListingGeneratorState
    let service: ListingGeneratorService

    @Query private var inventoryCards: [InventoryCard]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Instructions
                InstructionCard()

                // Card Selection
                CardSelectionSection(state: state, inventoryCards: inventoryCards)

                // Settings (only shown when card is selected)
                if state.selectedCard != nil {
                    SettingsSection(state: state)

                    // Price Preview
                    PricePreviewCard(state: state)

                    // Generate Button
                    GenerateButton(state: state, service: service)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
    }
}

// MARK: - Instruction Card

private struct InstructionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
                Text("How it works")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            Text("Select a card from your inventory, choose your platform and condition, then let our AI generate an optimized listing for you.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Card Selection Section

private struct CardSelectionSection: View {
    @Bindable var state: ListingGeneratorState
    let inventoryCards: [InventoryCard]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Select Card")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xxxs)

            if let selectedCard = state.selectedCard {
                SelectedCardRow(card: selectedCard, onRemove: {
                    withAnimation {
                        state.selectedCard = nil
                    }
                })
            } else {
                SelectCardButton(state: state, inventoryCards: inventoryCards)
            }
        }
    }
}

private struct SelectedCardRow: View {
    let card: InventoryCard
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Card Image
            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.backgroundTertiary)
                    .frame(width: 60, height: 84)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
            }

            // Card Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(card.cardName)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                Text(card.setName)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)

                Text("$\(String(format: "%.2f", card.marketValue))")
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.success)
            }

            Spacer()

            // Remove Button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
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
}

private struct SelectCardButton: View {
    @Bindable var state: ListingGeneratorState
    let inventoryCards: [InventoryCard]

    var body: some View {
        Menu {
            if inventoryCards.isEmpty {
                Text("No cards in inventory")
            } else {
                ForEach(inventoryCards, id: \.id) { card in
                    Button {
                        withAnimation {
                            state.selectedCard = card
                        }
                    } label: {
                        Label("\(card.cardName) - $\(String(format: "%.2f", card.marketValue))", systemImage: "photo")
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(DesignSystem.Colors.cyan)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text("Select from Inventory")
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("\(inventoryCards.count) cards available")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.down")
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
}

// MARK: - Settings Section

private struct SettingsSection: View {
    @Bindable var state: ListingGeneratorState

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Platform Picker
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Platform")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Menu {
                    ForEach(ListingPlatform.allCases) { platform in
                        Button {
                            withAnimation {
                                state.selectedPlatform = platform
                            }
                        } label: {
                            Label(platform.rawValue, systemImage: platform.iconName)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: state.selectedPlatform.iconName)
                            .foregroundStyle(DesignSystem.Colors.electricBlue)
                        Text(state.selectedPlatform.rawValue)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
            }

            // Condition Picker
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Condition")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Menu {
                    ForEach(ListingCondition.allCases) { condition in
                        Button {
                            withAnimation {
                                state.selectedCondition = condition
                            }
                        } label: {
                            Text(condition.rawValue)
                        }
                    }
                } label: {
                    HStack {
                        Text(state.selectedCondition.rawValue)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
            }

            // Pricing Strategy Picker
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Pricing Strategy")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Menu {
                    ForEach(PricingStrategy.allCases) { strategy in
                        Button {
                            withAnimation {
                                state.pricingStrategy = strategy
                            }
                        } label: {
                            Label(strategy.rawValue, systemImage: strategy.iconName)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: state.pricingStrategy.iconName)
                            .foregroundStyle(DesignSystem.Colors.success)
                        Text(state.pricingStrategy.rawValue)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
            }
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

// MARK: - Price Preview Card

private struct PricePreviewCard: View {
    let state: ListingGeneratorState

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Suggested Price")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.xxxs) {
                Text("$")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.success)
                Text(String(format: "%.2f", state.calculatedPrice))
                    .font(DesignSystem.Typography.displaySmall)
                    .foregroundStyle(DesignSystem.Colors.success)
                Spacer()
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("Base: $\(String(format: "%.2f", state.basePrice))")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Text("•")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Text("Condition: \(Int(state.selectedCondition.valueMultiplier * 100))%")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level3.color,
            radius: DesignSystem.Shadows.level3.radius,
            x: DesignSystem.Shadows.level3.x,
            y: DesignSystem.Shadows.level3.y
        )
    }
}

// MARK: - Generate Button

private struct GenerateButton: View {
    @Bindable var state: ListingGeneratorState
    let service: ListingGeneratorService

    var body: some View {
        Button {
            generateListing()
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "bolt.fill")
                    .font(.title3)
                Text("Generate Listing")
                    .font(DesignSystem.Typography.labelLarge)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(state.canGenerate ? DesignSystem.Colors.thunderYellow : DesignSystem.Colors.backgroundTertiary)
            .foregroundStyle(state.canGenerate ? DesignSystem.Colors.backgroundPrimary : DesignSystem.Colors.textDisabled)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .shadow(
                color: state.canGenerate ? DesignSystem.Shadows.level3.color : .clear,
                radius: DesignSystem.Shadows.level3.radius,
                x: DesignSystem.Shadows.level3.x,
                y: DesignSystem.Shadows.level3.y
            )
        }
        .disabled(!state.canGenerate)
    }

    private func generateListing() {
        guard let card = state.selectedCard else { return }

        withAnimation {
            state.startGeneration()
        }

        Task {
            let listing = await service.generateListing(
                card: card,
                platform: state.selectedPlatform,
                condition: state.selectedCondition,
                price: state.calculatedPrice
            )

            await MainActor.run {
                withAnimation {
                    state.completeGeneration(listing: listing)
                }
            }
        }
    }
}
