import Foundation
import SwiftUI

/// Manages state for the manual card entry flow
@MainActor
@Observable
final class ScanFlowState {
    // MARK: - Flow Steps
    enum Step: Equatable {
        case search
        case setSelection(pokemonName: String)
        case cardEntry(pokemonName: String, setName: String, setID: String)
        case success(card: InventoryCard)
    }

    var currentStep: Step = .search
    var isLoading = false
    var errorMessage: String?

    // MARK: - Search State (Step 1)
    var searchQuery = ""
    var searchResults: [PokemonSearchResult] = []
    var recentSearches: [String] {
        get { UserDefaults.standard.stringArray(forKey: "recentPokemonSearches") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "recentPokemonSearches") }
    }

    // MARK: - Set Selection State (Step 2)
    var availableSets: [CardSet] = []
    var selectedPokemon: String = ""

    // MARK: - Card Entry State (Step 3)
    var cardNumber = ""
    var selectedVariant: CardVariant = .standard
    var selectedCondition: CardCondition = .nearMint
    var fetchedPrice: Double?
    var cardImageURL: URL?
    var selectedSet: CardSet?

    // MARK: - Actions
    func resetFlow() {
        currentStep = .search
        searchQuery = ""
        searchResults = []
        cardNumber = ""
        selectedVariant = .standard
        selectedCondition = .nearMint
        fetchedPrice = nil
        cardImageURL = nil
        selectedSet = nil
        errorMessage = nil
    }

    func addToRecentSearches(_ pokemon: String) {
        var recent = recentSearches
        recent.removeAll { $0 == pokemon }
        recent.insert(pokemon, at: 0)
        recentSearches = Array(recent.prefix(5)) // Keep last 5
    }
}

/// Represents a Pokemon card set
struct CardSet: Identifiable, Sendable {
    let id: String
    let name: String
    let releaseDate: String
    let logoURL: URL?
    let total: Int

    init(id: String, name: String, releaseDate: String, logoURL: URL? = nil, total: Int = 0) {
        self.id = id
        self.name = name
        self.releaseDate = releaseDate
        self.logoURL = logoURL
        self.total = total
    }
}
