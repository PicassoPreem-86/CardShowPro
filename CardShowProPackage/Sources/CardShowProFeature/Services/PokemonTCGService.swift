import Foundation
import UIKit

/// Service for searching Pokemon TCG cards via the PokemonTCG.io API
/// Provides card search, fuzzy matching, and detailed pricing retrieval
@MainActor
@Observable
final class PokemonTCGService {
    static let shared = PokemonTCGService()

    private let pricingService = PricingService.shared

    private init() {}

    // MARK: - Card Search

    /// Get a specific card by name, set ID, and card number
    func getCard(pokemonName: String, setID: String, cardNumber: String) async throws -> (card: PokemonTCGResponse.PokemonTCGCard, pricing: CardPricing) {
        let cards = try await pricingService.searchCards(name: pokemonName, setName: nil, number: cardNumber)
        guard let card = cards.first else {
            throw PricingError.cardNotFound
        }
        let pricing = CardPricing(
            marketPrice: card.tcgplayer?.prices?.normal?.market ?? card.tcgplayer?.prices?.holofoil?.market,
            lowPrice: card.tcgplayer?.prices?.normal?.low ?? card.tcgplayer?.prices?.holofoil?.low,
            midPrice: card.tcgplayer?.prices?.normal?.mid ?? card.tcgplayer?.prices?.holofoil?.mid,
            highPrice: card.tcgplayer?.prices?.normal?.high ?? card.tcgplayer?.prices?.holofoil?.high,
            directLowPrice: nil,
            source: .pokemonTCG,
            lastUpdated: Date()
        )
        return (card, pricing)
    }

    /// Search for cards with fuzzy name matching
    func searchCardFuzzy(name: String, number: String? = nil) async throws -> [CardMatch] {
        let cards = try await pricingService.searchCards(name: name, number: number)
        return cards.map { card in
            CardMatch(
                id: card.id,
                cardName: card.name,
                setName: card.set.name,
                setID: card.set.name,
                cardNumber: card.number,
                imageURL: URL(string: card.images.large)
            )
        }
    }

    /// Search for cards by exact name
    func searchCard(name: String, number: String? = nil) async throws -> [CardMatch] {
        try await searchCardFuzzy(name: name, number: number)
    }

    /// Get detailed pricing with variant breakdowns
    func getDetailedPricing(cardID: String) async throws -> (DetailedTCGPlayerPricing, String?) {
        let pricing = try await pricingService.fetchPricingByID(cardID)
        let detailed = DetailedTCGPlayerPricing(
            normal: pricing.marketPrice.map { DetailedTCGPlayerPricing.PriceBreakdown(low: pricing.lowPrice, mid: pricing.midPrice, high: pricing.highPrice, market: $0) },
            holofoil: nil,
            reverseHolofoil: nil,
            firstEdition: nil,
            unlimited: nil
        )
        return (detailed, nil)
    }
}

// MARK: - CardMatch

/// Represents a matched card from search results
struct CardMatch: Identifiable, Sendable {
    let id: String
    let cardName: String
    let setName: String
    let setID: String
    let cardNumber: String
    let imageURL: URL?
}

// MARK: - DetailedTCGPlayerPricing

/// Detailed pricing breakdown by variant type
struct DetailedTCGPlayerPricing: Sendable {
    let normal: PriceBreakdown?
    let holofoil: PriceBreakdown?
    let reverseHolofoil: PriceBreakdown?
    let firstEdition: PriceBreakdown?
    let unlimited: PriceBreakdown?

    struct PriceBreakdown: Sendable {
        let low: Double?
        let mid: Double?
        let high: Double?
        let market: Double?

        var displayPrice: String {
            if let market { return "$\(String(format: "%.2f", market))" }
            if let mid { return "$\(String(format: "%.2f", mid))" }
            return "N/A"
        }
    }

    var hasAnyPricing: Bool {
        normal != nil || holofoil != nil || reverseHolofoil != nil || firstEdition != nil || unlimited != nil
    }

    struct VariantInfo {
        let name: String
        let pricing: PriceBreakdown
    }

    /// Best available market price across all variants
    var bestAvailablePrice: Double? {
        let variant = normal ?? holofoil ?? reverseHolofoil ?? firstEdition ?? unlimited
        return variant?.market ?? variant?.mid
    }

    var availableVariants: [VariantInfo] {
        var variants: [VariantInfo] = []
        if let normal { variants.append(VariantInfo(name: "Normal", pricing: normal)) }
        if let holofoil { variants.append(VariantInfo(name: "Holofoil", pricing: holofoil)) }
        if let reverseHolofoil { variants.append(VariantInfo(name: "Reverse Holofoil", pricing: reverseHolofoil)) }
        if let firstEdition { variants.append(VariantInfo(name: "1st Edition", pricing: firstEdition)) }
        if let unlimited { variants.append(VariantInfo(name: "Unlimited", pricing: unlimited)) }
        return variants
    }
}
