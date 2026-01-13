import SwiftData
import Foundation
import OSLog

/// Main pricing service that orchestrates three-tier caching:
/// 1. Memory cache (NSCache) - fastest
/// 2. SwiftData (PriceCacheRepository) - persistent
/// 3. API (PokemonTCGService) - network
@MainActor
public final class PricingService {
    private let repository: PriceCacheRepository
    private let pokemonAPI: PokemonTCGService
    private let memoryCache = NSCache<NSString, CachedPrice>()
    private let logger = Logger(subsystem: "com.cardshowpro.app", category: "PricingService")

    // Configuration
    private let staleTTL: TimeInterval = 86400 // 24 hours

    public init(modelContext: ModelContext) {
        self.repository = PriceCacheRepository(modelContext: modelContext)
        self.pokemonAPI = .shared

        // Configure memory cache limits
        memoryCache.countLimit = 200 // Store up to 200 cards in memory
        memoryCache.totalCostLimit = 10 * 1024 * 1024 // ~10MB memory limit
    }

    // MARK: - Public API

    /// Get price for a card, checking all cache tiers
    /// - Parameter cardID: Unique card identifier (e.g., "base1-4")
    /// - Returns: CachedPrice if found in any tier, nil if not cached
    public func getPrice(cardID: String, allowStale: Bool = false) throws -> CachedPrice? {
        // Tier 1: Check memory cache
        if let cached = memoryCache.object(forKey: cardID as NSString) {
            logger.debug("Memory cache hit for card: \(cardID)")

            // Return if fresh enough
            if allowStale || !cached.isStale {
                return cached
            }

            logger.debug("Memory cached price is stale for card: \(cardID)")
        }

        // Tier 2: Check SwiftData
        if let cached = try repository.getPrice(cardID: cardID) {
            logger.debug("SwiftData cache hit for card: \(cardID)")

            // Store in memory for faster future access
            memoryCache.setObject(cached, forKey: cardID as NSString)

            if allowStale || !cached.isStale {
                return cached
            }

            logger.debug("SwiftData cached price is stale for card: \(cardID)")
        }

        // Not found in any cache
        logger.debug("Cache miss for card: \(cardID)")
        return nil
    }

    /// Fetch price from API and update all cache tiers
    /// - Parameter cardID: Unique card identifier
    /// - Returns: Freshly fetched CachedPrice
    public func fetchPrice(cardID: String) async throws -> CachedPrice {
        logger.info("Fetching price from API for card: \(cardID)")

        // Fetch from PokemonTCG API
        let (cardData, _) = try await pokemonAPI.getCardByID(cardID)

        // Convert to CachedPrice model
        let cachedPrice = try convertToCachedPrice(cardData)

        // Save to persistent storage
        try repository.savePrice(cachedPrice)

        // Update memory cache
        memoryCache.setObject(cachedPrice, forKey: cardID as NSString)

        logger.info("Successfully cached price for card: \(cardID)")
        return cachedPrice
    }

    /// Get price with automatic fallback to API if stale/missing
    /// - Parameter cardID: Unique card identifier
    /// - Returns: CachedPrice (from cache or API)
    public func getPriceOrFetch(cardID: String) async throws -> CachedPrice {
        // Try cache first
        if let cached = try getPrice(cardID: cardID, allowStale: false) {
            return cached
        }

        // Cache miss or stale - fetch from API
        return try await fetchPrice(cardID: cardID)
    }

    /// Search for cards by name (cache-only)
    /// - Parameter query: Search query string
    /// - Returns: Array of cached prices matching query
    public func searchCachedPrices(query: String) throws -> [CachedPrice] {
        return try repository.searchPrices(query: query)
    }

    /// Search for cards by name (API)
    /// - Parameter query: Search query string
    /// - Returns: Array of card matches from API
    public func searchCardsFromAPI(name: String, number: String? = nil) async throws -> [CardMatch] {
        return try await pokemonAPI.searchCard(name: name, number: number)
    }

    /// Manually refresh a cached price
    /// - Parameter cardID: Unique card identifier
    /// - Returns: Updated CachedPrice
    public func refreshPrice(cardID: String) async throws -> CachedPrice {
        logger.info("Manual refresh requested for card: \(cardID)")
        return try await fetchPrice(cardID: cardID)
    }

    /// Get cache statistics
    public func getCacheStats() throws -> CacheStatistics {
        return try repository.getCacheStats()
    }

    /// Clear all cached prices (both memory and persistent)
    public func clearAllCaches() throws {
        memoryCache.removeAllObjects()
        try repository.clearAll()
        logger.info("Cleared all pricing caches")
    }

    /// Clear only memory cache (keeps SwiftData intact)
    public func clearMemoryCache() {
        memoryCache.removeAllObjects()
        logger.info("Cleared memory cache")
    }

    /// Remove stale prices older than specified days
    public func clearStalePrices(olderThanDays days: Int = 30) throws {
        try repository.deleteStalePrices(olderThanDays: days)
        logger.info("Cleared stale prices older than \(days) days")
    }

    // MARK: - Private Helpers

    /// Convert PokemonTCG API response to CachedPrice model
    private func convertToCachedPrice(_ cardData: PokemonTCGResponse.PokemonTCGCard) throws -> CachedPrice {
        let cachedPrice = CachedPrice(
            cardID: cardData.id,
            cardName: cardData.name,
            setName: cardData.set.name,
            setID: cardData.set.id,
            cardNumber: cardData.number,
            marketPrice: cardData.tcgplayer?.prices?.normal?.market ?? cardData.tcgplayer?.prices?.holofoil?.market,
            lowPrice: cardData.tcgplayer?.prices?.normal?.low ?? cardData.tcgplayer?.prices?.holofoil?.low,
            midPrice: cardData.tcgplayer?.prices?.normal?.mid ?? cardData.tcgplayer?.prices?.holofoil?.mid,
            highPrice: cardData.tcgplayer?.prices?.normal?.high ?? cardData.tcgplayer?.prices?.holofoil?.high,
            imageURLSmall: cardData.images.small,
            imageURLLarge: cardData.images.large,
            source: "PokemonTCG.io"
        )

        // Store variant pricing as JSON if available
        if let tcgplayer = cardData.tcgplayer?.prices {
            let variantPricing = VariantPricing(
                normal: tcgplayer.normal.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market, directLow: $0.directLow) },
                holofoil: tcgplayer.holofoil.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market, directLow: $0.directLow) },
                reverseHolofoil: tcgplayer.reverseHolofoil.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market, directLow: $0.directLow) },
                firstEdition: tcgplayer.firstEditionHolofoil.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market, directLow: $0.directLow) },
                unlimited: tcgplayer.unlimitedHolofoil.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market, directLow: $0.directLow) }
            )

            let encoder = JSONEncoder()
            cachedPrice.variantPricesJSON = try encoder.encode(variantPricing)
        }

        return cachedPrice
    }
}

// MARK: - Cache Strategy Info

/// Helper struct for cache strategy debugging
public struct CacheStrategy: Sendable {
    public enum Tier: String, Sendable {
        case memory = "Memory (NSCache)"
        case swiftData = "SwiftData (Persistent)"
        case api = "API (Network)"
    }

    public let tier: Tier
    public let latencyMS: Int

    public init(tier: Tier, latencyMS: Int) {
        self.tier = tier
        self.latencyMS = latencyMS
    }
}
