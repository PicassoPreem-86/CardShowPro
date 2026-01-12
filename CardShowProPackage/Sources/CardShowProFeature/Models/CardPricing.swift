import Foundation

/// Card pricing information from various sources
struct CardPricing: Codable, Sendable {
    let marketPrice: Double?
    let lowPrice: Double?
    let midPrice: Double?
    let highPrice: Double?
    let directLowPrice: Double?
    let source: PricingSource
    let lastUpdated: Date

    /// Best estimate for card value
    var estimatedValue: Double {
        marketPrice ?? midPrice ?? ((lowPrice ?? 0) + (highPrice ?? 0)) / 2
    }

    enum PricingSource: String, Codable, Sendable {
        case tcgPlayer = "TCGPlayer"
        case cardmarket = "Cardmarket"
        case pokemonTCG = "PokemonTCG"
        case unknown = "Unknown"
    }
}

/// PokemonTCG.io API response format (multiple cards)
struct PokemonTCGResponse: Codable {
    let data: [PokemonTCGCard]

    struct PokemonTCGCard: Codable {
        let id: String
        let name: String
        let set: PokemonTCGSet
        let number: String
        let tcgplayer: TCGPlayerPricing?
        let cardmarket: CardmarketPricing?
        let images: CardImages

        struct PokemonTCGSet: Codable {
            let id: String
            let name: String
            let series: String
            let printedTotal: Int
        }

        struct TCGPlayerPricing: Codable {
            let prices: Prices?

            struct Prices: Codable {
                let holofoil: PricePoint?
                let reverseHolofoil: PricePoint?
                let normal: PricePoint?
                let unlimitedHolofoil: PricePoint?
                let firstEditionHolofoil: PricePoint?
            }

            struct PricePoint: Codable {
                let low: Double?
                let mid: Double?
                let high: Double?
                let market: Double?
                let directLow: Double?
            }
        }

        struct CardmarketPricing: Codable {
            let prices: Prices?

            struct Prices: Codable {
                let averageSellPrice: Double?
                let lowPrice: Double?
                let trendPrice: Double?
                let avg1: Double?
                let avg7: Double?
                let avg30: Double?
            }
        }

        struct CardImages: Codable {
            let small: String
            let large: String
        }
    }

    /// Convert to our CardPricing model (takes first available pricing)
    func toCardPricing() -> CardPricing? {
        guard let card = data.first else { return nil }

        // Try TCGPlayer pricing first
        if let tcgPlayer = card.tcgplayer?.prices,
           let pricing = tcgPlayer.holofoil ?? tcgPlayer.normal ?? tcgPlayer.reverseHolofoil {
            return CardPricing(
                marketPrice: pricing.market,
                lowPrice: pricing.low,
                midPrice: pricing.mid,
                highPrice: pricing.high,
                directLowPrice: pricing.directLow,
                source: .tcgPlayer,
                lastUpdated: Date()
            )
        }

        // Fall back to Cardmarket pricing
        if let cardmarket = card.cardmarket?.prices {
            return CardPricing(
                marketPrice: cardmarket.averageSellPrice,
                lowPrice: cardmarket.lowPrice,
                midPrice: cardmarket.trendPrice,
                highPrice: nil,
                directLowPrice: nil,
                source: .cardmarket,
                lastUpdated: Date()
            )
        }

        return nil
    }

    /// Get high-res card image URL
    var imageURL: String? {
        data.first?.images.large
    }
}

/// PokemonTCG.io API response format (single card by ID)
struct PokemonTCGSingleResponse: Codable {
    let data: PokemonTCGResponse.PokemonTCGCard
}

/// Detailed TCGPlayer pricing with all variants
struct DetailedTCGPlayerPricing: Codable, Sendable {
    let normal: PriceBreakdown?
    let holofoil: PriceBreakdown?
    let reverseHolofoil: PriceBreakdown?
    let firstEdition: PriceBreakdown?
    let unlimited: PriceBreakdown?

    struct PriceBreakdown: Codable, Sendable {
        let low: Double?
        let mid: Double?
        let high: Double?
        let market: Double?

        var displayPrice: String {
            if let market = market {
                return "$\(String(format: "%.2f", market))"
            } else if let mid = mid {
                return "$\(String(format: "%.2f", mid))"
            } else if let low = low, let high = high {
                return "$\(String(format: "%.2f", low))-$\(String(format: "%.2f", high))"
            }
            return "N/A"
        }
    }

    /// Check if any pricing is available
    var hasAnyPricing: Bool {
        normal != nil || holofoil != nil || reverseHolofoil != nil || firstEdition != nil || unlimited != nil
    }

    /// Get all available variants as array
    var availableVariants: [(name: String, pricing: PriceBreakdown)] {
        var variants: [(String, PriceBreakdown)] = []
        if let normal = normal {
            variants.append(("Normal", normal))
        }
        if let holofoil = holofoil {
            variants.append(("Holofoil", holofoil))
        }
        if let reverseHolofoil = reverseHolofoil {
            variants.append(("Reverse Holofoil", reverseHolofoil))
        }
        if let firstEdition = firstEdition {
            variants.append(("1st Edition", firstEdition))
        }
        if let unlimited = unlimited {
            variants.append(("Unlimited", unlimited))
        }
        return variants
    }
}

/// eBay pricing (placeholder for Phase 2)
struct EbayPricing: Codable, Sendable {
    let lastSoldPrice: Double
    let lastSoldDate: Date
    let seller: String?
    let condition: String?

    var displayPrice: String {
        "$\(String(format: "%.2f", lastSoldPrice))"
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: lastSoldDate)
    }
}

/// Pricing error
enum PricingError: LocalizedError {
    case cardNotFound
    case noPricingAvailable
    case apiError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .cardNotFound:
            return "Card not found in pricing database"
        case .noPricingAvailable:
            return "No pricing information available for this card"
        case .apiError(let message):
            return "Pricing API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .cardNotFound, .noPricingAvailable:
            return "Enter a price manually or check back later"
        case .apiError, .networkError:
            return "Check your connection and try again"
        }
    }
}
