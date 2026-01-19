import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Legacy ScannedCard (for capture session)

/// Represents a card that has been scanned during a capture session
struct LegacyScannedCard: Identifiable, Sendable {
    let id: UUID
    let image: UIImage
    let timestamp: Date
    var cardName: String
    var cardNumber: String
    var setName: String
    var game: CardGame
    var marketValue: Double
    var confidence: Double // 0.0 to 1.0 for AI confidence

    init(
        id: UUID = UUID(),
        image: UIImage,
        timestamp: Date = Date(),
        cardName: String = "Unknown Card",
        cardNumber: String = "",
        setName: String = "",
        game: CardGame = .pokemon,
        marketValue: Double = 0.0,
        confidence: Double = 0.0
    ) {
        self.id = id
        self.image = image
        self.timestamp = timestamp
        self.cardName = cardName
        self.cardNumber = cardNumber
        self.setName = setName
        self.game = game
        self.marketValue = marketValue
        self.confidence = confidence
    }
}

/// Manages a card scanning session with multiple cards
@Observable
@MainActor
final class ScanSession {
    var scannedCards: [LegacyScannedCard] = []
    var isProcessing: Bool = false

    var totalValue: Double {
        scannedCards.reduce(0) { $0 + $1.marketValue }
    }

    var cardCount: Int {
        scannedCards.count
    }

    func addCard(_ card: LegacyScannedCard) {
        scannedCards.append(card)
    }

    func removeCard(_ card: LegacyScannedCard) {
        scannedCards.removeAll { $0.id == card.id }
    }

    func updateCard(_ card: LegacyScannedCard) {
        if let index = scannedCards.firstIndex(where: { $0.id == card.id }) {
            scannedCards[index] = card
        }
    }

    func clear() {
        scannedCards.removeAll()
    }
}

// MARK: - New ScannedCard Model (for seamless scan flow)

/// Represents a scanned card with all data needed for display and pricing
/// Used for the seamless scan flow and Rare Candy-style detail page
@Observable
@MainActor
public final class ScannedCard: Identifiable {
    public let id: UUID
    public let cardID: String               // PokemonTCG.io card ID
    public let name: String
    public let setName: String
    public let setID: String
    public let cardNumber: String
    public let imageURL: URL?
    public let rarity: String?
    public let scannedAt: Date

    // TCGPlayer integration
    public var tcgplayerId: String?

    // Pricing data (populated async after scan)
    public var marketPrice: Double?
    public var conditionPrices: ConditionPrices?
    public var priceHistory: [PricePoint]?
    public var priceChange7d: Double?
    public var priceChange30d: Double?

    // State
    public var isLoadingPrice: Bool = false
    public var pricingError: String?

    // MARK: - Computed Properties

    /// Primary display price (NM or market price)
    public var displayPrice: Double? {
        conditionPrices?.nearMint ?? marketPrice
    }

    /// Formatted price for display
    public var formattedPrice: String {
        if isLoadingPrice {
            return "..."
        }
        guard let price = displayPrice else {
            return "--"
        }
        return price.formatted(.currency(code: "USD"))
    }

    /// Time since scan for display
    public var timeAgo: String {
        let interval = Date().timeIntervalSince(scannedAt)
        guard interval > 0 else { return "Just now" }

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    /// Price trend based on 7-day change
    public var priceTrend: PriceTrend {
        guard let change = priceChange7d else { return .stable }
        if change > 2.0 { return .rising }
        if change < -2.0 { return .falling }
        return .stable
    }

    /// TCGPlayer URL for buying
    public var tcgPlayerBuyURL: URL? {
        guard let tcgId = tcgplayerId else { return nil }
        return URL(string: "https://www.tcgplayer.com/product/\(tcgId)")
    }

    // MARK: - Initializers

    public init(
        id: UUID = UUID(),
        cardID: String,
        name: String,
        setName: String,
        setID: String,
        cardNumber: String,
        imageURL: URL?,
        rarity: String? = nil,
        tcgplayerId: String? = nil,
        scannedAt: Date = Date()
    ) {
        self.id = id
        self.cardID = cardID
        self.name = name
        self.setName = setName
        self.setID = setID
        self.cardNumber = cardNumber
        self.imageURL = imageURL
        self.rarity = rarity
        self.tcgplayerId = tcgplayerId
        self.scannedAt = scannedAt
    }

    /// Create from CardMatch (from search results)
    public convenience init(from match: CardMatch) {
        self.init(
            cardID: match.id,
            name: match.cardName,
            setName: match.setName,
            setID: match.setID,
            cardNumber: match.cardNumber,
            imageURL: match.imageURL
        )
    }
}

// MARK: - Equatable & Hashable (nonisolated for protocol conformance)

extension ScannedCard: Equatable {
    nonisolated public static func == (lhs: ScannedCard, rhs: ScannedCard) -> Bool {
        lhs.id == rhs.id
    }
}

extension ScannedCard: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ScannedCardsManager

/// Manages scanned cards for the current session
/// Features running total and async price fetching
@Observable
@MainActor
public final class ScannedCardsManager {
    public static let shared = ScannedCardsManager()

    private(set) public var cards: [ScannedCard] = []

    private let pokemonService = PokemonTCGService.shared
    private let justTCGService = JustTCGService.shared

    /// Running total of all scanned card prices (NM condition)
    public var totalValue: Double {
        cards.compactMap(\.displayPrice).reduce(0, +)
    }

