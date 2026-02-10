import Foundation

/// State management for the Card Price Lookup view
@MainActor
@Observable
final class PriceLookupState {
    // Search input
    var cardName: String = ""
    var cardNumber: String = ""
    var parsedCardNumber: String? { cardNumber.isEmpty ? nil : cardNumber }

    // Condition selection
    var selectedCondition: PriceCondition = .nearMint

    // Loading state
    var isLoading: Bool = false
    var errorMessage: String?

    // Results
    var selectedMatch: CardMatch?
    var availableMatches: [CardMatch] = []
    var tcgPlayerPrices: DetailedTCGPlayerPricing?
    var tcgplayerId: String?

    // JustTCG condition pricing
    var conditionPrices: ConditionPrices?
    var priceChange7d: Double?
    var priceChange30d: Double?
    var priceHistory: [PricePoint]?

    // Cache state
    var isFromCache: Bool = false
    var cacheAgeHours: Double?

    // Autocomplete
    var autocompleteSuggestions: [String] = []

    // Recent searches
    var recentSearches: [RecentSearch] = []

    // MARK: - Computed Properties

    /// Whether we have enough data to perform a lookup
    var canLookupPrice: Bool {
        !cardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether JustTCG condition pricing is available
    var hasJustTCGPricing: Bool {
        conditionPrices != nil && !(conditionPrices?.availableConditions.isEmpty ?? true)
    }

    /// Current price based on selected condition
    var currentConditionPrice: Double? {
        conditionPrices?.price(for: selectedCondition) ?? tcgPlayerPrices?.bestAvailablePrice
    }

    /// Formatted cache age string
    var cacheAge: String {
        guard let hours = cacheAgeHours else { return "" }
        if hours < 1 {
            return "< 1h ago"
        } else if hours < 24 {
            return "\(Int(hours))h ago"
        } else {
            return "\(Int(hours / 24))d ago"
        }
    }

    // MARK: - Methods

    func addToRecentSearches(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.cardName.lowercased() == trimmed.lowercased() }
        recentSearches.insert(RecentSearch(cardName: trimmed), at: 0)
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
    }

    func clearError() {
        errorMessage = nil
    }

    /// Reset for a new lookup
    func reset() {
        selectedMatch = nil
        availableMatches = []
        tcgPlayerPrices = nil
        tcgplayerId = nil
        conditionPrices = nil
        priceChange7d = nil
        priceChange30d = nil
        priceHistory = nil
        isFromCache = false
        cacheAgeHours = nil
        errorMessage = nil
        isLoading = false
    }
}
