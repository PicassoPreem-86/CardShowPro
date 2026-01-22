import Foundation
import SwiftUI
import SwiftData
import OSLog
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

    // MARK: - Seller Buy Price Calculator

    /// Manual buy price entered by seller when evaluating purchase
    public var buyPrice: Double?

    /// Profit potential: market value - buy price
    public var profitPotential: Double? {
        guard let buy = buyPrice, let market = displayPrice else { return nil }
        return market - buy
    }

    /// Return on Investment: (profit / buy price) * 100
    public var roi: Double? {
        guard let buy = buyPrice, buy > 0, let profit = profitPotential else { return nil }
        return (profit / buy) * 100
    }

    /// ROI quality indicator for color coding
    public var roiQuality: ROIQuality {
        guard let roiValue = roi else { return .unknown }
        if roiValue >= 25 { return .good }
        if roiValue >= 15 { return .fair }
        return .poor
    }

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
/// Features running total and async price fetching with 3-tier caching
@Observable
@MainActor
public final class ScannedCardsManager {
    public static let shared = ScannedCardsManager()

    private(set) public var cards: [ScannedCard] = []

    private let pokemonService = PokemonTCGService.shared
    private let justTCGService = JustTCGService.shared
    private var pricingService: PricingService?
    private let logger = Logger(subsystem: "com.cardshowpro.app", category: "ScannedCardsManager")

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

    // MARK: - Configuration

    /// Configure the pricing service with a ModelContext for cache access
    /// Call this early (e.g., in app startup or view onAppear) to enable caching
    public func configure(modelContext: ModelContext) {
        if pricingService == nil {
            pricingService = PricingService(modelContext: modelContext)
            logger.info("PricingService configured - cache enabled")
        }
    }

    // MARK: - Public Methods

    /// Add a scanned card and fetch its pricing
    public func addCard(_ card: ScannedCard) {
        cards.insert(card, at: 0)

        // Fetch pricing in background
        Task {
            await fetchPricing(for: card)
        }
    }

    /// Add card from CardMatch
    /// If CardMatch includes pricing (from searchCard), uses it immediately
    /// Only fetches additional pricing if not available
    @discardableResult
    public func addCard(from match: CardMatch) -> ScannedCard {
        let card = ScannedCard(from: match)

        // If CardMatch already has pricing, use it (skip redundant API call)
        if let price = match.marketPrice {
            card.marketPrice = price
            card.isLoadingPrice = false

            // Extract TCGPlayer ID if available
            if let tcgURL = match.tcgplayerURL {
                card.tcgplayerId = JustTCGService.extractTCGPlayerID(from: tcgURL)
            }

            // Insert card immediately with pricing
            cards.insert(card, at: 0)
            logger.info("Added card with inline pricing: \(card.cardID) @ \(price)")

            // Fetch JustTCG condition prices in background (non-blocking)
            Task {
                await fetchConditionPricing(for: card)
            }
            return card
        }

        // No inline pricing - use standard flow with API fetch
        addCard(card)
        return card
    }

    /// Add card with pre-loaded pricing (FAST PATH - used when getCard() returns pricing directly)
    /// This skips the getCardByID() call since pricing is already available
    /// Only fetches JustTCG condition prices in background (non-blocking)
    func addCardWithPricing(_ card: ScannedCard, pricing: CardPricing) {
        // Apply pricing directly
        card.marketPrice = pricing.marketPrice
        card.isLoadingPrice = false

        // Insert card at top of list
        cards.insert(card, at: 0)

        logger.info("Added card via fast path: \(card.cardID) with market price \(pricing.marketPrice ?? 0)")

        // Fetch JustTCG condition prices in background (non-blocking)
        // This enhances pricing data but doesn't block the UI
        Task {
            await fetchConditionPricing(for: card)
        }
    }

