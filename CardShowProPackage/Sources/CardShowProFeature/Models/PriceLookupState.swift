import Foundation

/// State model for the Card Price Lookup Tool
/// This tool allows users to look up card prices WITHOUT adding to inventory
@MainActor
@Observable
final class PriceLookupState: Sendable {
    // MARK: - Input Fields

    /// Pokemon card name (required)
    var cardName: String = ""

    /// Card number - first part (e.g., "25" from "25/102")
    var cardNumber: String = ""

    /// Total cards in set - second part (e.g., "102" from "25/102") - optional
    var totalCards: String = ""

    /// Card variant (e.g., "Holo", "Reverse Holo", "Full Art") - free text
    var variant: String = ""

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

    /// Recent search queries (limit to 5)
    var recentSearches: [String] = []

    // MARK: - Computed Properties

    /// Check if lookup button should be enabled
    var canLookupPrice: Bool {
        !cardName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Format card number for display (e.g., "25/102" or just "25")
    var formattedCardNumber: String {
        let number = cardNumber.trimmingCharacters(in: .whitespaces)
        let total = totalCards.trimmingCharacters(in: .whitespaces)

        if !number.isEmpty && !total.isEmpty {
            return "\(number)/\(total)"
        } else if !number.isEmpty {
            return number
        } else {
            return ""
        }
    }

    // MARK: - Methods

    /// Reset all state
    func reset() {
        cardName = ""
        cardNumber = ""
        totalCards = ""
        variant = ""
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
}
