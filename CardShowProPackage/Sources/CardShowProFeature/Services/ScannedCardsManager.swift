import Foundation
import SwiftData
import SwiftUI

/// Manages scanned cards for the current session
/// Provides running totals and persistence of scan results
@MainActor
@Observable
final class ScannedCardsManager {
    static let shared = ScannedCardsManager()

    private(set) var cards: [ScannedCard] = []
    private var modelContext: ModelContext?
    private let pokemonService = PokemonTCGService.shared

    private init() {}

    /// Configure with SwiftData model context for persistence
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Add a card from a CardMatch (after scan + API lookup)
    func addCard(from match: CardMatch) {
        let card = ScannedCard(
            cardID: match.id,
            name: match.cardName,
            setName: match.setName,
            setID: match.setID,
            cardNumber: match.cardNumber,
            imageURL: match.imageURL
        )
        cards.insert(card, at: 0)

        // Fetch pricing in background
        Task {
            await fetchPricing(for: card, cardID: match.id)
        }
    }

    /// Add a pre-built ScannedCard
    func addCard(_ card: ScannedCard) {
        cards.insert(card, at: 0)
    }

    /// Remove a card by ID
    func removeCard(_ card: ScannedCard) {
        cards.removeAll { $0.id == card.id }
    }

    /// Total market value of all scanned cards
    var totalValue: Double {
        cards.compactMap { $0.marketPrice }.reduce(0, +)
    }

    /// Number of scanned cards
    var cardCount: Int {
        cards.count
    }

    /// Whether any cards have been scanned
    var hasCards: Bool {
        !cards.isEmpty
    }

    /// Number of cards (alias for views)
    var count: Int {
        cards.count
    }

    /// Number of cards that have pricing loaded
    var cardsWithPrices: Int {
        cards.filter { $0.marketPrice != nil }.count
    }

    /// Formatted total value string
    var formattedTotal: String {
        "$\(String(format: "%.2f", totalValue))"
    }

    /// Clear all scanned cards
    func clearAll() {
        cards.removeAll()
    }

    /// Fetch pricing for a scanned card, populating all variant prices
    private func fetchPricing(for card: ScannedCard, cardID: String) async {
        card.isLoadingPrice = true
        do {
            let (detailed, tcgplayerID) = try await pokemonService.getDetailedPricing(cardID: cardID)

            // Populate all available variant pricing for display
            var variantPrices: [ScannedCard.VariantPricingInfo] = []
            if let normal = detailed.normal {
                variantPrices.append(.init(name: "Normal", market: normal.market, low: normal.low, mid: normal.mid, high: normal.high))
            }
            if let holo = detailed.holofoil {
                variantPrices.append(.init(name: "Holofoil", market: holo.market, low: holo.low, mid: holo.mid, high: holo.high))
            }
            if let reverse = detailed.reverseHolofoil {
                variantPrices.append(.init(name: "Reverse Holo", market: reverse.market, low: reverse.low, mid: reverse.mid, high: reverse.high))
            }
            if let first = detailed.firstEdition {
                variantPrices.append(.init(name: "1st Edition", market: first.market, low: first.low, mid: first.mid, high: first.high))
            }
            if let unlimited = detailed.unlimited {
                variantPrices.append(.init(name: "Unlimited", market: unlimited.market, low: unlimited.low, mid: unlimited.mid, high: unlimited.high))
            }
            card.variantPricing = variantPrices

            // Use the best available price as default display
            let bestVariant = detailed.normal ?? detailed.holofoil ?? detailed.reverseHolofoil ?? detailed.firstEdition ?? detailed.unlimited
            card.marketPrice = bestVariant?.market
            card.displayPrice = bestVariant?.market

            if let tcgplayerID {
                card.tcgPlayerBuyURL = URL(string: "https://www.tcgplayer.com/product/\(tcgplayerID)")
            }
        } catch {
            card.pricingError = error.localizedDescription
        }
        card.isLoadingPrice = false
    }
}