    /// Formatted total price
    public var formattedTotal: String {
        totalValue.formatted(.currency(code: "USD"))
    }

    /// Number of scanned cards
    public var count: Int {
        cards.count
    }

    /// Whether there are any scanned cards
    public var hasCards: Bool {
        !cards.isEmpty
    }

    /// Number of cards with prices loaded
    public var cardsWithPrices: Int {
        cards.filter { $0.displayPrice != nil }.count
    }

    private init() {}

    // MARK: - Public Methods

    /// Add a scanned card and fetch its pricing
    public func addCard(_ card: ScannedCard) {
        cards.insert(card, at: 0)

        // Fetch pricing in background
        Task {
            await fetchPricing(for: card)
        }
    }

    /// Add card from CardMatch and fetch pricing
    @discardableResult
    public func addCard(from match: CardMatch) -> ScannedCard {
        let card = ScannedCard(from: match)
        addCard(card)
        return card
    }

    /// Remove a card by ID
    public func removeCard(id: UUID) {
        cards.removeAll { $0.id == id }
    }

    /// Remove card at index
    public func removeCard(at index: Int) {
        guard cards.indices.contains(index) else { return }
        cards.remove(at: index)
    }

    /// Clear all scanned cards
    public func clearAll() {
        cards.removeAll()
    }

    // MARK: - Pricing

    /// Fetch pricing for a scanned card
    /// First gets basic pricing from PokemonTCG.io, then tries JustTCG for detailed condition pricing
    public func fetchPricing(for card: ScannedCard) async {
        card.isLoadingPrice = true
        card.pricingError = nil

        do {
            // Step 1: Get basic pricing and TCGPlayer ID from PokemonTCG.io
            let (cardData, basicPricing) = try await pokemonService.getCardByID(card.cardID)
            card.marketPrice = basicPricing.marketPrice

            // Extract TCGPlayer ID if available
            if let tcgplayerURL = cardData.tcgplayer?.url {
                card.tcgplayerId = JustTCGService.extractTCGPlayerID(from: tcgplayerURL)
            }

            // Step 2: Try to get detailed condition pricing from JustTCG
            if let tcgId = card.tcgplayerId, justTCGService.isConfigured {
                do {
                    let justTCGCard = try await justTCGService.getCardPricing(
                        tcgplayerId: tcgId,
                        includePriceHistory: true
                    )

                    // Apply JustTCG pricing
                    let conditionPricesDict = justTCGCard.bestAvailableConditionPrices()
                    card.conditionPrices = ConditionPrices(from: conditionPricesDict)
                    card.priceHistory = justTCGCard.nearMintPriceHistory
                    card.priceChange7d = justTCGCard.priceChange7d
                    card.priceChange30d = justTCGCard.priceChange30d

                    // Update market price with JustTCG NM price if available
                    if let nmPrice = justTCGCard.price(for: .nearMint) {
                        card.marketPrice = nmPrice
                    }

                } catch {
                    // JustTCG failed, but we still have basic pricing - continue without detailed data
                    // This is not a critical error
                }
            }

            card.isLoadingPrice = false

        } catch {
            // Handle error gracefully
            card.pricingError = error.localizedDescription
            card.isLoadingPrice = false
        }
    }

    /// Refresh pricing for a specific card
    public func refreshPricing(for card: ScannedCard) async {
        await fetchPricing(for: card)
    }
}

// MARK: - Mock Data for Previews

#if DEBUG
extension ScannedCard {
    @MainActor
    static var mockCharizard: ScannedCard {
        let card = ScannedCard(
            cardID: "base1-4",
            name: "Charizard",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "4",
            imageURL: URL(string: "https://images.pokemontcg.io/base1/4_hires.png"),
            rarity: "Rare Holo"
        )
        card.marketPrice = 350.00
        card.conditionPrices = ConditionPrices(
            nearMint: 350.00,
            lightlyPlayed: 280.00,
            moderatelyPlayed: 200.00,
            heavilyPlayed: 150.00,
            damaged: 100.00
        )
        card.priceChange7d = 5.2
        card.priceChange30d = 12.8
        card.priceHistory = (0..<30).map { day in
            PricePoint(
                p: 320.0 + Double.random(in: -20...30),
                t: Int(Date().timeIntervalSince1970) - ((29 - day) * 86400)
            )
        }
        return card
    }

    @MainActor
    static var mockPikachu: ScannedCard {
        let card = ScannedCard(
            cardID: "base1-58",
            name: "Pikachu",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "58",
            imageURL: URL(string: "https://images.pokemontcg.io/base1/58_hires.png"),
            rarity: "Common"
        )
        card.marketPrice = 25.00
        card.conditionPrices = ConditionPrices(
            nearMint: 25.00,
            lightlyPlayed: 20.00,
            moderatelyPlayed: 15.00,
            heavilyPlayed: 10.00,
            damaged: 5.00
        )
        card.priceChange7d = -2.5
        return card
    }

    @MainActor
    static var mockLoading: ScannedCard {
        let card = ScannedCard(
            cardID: "sv1-1",
            name: "Sprigatito",
            setName: "Scarlet & Violet",
            setID: "sv1",
            cardNumber: "1",
            imageURL: nil
        )
        card.isLoadingPrice = true
        return card
    }
}
#endif
