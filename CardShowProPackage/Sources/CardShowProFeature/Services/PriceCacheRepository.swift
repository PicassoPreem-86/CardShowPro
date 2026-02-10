import Foundation
import SwiftData

/// Cached price data for a card (in-memory cache with TTL)
final class CachedPrice: Sendable {
    let cardID: String
    let cardName: String
    let setName: String
    let setID: String
    let cardNumber: String
    let marketPrice: Double?
    let lowPrice: Double?
    let midPrice: Double?
    let highPrice: Double?
    let imageURLSmall: String?
    let imageURLLarge: String?
    let cachedAt: Date

    // Mutable properties stored via nonisolated(unsafe) for Sendable
    nonisolated(unsafe) var variantPricesJSON: Data?
    nonisolated(unsafe) var conditionPrices: ConditionPrices?
    nonisolated(unsafe) var priceChange7d: Double?
    nonisolated(unsafe) var priceChange30d: Double?
    nonisolated(unsafe) var priceHistory: [PricePoint]?
    nonisolated(unsafe) var tcgplayerId: String?
    nonisolated(unsafe) var justTCGLastUpdated: Date?

    init(
        cardID: String,
        cardName: String,
        setName: String,
        setID: String,
        cardNumber: String,
        marketPrice: Double? = nil,
        lowPrice: Double? = nil,
        midPrice: Double? = nil,
        highPrice: Double? = nil,
        imageURLSmall: String? = nil,
        imageURLLarge: String? = nil
    ) {
        self.cardID = cardID
        self.cardName = cardName
        self.setName = setName
        self.setID = setID
        self.cardNumber = cardNumber
        self.marketPrice = marketPrice
        self.lowPrice = lowPrice
        self.midPrice = midPrice
        self.highPrice = highPrice
        self.imageURLSmall = imageURLSmall
        self.imageURLLarge = imageURLLarge
        self.cachedAt = Date()
    }

    /// Age of cache entry in hours
    var ageInHours: Double {
        Date().timeIntervalSince(cachedAt) / 3600
    }

    /// Whether cache is still fresh (< 24 hours)
    var isFresh: Bool {
        ageInHours < 24
    }

    /// Whether cache entry is stale (> 24 hours)
    var isStale: Bool {
        !isFresh
    }

    /// Set condition prices from JustTCG data
    func setConditionPrices(_ prices: ConditionPrices) {
        self.conditionPrices = prices
    }

    /// Set price history data
    func setPriceHistory(_ history: [PricePoint]) {
        self.priceHistory = history
    }
}

/// Repository for caching card prices using in-memory storage
@MainActor
final class PriceCacheRepository {
    private var cache: [String: CachedPrice] = [:]
    private let modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    /// Get cached price for a card
    func getPrice(cardID: String) throws -> CachedPrice? {
        cache[cardID]
    }

    /// Save price to cache
    func savePrice(_ price: CachedPrice) throws {
        cache[price.cardID] = price
    }

    /// Clear all cached prices
    func clearAll() {
        cache.removeAll()
    }
}
