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

/// Repository for caching card prices using in-memory + SwiftData persistence
@MainActor
final class PriceCacheRepository {
    private var cache: [String: CachedPrice] = [:]
    private var accessOrder: [String] = []
    private let maxCacheSize = 5000
    private let modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    /// Pre-load SwiftData entries into in-memory cache on startup
    func preloadFromPersistence() {
        guard let modelContext else { return }
        do {
            let descriptor = FetchDescriptor<PriceCacheEntry>(
                sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
            )
            let entries = try modelContext.fetch(descriptor)
            for entry in entries.prefix(maxCacheSize) {
                let cached = CachedPrice(
                    cardID: entry.cardId,
                    cardName: entry.cardName,
                    setName: entry.setName ?? "",
                    setID: "",
                    cardNumber: "",
                    marketPrice: entry.marketPrice,
                    lowPrice: entry.lowPrice,
                    midPrice: entry.midPrice,
                    highPrice: entry.highPrice
                )
                cached.tcgplayerId = entry.tcgPlayerId
                cache[entry.cardId] = cached
                accessOrder.append(entry.cardId)
            }
        } catch {
            #if DEBUG
            print("PriceCacheRepository: Failed to preload from SwiftData: \(error)")
            #endif
        }
    }

    /// Get cached price for a card (checks in-memory first, then SwiftData)
    func getPrice(cardID: String) throws -> CachedPrice? {
        // Check in-memory cache first
        if let cached = cache[cardID] {
            trackAccess(cardID)
            return cached
        }

        // Fall back to SwiftData
        guard let modelContext else { return nil }
        let searchID = cardID
        var descriptor = FetchDescriptor<PriceCacheEntry>(
            predicate: #Predicate<PriceCacheEntry> { entry in
                entry.cardId == searchID
            }
        )
        descriptor.fetchLimit = 1
        guard let entry = try modelContext.fetch(descriptor).first else { return nil }

        // Hydrate into in-memory cache
        let cached = CachedPrice(
            cardID: entry.cardId,
            cardName: entry.cardName,
            setName: entry.setName ?? "",
            setID: "",
            cardNumber: "",
            marketPrice: entry.marketPrice,
            lowPrice: entry.lowPrice,
            midPrice: entry.midPrice,
            highPrice: entry.highPrice
        )
        cached.tcgplayerId = entry.tcgPlayerId
        cache[cardID] = cached
        trackAccess(cardID)
        return cached
    }

    /// Save price to both in-memory cache and SwiftData
    func savePrice(_ price: CachedPrice) throws {
        // Write to in-memory cache
        cache[price.cardID] = price
        trackAccess(price.cardID)
        evictIfNeeded()

        // Write to SwiftData
        guard let modelContext else { return }
        let searchID = price.cardID
        var descriptor = FetchDescriptor<PriceCacheEntry>(
            predicate: #Predicate<PriceCacheEntry> { entry in
                entry.cardId == searchID
            }
        )
        descriptor.fetchLimit = 1

        let entry: PriceCacheEntry
        if let existing = try modelContext.fetch(descriptor).first {
            entry = existing
        } else {
            entry = PriceCacheEntry(cardId: price.cardID, cardName: price.cardName)
            modelContext.insert(entry)
        }

        entry.cardName = price.cardName
        entry.setName = price.setName
        entry.lowPrice = price.lowPrice
        entry.midPrice = price.midPrice
        entry.highPrice = price.highPrice
        entry.marketPrice = price.marketPrice
        entry.tcgPlayerId = price.tcgplayerId
        entry.lastUpdated = Date()
        entry.source = "tcgplayer"

        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("PriceCacheRepository: Failed to persist to SwiftData: \(error)")
            #endif
        }
    }

    /// Clear all cached prices (both in-memory and SwiftData)
    func clearCache() {
        cache.removeAll()
        accessOrder.removeAll()

        guard let modelContext else { return }
        do {
            try modelContext.delete(model: PriceCacheEntry.self)
            try modelContext.save()
        } catch {
            #if DEBUG
            print("PriceCacheRepository: Failed to clear SwiftData cache: \(error)")
            #endif
        }
    }

    /// Legacy alias for backward compatibility
    func clearAll() {
        clearCache()
    }

    /// Number of entries in the in-memory cache
    var cacheEntryCount: Int {
        cache.count
    }

    /// Total number of entries persisted in SwiftData
    func persistedEntryCount() -> Int {
        guard let modelContext else { return 0 }
        do {
            let descriptor = FetchDescriptor<PriceCacheEntry>()
            return try modelContext.fetchCount(descriptor)
        } catch {
            return 0
        }
    }

    // MARK: - LRU Eviction

    private func trackAccess(_ cardID: String) {
        accessOrder.removeAll { $0 == cardID }
        accessOrder.append(cardID)
    }

    private func evictIfNeeded() {
        while cache.count > maxCacheSize, let oldest = accessOrder.first {
            cache.removeValue(forKey: oldest)
            accessOrder.removeFirst()
        }
    }
}
