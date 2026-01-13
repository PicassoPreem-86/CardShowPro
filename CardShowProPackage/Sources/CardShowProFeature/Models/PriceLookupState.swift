import Foundation

/// State model for the Card Price Lookup Tool
/// This tool allows users to look up card prices WITHOUT adding to inventory
@MainActor
@Observable
final class PriceLookupState: Sendable {
    // MARK: - Input Fields

    /// Pokemon card name (required)
    var cardName: String = ""

    /// Card number in "25/102" or "25" format
    var cardNumber: String = ""

    // MARK: - Pricing Data

    /// Detailed TCGPlayer pricing with all variants
    var tcgPlayerPrices: DetailedTCGPlayerPricing?

    /// eBay last sold pricing (placeholder for Phase 2)
    var ebayLastSold: EbayPricing?

    // MARK: - UI State

    /// Loading indicator
    var isLoading: Bool = false

    /// Error message to display
    var errorMessage: String?

    // MARK: - Card Search State

    /// Currently selected card match
    var selectedMatch: CardMatch?

    /// Available card matches from search
    var availableMatches: [CardMatch] = []

    /// Recent search queries (limit to 5) - persisted to UserDefaults
    var recentSearches: [String] = [] {
        didSet {
            UserDefaults.standard.set(recentSearches, forKey: "recentCardSearches")
        }
    }

    /// Autocomplete suggestions
    var autocompleteSuggestions: [CardMatch] = []

    /// Loading indicator for autocomplete
    var isLoadingAutocomplete: Bool = false

    // MARK: - Computed Properties

    /// Check if lookup button should be enabled
    var canLookupPrice: Bool {
        !cardName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Parse card number from "25/102" or "25" format for API query
    var parsedCardNumber: String? {
        let trimmed = cardNumber.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // If format is "25/102", extract "25"
        if let slashIndex = trimmed.firstIndex(of: "/") {
            return String(trimmed[..<slashIndex]).trimmingCharacters(in: .whitespaces)
        }

        // Otherwise return as-is (e.g., "25")
        return trimmed
    }

    // MARK: - Initialization

    init() {
        // Load recent searches from UserDefaults
        if let saved = UserDefaults.standard.array(forKey: "recentCardSearches") as? [String] {
            self.recentSearches = saved
        }
    }

    // MARK: - Methods

    /// Reset all state
    func reset() {
        cardName = ""
        cardNumber = ""
        tcgPlayerPrices = nil
        ebayLastSold = nil
        isLoading = false
        errorMessage = nil
        selectedMatch = nil
        availableMatches = []
    }

    /// Add to recent searches
    func addToRecentSearches(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Remove if already exists
        recentSearches.removeAll { $0 == trimmed }

        // Add to front
        recentSearches.insert(trimmed, at: 0)

        // Limit to 5
        if recentSearches.count > 5 {
            recentSearches = Array(recentSearches.prefix(5))
        }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Clear autocomplete suggestions
    func clearAutocomplete() {
        autocompleteSuggestions = []
        isLoadingAutocomplete = false
    }
}
