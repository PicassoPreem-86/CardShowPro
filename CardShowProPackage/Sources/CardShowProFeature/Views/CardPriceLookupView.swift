import SwiftUI

/// Card Price Lookup Tool
/// Allows users to lookup card prices WITHOUT adding to inventory
@MainActor
struct CardPriceLookupView: View {
    @State private var lookupState = PriceLookupState()
    @State private var showMatchSelection = false
    private let pokemonService = PokemonTCGService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                headerSection

                // Input Sections
                inputSections

                // Action Button
                lookupButton

                // Results Section
                if lookupState.isLoading {
                    loadingSection
                } else if let errorMessage = lookupState.errorMessage {
                    errorSection(errorMessage)
                } else if lookupState.tcgPlayerPrices != nil {
                    pricingResultsSection
                }
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
        }
        .background(Color.clear)
        .navigationTitle("Price Lookup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showMatchSelection) {
            matchSelectionSheet
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Card Price Lookup")
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Look up current TCGPlayer prices without adding to inventory")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input Sections

    private var inputSections: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Card Name Input
            cardNameInput

            // Card Number Input (Split)
            cardNumberInput

            // Variant Input
            variantInput
        }
    }

    private var cardNameInput: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Card Name")
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            TextField("e.g., Pikachu", text: $lookupState.cardName)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.borderPrimary, lineWidth: 1)
                )
                .autocorrectionDisabled()
        }
    }

    private var cardNumberInput: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Card Number")
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                // First part (e.g., "25")
                TextField("25", text: $lookupState.cardNumber)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.borderPrimary, lineWidth: 1)
                    )
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity)

                // Separator
                Text("/")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                // Second part (e.g., "102")
                TextField("102", text: $lookupState.totalCards)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.borderPrimary, lineWidth: 1)
                    )
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity)
            }

            Text("Optional: Enter card number and/or total cards in set")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
    }

    private var variantInput: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Variant (Optional)")
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            TextField("e.g., Holo, Reverse Holo, Full Art", text: $lookupState.variant)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.borderPrimary, lineWidth: 1)
                )
        }
    }

    // MARK: - Action Button

    private var lookupButton: some View {
        Button {
            performLookup()
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(DesignSystem.Typography.labelLarge)
                Text("Look Up Price")
                    .font(DesignSystem.Typography.labelLarge)
            }
            .frame(maxWidth: .infinity)
        }
        .primaryButtonStyle()
        .disabled(!lookupState.canLookupPrice || lookupState.isLoading)
        .opacity(lookupState.canLookupPrice && !lookupState.isLoading ? 1.0 : 0.5)
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .tint(DesignSystem.Colors.cyan)
                .scaleEffect(1.5)

            Text("Looking up prices...")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xl)
        .cardStyle()
    }

    // MARK: - Error Section

    private func errorSection(_ message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.error)

            Text("Error")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                lookupState.clearError()
            } label: {
                Text("Dismiss")
                    .font(DesignSystem.Typography.labelLarge)
                    .frame(maxWidth: .infinity)
            }
            .secondaryButtonStyle()
        }
        .padding(DesignSystem.Spacing.lg)
        .cardStyle()
    }

    // MARK: - Pricing Results Section

    private var pricingResultsSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Large Card Image
            if let selectedMatch = lookupState.selectedMatch {
                cardImageSection(selectedMatch)

                // Card Details
                cardDetailsSection(selectedMatch)
            }

            // TCGPlayer Section
            if let tcgPrices = lookupState.tcgPlayerPrices, tcgPrices.hasAnyPricing {
                tcgPlayerPricingSection(tcgPrices)
            } else {
                noPricingAvailableSection
            }

            // eBay Section (Placeholder)
            ebayPlaceholderSection

            // Bottom Actions
            bottomActionsSection
        }
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
    }

    private func tcgPlayerPricingSection(_ pricing: DetailedTCGPlayerPricing) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)

                Text("TCGPlayer Pricing")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()
            }

            // Price Cards Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                ForEach(pricing.availableVariants, id: \.name) { variant in
                    priceCard(variantName: variant.name, pricing: variant.pricing)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }

    private func priceCard(variantName: String, pricing: DetailedTCGPlayerPricing.PriceBreakdown) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Variant Name
            Text(variantName)
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Divider()

            // Pricing Details
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                if let market = pricing.market {
                    HStack {
                        Text("Market:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", market))")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.success)
                    }
                }

                if let low = pricing.low {
                    HStack {
                        Text("Low:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", low))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                }

                if let mid = pricing.mid {
                    HStack {
                        Text("Mid:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", mid))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                }

                if let high = pricing.high {
                    HStack {
                        Text("High:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", high))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
        )
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
                copyPricesToClipboard()
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

            Button {
                lookupState.reset()
            } label: {
                Text("New Lookup")
                    .font(DesignSystem.Typography.labelLarge)
                    .frame(maxWidth: .infinity)
            }
            .secondaryButtonStyle()
        }
    }

    // MARK: - Match Selection Sheet

    private var matchSelectionSheet: some View {
        NavigationStack {
            List {
                ForEach(lookupState.availableMatches) { match in
                    Button {
                        selectMatch(match)
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            // Larger Card Image (100x140)
                            if let imageURL = match.imageURL {
                                AsyncImage(url: imageURL) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .tint(DesignSystem.Colors.cyan)
                                            .frame(width: 100, height: 140)
                                            .background(DesignSystem.Colors.backgroundTertiary)
                                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 140)
                                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                                    case .failure:
                                        VStack(spacing: DesignSystem.Spacing.xxxs) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 24))
                                                .foregroundStyle(DesignSystem.Colors.textTertiary)

                                            Text("No Image")
                                                .font(DesignSystem.Typography.caption)
                                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                                        }
                                        .frame(width: 100, height: 140)
                                        .background(DesignSystem.Colors.backgroundTertiary)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }

                            // Enhanced Card Info
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                // Card Name - Larger and more prominent
                                Text(match.cardName)
                                    .font(DesignSystem.Typography.heading4)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)

                                // Set Name - Better spacing
                                Text(match.setName)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .lineLimit(1)

                                // Card Number - Clear display
                                Text("#\(match.cardNumber)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                    .listRowBackground(DesignSystem.Colors.backgroundSecondary)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Select Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showMatchSelection = false
                    }
                }
            }
        }
    }

    // MARK: - Methods

    private func performLookup() {
        Task {
            lookupState.isLoading = true
            lookupState.errorMessage = nil

            do {
                // Search for matching cards
                let matches = try await pokemonService.searchCard(
                    name: lookupState.cardName,
                    number: lookupState.cardNumber.isEmpty ? nil : lookupState.cardNumber
                )

                guard !matches.isEmpty else {
                    lookupState.errorMessage = "No cards found matching '\(lookupState.cardName)'"
                    lookupState.isLoading = false
                    return
                }

                // If multiple matches, show selection sheet
                if matches.count > 1 {
                    lookupState.availableMatches = matches
                    showMatchSelection = true
                    lookupState.isLoading = false
                    return
                }

                // Single match - fetch pricing directly
                let match = matches[0]
                lookupState.selectedMatch = match

                let detailedPricing = try await pokemonService.getDetailedPricing(cardID: match.id)
                lookupState.tcgPlayerPrices = detailedPricing

                lookupState.addToRecentSearches(lookupState.cardName)
                lookupState.isLoading = false

            } catch {
                lookupState.errorMessage = "Failed to lookup pricing: \(error.localizedDescription)"
                lookupState.isLoading = false
            }
        }
    }

    private func selectMatch(_ match: CardMatch) {
        lookupState.selectedMatch = match
        showMatchSelection = false

        Task {
            lookupState.isLoading = true
            do {
                let detailedPricing = try await pokemonService.getDetailedPricing(cardID: match.id)
                lookupState.tcgPlayerPrices = detailedPricing
                lookupState.addToRecentSearches(lookupState.cardName)
                lookupState.isLoading = false
            } catch {
                lookupState.errorMessage = "Failed to fetch pricing: \(error.localizedDescription)"
                lookupState.isLoading = false
            }
        }
    }

    private func copyPricesToClipboard() {
        guard let pricing = lookupState.tcgPlayerPrices,
              let match = lookupState.selectedMatch else { return }

        var text = "\(match.cardName) #\(match.cardNumber)\n"
        text += "\(match.setName)\n\n"

        for variant in pricing.availableVariants {
            text += "\(variant.name): \(variant.pricing.displayPrice)\n"
        }

        UIPasteboard.general.string = text

        // TODO: Show success feedback (toast or alert)
    }
}