    /// Fetch detailed condition pricing from JustTCG in background
    /// This is called after the card is added to enhance pricing data
    /// Non-fatal: Card still shows basic pricing if this fails
    func fetchConditionPricing(for card: ScannedCard) async {
        guard let tcgId = card.tcgplayerId, self.justTCGService.isConfigured else {
            logger.debug("Skipping JustTCG fetch: tcgplayerId=\(card.tcgplayerId ?? "nil"), configured=\(self.justTCGService.isConfigured)")
            return
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Fetching JustTCG condition pricing for TCGPlayer ID: \(tcgId)")

        do {
            let justTCGCard = try await self.justTCGService.getCardPricing(
                tcgplayerId: tcgId,
                includePriceHistory: true
            )

            // Apply JustTCG pricing
            let conditionPricesDict = justTCGCard.bestAvailableConditionPrices()
            card.conditionPrices = ConditionPrices(from: conditionPricesDict)
            card.priceHistory = justTCGCard.nearMintPriceHistory
            card.priceChange7d = justTCGCard.priceChange7d
            card.priceChange30d = justTCGCard.priceChange30d

            // Update market price with JustTCG NM price if available (more accurate)
            if let nmPrice = justTCGCard.price(for: .nearMint) {
                card.marketPrice = nmPrice
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("JustTCG condition pricing fetched in \(String(format: "%.2f", elapsed))s")
            print("📊 DEBUG [JustTCG]: Condition pricing loaded in \(String(format: "%.2f", elapsed))s for \(card.cardID)")

            // Cache the enhanced pricing data
            if let pricingService = pricingService {
                do {
                    // Re-fetch through pricing service to update cache
                    _ = try await pricingService.fetchPrice(cardID: card.cardID)
                    logger.info("Cached enhanced pricing for \(card.cardID)")
                } catch {
                    // Cache update failure is non-fatal
                    logger.warning("Failed to cache enhanced pricing: \(error.localizedDescription)")
                }
            }

        } catch {
            // JustTCG failure is non-fatal - card still has basic pricing from getCard()
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            logger.warning("JustTCG fetch failed in \(String(format: "%.2f", elapsed))s: \(error.localizedDescription)")
            print("⚠️ DEBUG [JustTCG]: Condition pricing failed (non-fatal) - \(error.localizedDescription)")
        }
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
    /// Checks 3-tier cache first (memory → SwiftData → API)
    /// Then tries JustTCG for detailed condition pricing
    public func fetchPricing(for card: ScannedCard) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        card.isLoadingPrice = true
        card.pricingError = nil

        do {
            // OPTIMIZATION: Check cache FIRST before any API calls
            if let pricingService = pricingService {
                do {
                    if let cached = try pricingService.getPrice(cardID: card.cardID, allowStale: false) {
                        let cacheTime = CFAbsoluteTimeGetCurrent() - startTime
                        logger.info("🚀 CACHE HIT for \(card.cardID) in \(String(format: "%.3f", cacheTime))s")
                        print("🚀 DEBUG [Cache]: HIT for \(card.cardID) in \(String(format: "%.3f", cacheTime))s - skipping API call!")

                        // Apply cached pricing directly
                        card.marketPrice = cached.marketPrice
                        card.tcgplayerId = cached.tcgplayerId
                        card.conditionPrices = cached.conditionPrices
                        card.priceHistory = cached.priceHistory
                        card.priceChange7d = cached.priceChange7d
                        card.priceChange30d = cached.priceChange30d
                        card.isLoadingPrice = false
                        return // Early exit - no API calls needed!
                    } else {
                        logger.debug("Cache miss for \(card.cardID) - fetching from API")
                        print("📡 DEBUG [Cache]: MISS for \(card.cardID) - will fetch from API")
                    }
                } catch {
                    // Cache error is non-fatal, continue with API
                    logger.warning("Cache lookup failed: \(error.localizedDescription)")
                }
            } else {
                print("⚠️ DEBUG [Cache]: PricingService not configured - no cache available")
            }

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

            // Step 3: Save to cache for future lookups (if cache is configured)
            if let pricingService = pricingService {
                do {
                    // Convert to CachedPrice and save
                    let cachedPrice = try await pricingService.fetchPrice(cardID: card.cardID)
                    logger.info("Saved pricing to cache for \(card.cardID)")

                    // Update card with any additional cached data
                    card.tcgplayerId = card.tcgplayerId ?? cachedPrice.tcgplayerId
                } catch {
                    // Caching failure is non-fatal
                    logger.warning("Failed to cache pricing: \(error.localizedDescription)")
                }
            }

            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            print("📡 DEBUG [API]: Pricing fetched in \(String(format: "%.2f", totalTime))s for \(card.cardID)")
            card.isLoadingPrice = false

        } catch {
            // Handle error gracefully
            card.pricingError = error.localizedDescription
            card.isLoadingPrice = false
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            print("❌ DEBUG [API]: Pricing FAILED in \(String(format: "%.2f", totalTime))s - \(error.localizedDescription)")
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

// MARK: - ROI Quality

/// Return on Investment quality indicator for seller decision making
public enum ROIQuality: Sendable {
    case good       // >= 25%
    case fair       // 15-25%
    case poor       // < 15%
    case unknown    // No ROI calculated

    /// Color for ROI display
    public var color: Color {
        switch self {
        case .good: return .green
        case .fair: return .yellow
        case .poor: return .red
        case .unknown: return .gray
        }
    }

    /// Display text
    public var displayText: String {
        switch self {
        case .good: return "Good Deal"
        case .fair: return "Fair Deal"
        case .poor: return "Low Margin"
        case .unknown: return "Unknown"
        }
    }
}
