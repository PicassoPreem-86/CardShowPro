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

    /// Recent search queries (limit to 10) - persisted to UserDefaults
    var recentSearches: [RecentSearch] = []

    /// Autocomplete suggestions
    var autocompleteSuggestions: [CardMatch] = []

    /// Loading indicator for autocomplete
    var isLoadingAutocomplete: Bool = false

    // MARK: - Cache State

    /// Whether the current result is from cache
    var isFromCache: Bool = false

    /// Age of cached data in hours (if from cache)
    var cacheAgeHours: Int?

    // MARK: - Computed Properties

    /// Cache age display string
    var cacheAge: String {
        guard let hours = cacheAgeHours else { return "" }
        if hours < 1 {
            return "Just updated"
        } else if hours == 1 {
            return "1 hour ago"
        } else if hours < 24 {
            return "\(hours) hours ago"
        } else {
            let days = hours / 24
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
    }

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
        loadRecentSearches()
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
        isFromCache = false
        cacheAgeHours = nil
    }

    /// Add to recent searches
    func addToRecentSearches(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Remove if already exists (case-insensitive)
        recentSearches.removeAll { $0.cardName.lowercased() == trimmed.lowercased() }

        // Add to front
        let search = RecentSearch(cardName: trimmed, timestamp: Date())
        recentSearches.insert(search, at: 0)

        // Limit to 10
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }

        // Persist to UserDefaults
        saveRecentSearches()
    }

    /// Clear all recent searches
    func clearRecentSearches() {
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: "recentCardSearches")
    }

    /// Save recent searches to UserDefaults
    private func saveRecentSearches() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(encoded, forKey: "recentCardSearches")
        }
    }

    /// Load recent searches from UserDefaults
    func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: "recentCardSearches"),
              let decoded = try? JSONDecoder().decode([RecentSearch].self, from: data) else {
            return
        }
        recentSearches = decoded
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
