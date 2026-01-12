import SwiftUI
import SwiftData

struct CardEntryView: View {
    let pokemonName: String
    let setName: String
    let setID: String
    @Bindable var state: ScanFlowState
    @Environment(\.modelContext) private var modelContext
    @State private var service = PokemonTCGService.shared

    // UI State
    @State private var isLoadingCard = false
    @State private var errorMessage: String?

    var isFormValid: Bool {
        !state.cardNumber.isEmpty && state.fetchedPrice != nil
    }

    private var accessibilityHintText: String {
        guard isFormValid, let basePrice = state.fetchedPrice else {
            return "Enter card number to enable"
        }
        let finalPrice = basePrice * state.selectedVariant.priceMultiplier * state.selectedCondition.priceMultiplier
        return "Saves this card with price $\(String(format: "%.2f", finalPrice))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card Image Preview
                CardImageSection(
                    imageURL: state.cardImageURL,
                    isLoading: isLoadingCard
                )

                // Card Number Input
                CardNumberSection(
                    cardNumber: $state.cardNumber,
                    onCardNumberChanged: fetchCardDetails
                )

                // Variant Selector
                VariantSelectorSection(selectedVariant: $state.selectedVariant)

                // Condition Selector
                ConditionSelectorSection(selectedCondition: $state.selectedCondition)

                // Market Price Display
                if let price = state.fetchedPrice {
                    MarketPriceSection(
                        basePrice: price,
                        variant: state.selectedVariant,
                        condition: state.selectedCondition
                    )
                }

                // Error Message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Add to Inventory Button
                Button {
                    addToInventory()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Inventory")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.cyan : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid)
                .padding(.horizontal)
                .padding(.top, 8)
                .accessibilityLabel("Add card to inventory")
                .accessibilityHint(accessibilityHintText)
            }
            .padding(.vertical)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("\(pokemonName) • \(setName)")
                        .font(.headline)
                    Text("Add Card")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Actions

    private func fetchCardDetails() {
        guard !state.cardNumber.isEmpty else {
            state.fetchedPrice = nil
            state.cardImageURL = nil
            errorMessage = nil
            return
        }

        Task {
            isLoadingCard = true
            errorMessage = nil

            do {
                let result = try await service.getCard(
                    pokemonName: pokemonName,
                    setID: setID,
                    cardNumber: state.cardNumber
                )

                // Update state with fetched data
                state.fetchedPrice = result.pricing.estimatedValue
                state.cardImageURL = URL(string: result.card.images.large)

            } catch {
                errorMessage = "Could not fetch card details. Please try again."
                state.fetchedPrice = nil
                state.cardImageURL = nil
            }

            isLoadingCard = false
        }
    }

    private func addToInventory() {
        guard isFormValid, let basePrice = state.fetchedPrice else { return }

        // Calculate adjusted price based on variant and condition
        let variantMultiplier = state.selectedVariant.priceMultiplier
        let conditionMultiplier = state.selectedCondition.priceMultiplier
        let finalPrice = basePrice * variantMultiplier * conditionMultiplier

        // Create inventory card
        let newCard = InventoryCard(
            cardName: pokemonName,
            cardNumber: state.cardNumber,
            setName: setName,
            gameType: CardGame.pokemon.rawValue,
            estimatedValue: finalPrice,
            confidence: 1.0, // Manual entry = 100% confidence
            timestamp: Date(),
            imageData: nil // We'll download the image in the future
        )

        // Save to SwiftData
        modelContext.insert(newCard)

        do {
            try modelContext.save()

            // Success haptic
            HapticManager.shared.success()

            // Navigate to success with animation
            withAnimation(.spring(response: 0.3)) {
                state.currentStep = .success(card: newCard)
            }

        } catch {
            // Error haptic
            HapticManager.shared.error()
            errorMessage = "Failed to save card. Please try again."
        }
    }
}

// MARK: - Subviews

private struct CardImageSection: View {
    let imageURL: URL?
    let isLoading: Bool

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(width: 250, height: 350)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 250, height: 350)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 8)
                    case .failure:
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                            Text("Image not available")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 250, height: 350)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                    Text("Enter card number to preview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 250, height: 350)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }
}

private struct CardNumberSection: View {
    @Binding var cardNumber: String
    let onCardNumberChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Number")
                .font(.headline)
                .padding(.horizontal)

            TextField("e.g., 001, 025, 150", text: $cardNumber)
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .onChange(of: cardNumber) { _, _ in
                    onCardNumberChanged()
                }
                .accessibilityLabel("Card number")
        }
    }
}

private struct VariantSelectorSection: View {
    @Binding var selectedVariant: CardVariant

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Variant")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CardVariant.allCases, id: \.self) { variant in
                        Button {
                            HapticManager.shared.light()
                            withAnimation(.spring(response: 0.3)) {
                                selectedVariant = variant
                            }
                        } label: {
                            Text(variant.displayName)
                                .font(.subheadline)
                                .fontWeight(selectedVariant == variant ? .semibold : .regular)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    selectedVariant == variant
                                        ? Color.cyan
                                        : Color.gray.opacity(0.2)
                                )
                                .foregroundStyle(
                                    selectedVariant == variant
                                        ? .white
                                        : .primary
                                )
                                .clipShape(Capsule())
                        }
                        .accessibilityLabel("\(variant.displayName), \(selectedVariant == variant ? "selected" : "not selected")")
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct ConditionSelectorSection: View {
    @Binding var selectedCondition: CardCondition

    private let shortConditions: [(CardCondition, String)] = [
        (.mint, "M"),
        (.nearMint, "NM"),
        (.excellent, "LP"),
        (.good, "MP"),
        (.played, "HP"),
        (.poor, "DMG")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Condition")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(shortConditions, id: \.0) { condition, shortName in
                        Button {
                            HapticManager.shared.light()
                            withAnimation(.spring(response: 0.3)) {
                                selectedCondition = condition
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(shortName)
                                    .font(.headline)
                                Text(condition.rawValue)
                                    .font(.caption2)
                            }
                            .fontWeight(selectedCondition == condition ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedCondition == condition
                                    ? Color.cyan
                                    : Color.gray.opacity(0.2)
                            )
                            .foregroundStyle(
                                selectedCondition == condition
                                    ? .white
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .accessibilityLabel("\(condition.rawValue), \(selectedCondition == condition ? "selected" : "not selected")")
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct MarketPriceSection: View {
    let basePrice: Double
    let variant: CardVariant
    let condition: CardCondition

    private var adjustedPrice: Double {
        basePrice * variant.priceMultiplier * condition.priceMultiplier
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Market Price")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("$\(adjustedPrice, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.cyan)
                        .contentTransition(.numericText())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Base: $\(basePrice, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if variant.priceMultiplier != 1.0 {
                        Text("\(variant.displayName): \(variant.priceMultiplier, specifier: "%.1f")x")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .transition(.opacity.combined(with: .scale))
                    }
                    if condition.priceMultiplier != 1.0 {
                        Text("\(condition.rawValue): \(condition.priceMultiplier, specifier: "%.1f")x")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            }
            .padding()
            .background(Color.cyan.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .animation(.spring(response: 0.3), value: adjustedPrice)
    }
}

// MARK: - CardCondition Extension

extension CardCondition {
    var priceMultiplier: Double {
        switch self {
        case .mint: return 1.2
        case .nearMint: return 1.0
        case .excellent: return 0.8
        case .good: return 0.6
        case .played: return 0.4
        case .poor: return 0.2
        }
    }
}

