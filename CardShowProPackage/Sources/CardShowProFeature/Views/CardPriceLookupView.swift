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
    private let lookupService = PriceLookupService()

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
                        PriceLookupResultsView(
                            lookupState: lookupState,
                            onCopyPrices: { copyPricesToClipboard() },
                            onAddToInventory: { showInventoryEntry = true },
                            onNewLookup: {
                                lookupState.reset()
                                focusedField = .cardName
                            },
                            onShowPriceHistory: { showPriceHistory = true },
                            canAddToInventory: lookupService.prepareInventoryEntry(state: lookupState) != nil
                        )
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
            .task {
                lookupState.loadRecentSearches()
            }
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
                PriceLookupMatchSheet(
                    matches: lookupState.availableMatches,
                    onSelect: { match in
                        selectMatch(match)
                    },
                    onCancel: {
                        showMatchSelection = false
                    }
                )
            }
            .sheet(isPresented: $showInventoryEntry) {
                if let entryData = lookupService.prepareInventoryEntry(state: lookupState) {
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
                        performLookup()
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
                .submitLabel(.search)
                .onSubmit {
                    if lookupState.canLookupPrice {
                        performLookup()
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

    // MARK: - Methods

    private func performLookup() {
        Task {
            await lookupService.performLookup(
                state: lookupState,
                cache: priceCache,
                onShowMatches: {
                    showMatchSelection = true
                }
            )
        }
    }

    private func selectMatch(_ match: CardMatch) {
        lookupState.selectedMatch = match
        showMatchSelection = false

        // Cancel any existing pricing fetch
        autocompleteTask?.cancel()

        Task {
            await lookupService.selectMatch(
                match,
                state: lookupState,
                cache: priceCache
            )
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
}
