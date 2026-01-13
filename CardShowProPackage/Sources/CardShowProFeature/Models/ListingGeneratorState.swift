import Foundation
import Observation

/// Phase of the listing generation flow
public enum ListingGenerationPhase: Sendable {
    case input
    case generating
    case output
}

/// Observable state for the Listing Generator feature
@MainActor
@Observable
public final class ListingGeneratorState: Sendable {
    // MARK: - Phase Management
    public var currentPhase: ListingGenerationPhase = .input

    // MARK: - Input State
    public var selectedCard: InventoryCard?
    public var selectedPlatform: ListingPlatform = .ebay
    public var selectedCondition: ListingCondition = .nearMint
    public var pricingStrategy: PricingStrategy = .market

    // MARK: - Generation State
    public var isGenerating: Bool = false
    public var generationProgress: Double = 0.0 // 0.0 to 1.0

    // MARK: - Output State
    public var generatedListing: GeneratedListing?

    // MARK: - UI State
    public var showCardPicker: Bool = false
    public var showCopyToast: Bool = false

    // MARK: - Computed Properties

    /// Whether the generate button should be enabled
    public var canGenerate: Bool {
        selectedCard != nil && !isGenerating
    }

    /// Estimated base price from selected card
    public var basePrice: Double {
        selectedCard?.marketValue ?? 0.0
    }

    /// Calculated price based on condition and strategy
    public var calculatedPrice: Double {
        basePrice * selectedCondition.valueMultiplier * pricingStrategy.priceMultiplier
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Actions

    /// Start the generation process
    public func startGeneration() {
        guard canGenerate else { return }
        currentPhase = .generating
        isGenerating = true
        generationProgress = 0.0
    }

    /// Complete the generation with result
    public func completeGeneration(listing: GeneratedListing) {
        generatedListing = listing
        isGenerating = false
        generationProgress = 1.0
        currentPhase = .output
    }

    /// Reset to initial state
    public func reset() {
        currentPhase = .input
        selectedCard = nil
        selectedPlatform = .ebay
        selectedCondition = .nearMint
        pricingStrategy = .market
        isGenerating = false
        generationProgress = 0.0
        generatedListing = nil
        showCardPicker = false
        showCopyToast = false
    }

    /// Go back to input phase for new listing
    public func startNewListing() {
        currentPhase = .input
        isGenerating = false
        generationProgress = 0.0
        generatedListing = nil
        showCopyToast = false
        // Keep card and settings for quick iterations
    }
}
