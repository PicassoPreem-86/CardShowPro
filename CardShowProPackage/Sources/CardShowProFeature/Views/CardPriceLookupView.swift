import SwiftUI
import SwiftData

/// Card Price Lookup Tool
/// Allows users to lookup card prices WITHOUT adding to inventory
@MainActor
struct CardPriceLookupView: View {
    @State private var lookupState = PriceLookupState()
    @State private var showMatchSelection = false
    @State private var showCopySuccess = false
    @State private var showInventoryEntry = false
    @State private var showPriceHistory = false
    @State private var autocompleteTask: Task<Void, Never>?
    @State private var dismissToastTask: Task<Void, Never>?
    @FocusState private var focusedField: Field?
    private let pokemonService = PokemonTCGService.shared
    private let justTCGService = JustTCGService.shared
    private let localDatabase = LocalCardDatabase.shared

    // Cache integration
    @Environment(\.modelContext) private var modelContext
    private var priceCache: PriceCacheRepository {
        PriceCacheRepository(modelContext: modelContext)
    }

    enum Field {
        case cardName
        case cardNumber
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Nebula background layer
                NebulaBackgroundView()

                // Content layer
                ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    headerSection

                    // Recent Searches (if available)
                    if !lookupState.recentSearches.isEmpty {
                        RecentSearchesView(
                            searches: lookupState.recentSearches,
                            onSelect: { cardName in
                                lookupState.cardName = cardName
                                focusedField = nil // Dismiss keyboard
                                performLookup()
                            },
                            onClear: {
                                lookupState.clearRecentSearches()
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

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
                .padding(DesignSystem.Spacing.md)
            }
            }
            .background(Color.clear)
            .navigationTitle("Price Lookup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
                }
            }
            .overlay(alignment: .top) {
                if showCopySuccess {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.success)
                        Text("Prices copied to clipboard")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showMatchSelection) {
                matchSelectionSheet
            }
            .sheet(isPresented: $showInventoryEntry) {
                if let entryData = prepareInventoryEntry() {
                    NavigationStack {
                        let scanState = ScanFlowState()
                        let _ = {
                            scanState.cardNumber = entryData.cardNumber
                            scanState.fetchedPrice = entryData.price
                            scanState.cardImageURL = entryData.imageURL
                        }()

                        CardEntryView(
                            pokemonName: entryData.pokemonName,
                            setName: entryData.setName,
                            setID: entryData.setID,
                            state: scanState
                        )
                    }
                }
            }
            .sheet(isPresented: $showPriceHistory) {
                if let match = lookupState.selectedMatch {
                    PriceHistorySheet(
                        priceHistory: lookupState.priceHistory ?? [],
                        cardName: match.cardName,
                        currentPrice: lookupState.currentConditionPrice,
                        priceChange7d: lookupState.priceChange7d,
                        priceChange30d: lookupState.priceChange30d
                    )
                }
            }
            .onDisappear {
                autocompleteTask?.cancel()
                dismissToastTask?.cancel()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Card Price Lookup")
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

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

            // Card Number Input (Consolidated)
            cardNumberInput
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
                .background(DesignSystem.Colors.backgroundTertiary.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1.5)
                )
                .autocorrectionDisabled()
                .textContentType(.name)
                .focused($focusedField, equals: .cardName)
                .submitLabel(.search)
                .onSubmit {
                    if !lookupState.cardName.isEmpty {
                        performLookup() // Trigger lookup when user presses Search
                    } else {
                        focusedField = .cardNumber
                    }
                }
                .accessibilityLabel("Card Name")
                .accessibilityHint("Enter the Pokemon card name to search")
        }
    }

    private var cardNumberInput: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Card Number")
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            TextField("25/102 or 25", text: $lookupState.cardNumber)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1.5)
                )
                .keyboardType(.default)
                .focused($focusedField, equals: .cardNumber)
                .submitLabel(.search) // Changed from .done to .search
                .onSubmit {
                    if lookupState.canLookupPrice {
                        performLookup() // Trigger lookup if we have enough info
                    } else {
                        focusedField = nil
                    }
                }
                .accessibilityLabel("Card Number")
                .accessibilityHint("Optional: Enter card number like 25 slash 102 or just 25")

            Text("Optional: Enter card number (e.g., 25/102 or 25)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
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
        .accessibilityLabel("Look up card price")
        .accessibilityHint("Searches for current pricing from TCGPlayer")
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
                tcgPlayerPricingSection(tcgPrices)
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
            ConditionPriceSelector(
                selectedCondition: Binding(
                    get: { lookupState.selectedCondition },
                    set: { lookupState.selectedCondition = $0 }
                ),
                conditionPrices: lookupState.conditionPrices,
                priceChange7d: lookupState.priceChange7d,
                onPriceHistoryTap: lookupState.priceHistory != nil ? {
                    showPriceHistory = true
                } : nil
            )
        }
        .padding(DesignSystem.Spacing.md)
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
            .accessibilityLabel("Copy all prices to clipboard")

            Button {
                showInventoryEntry = true
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
            .disabled(prepareInventoryEntry() == nil)
            .opacity(prepareInventoryEntry() != nil ? 1.0 : 0.5)
            .accessibilityLabel("Add card to inventory")
            .accessibilityHint("Opens card entry form with pre-filled data from this lookup")

            Button {
                lookupState.reset()
                focusedField = .cardName // Auto-focus keyboard for next lookup
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

    private func prepareInventoryEntry() -> (pokemonName: String, setName: String, setID: String, cardNumber: String, price: Double, imageURL: URL?)? {
        guard let match = lookupState.selectedMatch,
              let pricing = lookupState.tcgPlayerPrices,
              let normalVariant = pricing.availableVariants.first(where: { $0.name == "Normal" }),
              let marketPrice = normalVariant.pricing.market
        else { return nil }

        return (
            pokemonName: match.cardName,
            setName: match.setName,
            setID: match.setID,
            cardNumber: match.cardNumber,
            price: marketPrice,
            imageURL: match.imageURL
        )
    }

    private func performLookup() {
        Task {
            let startTime = Date()
            lookupState.isLoading = true
            lookupState.errorMessage = nil
            lookupState.isFromCache = false
            lookupState.cacheAgeHours = nil

            // Generate cache key for lookup
            let cacheKey = generateCacheKey(lookupState.cardName, lookupState.parsedCardNumber)

            do {
                // CACHE FIRST: Check cache before any search
                if let cachedPrice = try? priceCache.getPrice(cardID: cacheKey) {
                    // Check if fresh (< 24 hours)
                    if !cachedPrice.isStale {
                        let duration = Date().timeIntervalSince(startTime)
                        print("✅ CACHE HIT: \(cacheKey) (age: \(cachedPrice.ageInHours)h, duration: \(String(format: "%.2f", duration))s)")
                        displayCachedResult(cachedPrice)
                        lookupState.isLoading = false
                        return
                    } else {
                        print("⚠️ STALE CACHE: \(cacheKey) (age: \(cachedPrice.ageInHours)h) - Refreshing...")
                    }
                }

                print("❌ CACHE MISS: \(cacheKey) - Searching local database...")

                // LOCAL DATABASE SEARCH FIRST (fast <50ms)
                // Ensure database is initialized
                if await !localDatabase.isReady {
                    try await localDatabase.initialize()
                }

                let localSearchStart = CFAbsoluteTimeGetCurrent()
                let localMatches = try await localDatabase.search(
                    name: lookupState.cardName,
                    number: lookupState.parsedCardNumber,
                    limit: 50
                )
                let localSearchTime = (CFAbsoluteTimeGetCurrent() - localSearchStart) * 1000
                print("🗄️ LOCAL DB: Found \(localMatches.count) matches in \(String(format: "%.1f", localSearchTime))ms")

                // Convert LocalCardMatch to CardMatch for UI
                let matches = localMatches.map { $0.toCardMatch() }

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

                // Single match - fetch pricing from API
                let match = matches[0]
                lookupState.selectedMatch = match

                let (detailedPricing, tcgplayerId) = try await pokemonService.getDetailedPricing(cardID: match.id)
                lookupState.tcgPlayerPrices = detailedPricing
                lookupState.tcgplayerId = tcgplayerId

                // SAVE TO CACHE
                savePriceToCache(match: match, pricing: detailedPricing)

                let duration = Date().timeIntervalSince(startTime)
                print("⏱️ TOTAL LOOKUP: \(cacheKey) took \(String(format: "%.2f", duration))s (local: \(String(format: "%.0f", localSearchTime))ms)")

                lookupState.addToRecentSearches(lookupState.cardName)
                lookupState.isLoading = false

                // Attempt to fetch JustTCG pricing in background
                if let fetchedTcgplayerId = tcgplayerId {
                    print("🔗 Found TCGPlayer ID: \(fetchedTcgplayerId) - fetching JustTCG pricing")
                    Task {
                        await fetchJustTCGPricing(tcgplayerId: fetchedTcgplayerId, cardID: match.id)
                    }
                } else {
                    print("⚠️ No TCGPlayer ID available - JustTCG pricing unavailable")
                }

            } catch {
                let duration = Date().timeIntervalSince(startTime)
                print("❌ LOOKUP FAILED: \(cacheKey) after \(String(format: "%.2f", duration))s - \(error)")

                // Improved error messages for common failures
                let errorMessage: String

                if error is DatabaseError {
                    // All database errors get a generic message
                    errorMessage = "Card database error. Please try again or reinstall the app."
                } else if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        errorMessage = "No internet connection. Please check your WiFi or cellular data."
                    case .timedOut:
                        errorMessage = "Request timed out. The server took too long to respond. Please try again."
                    case .cannotFindHost, .cannotConnectToHost:
                        errorMessage = "Cannot reach pricing servers. Please try again later."
                    case .networkConnectionLost:
                        errorMessage = "Network connection lost. Please check your connection and try again."
                    default:
                        errorMessage = "Network error: \(urlError.localizedDescription)"
                    }
                } else {
                    errorMessage = "Failed to lookup pricing. Please try again."
                }

                lookupState.errorMessage = errorMessage
                lookupState.isLoading = false
            }
        }
    }

    private func selectMatch(_ match: CardMatch) {
        lookupState.selectedMatch = match
        showMatchSelection = false

        // Cancel any existing pricing fetch
        autocompleteTask?.cancel()

        Task {
            let startTime = Date()
            lookupState.isLoading = true
            lookupState.isFromCache = false
            lookupState.cacheAgeHours = nil

            // CACHE FIRST: Check cache for this specific match
            if let cachedPrice = try? priceCache.getPrice(cardID: match.id), !cachedPrice.isStale {
                let duration = Date().timeIntervalSince(startTime)
                print("✅ CACHE HIT (selectMatch): \(match.id) (age: \(cachedPrice.ageInHours)h, duration: \(String(format: "%.2f", duration))s)")
                displayCachedResult(cachedPrice)
                lookupState.isLoading = false
                return
            }

            // CACHE MISS OR STALE: Fetch from API
            do {
                let (detailedPricing, tcgplayerId) = try await pokemonService.getDetailedPricing(cardID: match.id)
                lookupState.tcgPlayerPrices = detailedPricing
                lookupState.tcgplayerId = tcgplayerId

                // SAVE TO CACHE
                savePriceToCache(match: match, pricing: detailedPricing)

                let duration = Date().timeIntervalSince(startTime)
                print("⏱️ API LOOKUP (selectMatch): \(match.id) took \(String(format: "%.2f", duration))s")

                lookupState.addToRecentSearches(lookupState.cardName)
                lookupState.isLoading = false

                // Attempt to fetch JustTCG pricing in background
                if let fetchedTcgplayerId = tcgplayerId {
                    print("🔗 Found TCGPlayer ID: \(fetchedTcgplayerId) - fetching JustTCG pricing")
                    Task {
                        await fetchJustTCGPricing(tcgplayerId: fetchedTcgplayerId, cardID: match.id)
                    }
                } else {
                    print("⚠️ No TCGPlayer ID available - JustTCG pricing unavailable")
                }
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                print("❌ LOOKUP FAILED (selectMatch): \(match.id) after \(String(format: "%.2f", duration))s")

                // Improved error messages for common network failures
                let errorMessage: String

                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        errorMessage = "No internet connection. Please check your WiFi or cellular data."
                    case .timedOut:
                        errorMessage = "Request timed out. The server took too long to respond. Please try again."
                    case .cannotFindHost, .cannotConnectToHost:
                        errorMessage = "Cannot reach PokemonTCG.io servers. Please try again later."
                    case .networkConnectionLost:
                        errorMessage = "Network connection lost. Please check your connection and try again."
                    default:
                        errorMessage = "Network error: \(urlError.localizedDescription)"
                    }
                } else {
                    errorMessage = "Failed to fetch pricing. Please try again."
                }

                lookupState.errorMessage = errorMessage
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

        // Show success feedback
        withAnimation(.easeInOut(duration: 0.3)) {
            showCopySuccess = true
        }

        // Auto-dismiss after 2 seconds
        dismissToastTask?.cancel()
        dismissToastTask = Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.3)) {
                showCopySuccess = false
            }
        }
    }

    // MARK: - JustTCG Integration

    /// Fetch JustTCG condition pricing for the current card
    private func fetchJustTCGPricing(tcgplayerId: String, cardID: String) async {
        guard justTCGService.isConfigured else {
            print("⚠️ JustTCG API not configured - skipping condition pricing")
            return
        }

        do {
            print("🔍 Fetching JustTCG pricing for TCGPlayer ID: \(tcgplayerId)")
            let justTCGCard = try await justTCGService.getCardPricing(
                tcgplayerId: tcgplayerId,
                includePriceHistory: true
            )

            // Update lookup state with JustTCG data
            // Use bestAvailableConditionPrices() to handle both Normal and Foil cards
            let conditionPrices = ConditionPrices(from: justTCGCard.bestAvailableConditionPrices())
            lookupState.conditionPrices = conditionPrices
            print("📊 JustTCG available printings: \(justTCGCard.availablePrintings), primary: \(justTCGCard.primaryPrinting)")
            lookupState.priceChange7d = justTCGCard.priceChange7d
            lookupState.priceChange30d = justTCGCard.priceChange30d
            lookupState.priceHistory = justTCGCard.nearMintPriceHistory
            lookupState.tcgplayerId = tcgplayerId

            print("✅ JustTCG pricing loaded: \(conditionPrices.availableConditions.count) conditions")

            // Update cache with JustTCG data
            if var cachedPrice = try? priceCache.getPrice(cardID: cardID) {
                cachedPrice.setConditionPrices(conditionPrices)
                cachedPrice.priceChange7d = justTCGCard.priceChange7d
                cachedPrice.priceChange30d = justTCGCard.priceChange30d
                cachedPrice.tcgplayerId = tcgplayerId
                cachedPrice.justTCGLastUpdated = Date()
                if let history = justTCGCard.nearMintPriceHistory {
                    cachedPrice.setPriceHistory(history)
                }
                try? priceCache.savePrice(cachedPrice)
                print("💾 JustTCG data cached for: \(cardID)")
            }
        } catch {
            print("⚠️ JustTCG fetch failed: \(error.localizedDescription)")
            // Non-critical - we still have TCGPlayer pricing
        }
    }

    // MARK: - Cache Helper Methods

    /// Generate cache key from card name and number
    private func generateCacheKey(_ cardName: String, _ cardNumber: String?) -> String {
        let normalized = cardName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let number = cardNumber {
            return "\(normalized)_\(number)"
        }
        return normalized
    }

    /// Display cached result in UI
    private func displayCachedResult(_ cachedPrice: CachedPrice) {
        // Reconstruct CardMatch from cache
        lookupState.selectedMatch = CardMatch(
            id: cachedPrice.cardID,
            cardName: cachedPrice.cardName,
            setName: cachedPrice.setName,
            setID: cachedPrice.setID,
            cardNumber: cachedPrice.cardNumber,
            imageURL: cachedPrice.imageURLLarge.flatMap { URL(string: $0) }
        )

        // Reconstruct DetailedTCGPlayerPricing from cache
        var pricing = DetailedTCGPlayerPricing(
            normal: nil,
            holofoil: nil,
            reverseHolofoil: nil,
            firstEdition: nil,
            unlimited: nil
        )

        // Try to load full variant pricing from JSON first
        if let variantData = cachedPrice.variantPricesJSON,
           let variantPricing = try? JSONDecoder().decode(VariantPricing.self, from: variantData) {
            pricing = DetailedTCGPlayerPricing(
                normal: variantPricing.normal.map { DetailedTCGPlayerPricing.PriceBreakdown(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
                holofoil: variantPricing.holofoil.map { DetailedTCGPlayerPricing.PriceBreakdown(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
                reverseHolofoil: variantPricing.reverseHolofoil.map { DetailedTCGPlayerPricing.PriceBreakdown(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
                firstEdition: variantPricing.firstEdition.map { DetailedTCGPlayerPricing.PriceBreakdown(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
                unlimited: variantPricing.unlimited.map { DetailedTCGPlayerPricing.PriceBreakdown(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) }
            )
        } else if cachedPrice.marketPrice != nil || cachedPrice.lowPrice != nil {
            // Fallback: If we have basic pricing but no variant JSON, create a "Normal" variant
            pricing = DetailedTCGPlayerPricing(
                normal: DetailedTCGPlayerPricing.PriceBreakdown(
                    low: cachedPrice.lowPrice,
                    mid: cachedPrice.midPrice,
                    high: cachedPrice.highPrice,
                    market: cachedPrice.marketPrice
                ),
                holofoil: nil,
                reverseHolofoil: nil,
                firstEdition: nil,
                unlimited: nil
            )
        }

        lookupState.tcgPlayerPrices = pricing
        lookupState.isFromCache = true
        lookupState.cacheAgeHours = cachedPrice.ageInHours
        lookupState.addToRecentSearches(cachedPrice.cardName)

        // Load JustTCG condition pricing from cache
        lookupState.conditionPrices = cachedPrice.conditionPrices
        lookupState.priceChange7d = cachedPrice.priceChange7d
        lookupState.priceChange30d = cachedPrice.priceChange30d
        lookupState.priceHistory = cachedPrice.priceHistory
        lookupState.tcgplayerId = cachedPrice.tcgplayerId
    }

    /// Save price to cache after API fetch
    private func savePriceToCache(match: CardMatch, pricing: DetailedTCGPlayerPricing) {
        // Extract BEST AVAILABLE variant pricing (not just normal)
        // Priority: normal > holofoil > reverseHolofoil > firstEdition > unlimited
        let bestVariant = pricing.normal ?? pricing.holofoil ?? pricing.reverseHolofoil ?? pricing.firstEdition ?? pricing.unlimited

        let cachedPrice = CachedPrice(
            cardID: match.id,
            cardName: match.cardName,
            setName: match.setName,
            setID: match.setID,
            cardNumber: match.cardNumber,
            marketPrice: bestVariant?.market,
            lowPrice: bestVariant?.low,
            midPrice: bestVariant?.mid,
            highPrice: bestVariant?.high,
            imageURLSmall: match.imageURL?.absoluteString,
            imageURLLarge: match.imageURL?.absoluteString
        )

        // Store full variant pricing as JSON for complete reconstruction
        let variantPricing = VariantPricing(
            normal: pricing.normal.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
            holofoil: pricing.holofoil.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
            reverseHolofoil: pricing.reverseHolofoil.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
            firstEdition: pricing.firstEdition.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
            unlimited: pricing.unlimited.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) }
        )
        cachedPrice.variantPricesJSON = try? JSONEncoder().encode(variantPricing)

        do {
            try priceCache.savePrice(cachedPrice)
            print("💾 CACHED: \(match.id) (variants: \(pricing.availableVariants.map { $0.name }.joined(separator: ", ")))")
        } catch {
            print("⚠️ Failed to cache price: \(error)")
        }
    }
}
