import SwiftData
import Foundation
import OSLog

/// Repository for managing cached pricing data in SwiftData
/// Handles all CRUD operations for CachedPrice model
@MainActor
final class PriceCacheRepository {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.cardshowpro.app", category: "PriceCache")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Save new price to cache
    func savePrice(_ cachedPrice: CachedPrice) throws {
        modelContext.insert(cachedPrice)
        try modelContext.save()
        logger.info("Saved price for card: \(cachedPrice.cardID)")
    }

    // MARK: - Read

    /// Fetch price by card ID
    func getPrice(cardID: String) throws -> CachedPrice? {
        let predicate = #Predicate<CachedPrice> { $0.cardID == cardID }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    /// Fetch all cached prices
    func getAllPrices() throws -> [CachedPrice] {
        let descriptor = FetchDescriptor<CachedPrice>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch stale prices (older than specified hours)
    func getStalePrices(olderThanHours hours: Int = 24) throws -> [CachedPrice] {
        let cutoffDate = Calendar.current.date(
            byAdding: .hour,
            value: -hours,
            to: Date()
        )!

        let predicate = #Predicate<CachedPrice> { $0.lastUpdated < cutoffDate }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }

    /// Search cached prices by card name
    func searchPrices(query: String) throws -> [CachedPrice] {
        let predicate = #Predicate<CachedPrice> {
            $0.cardName.localizedStandardContains(query)
        }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 50 // Limit results for performance
        descriptor.sortBy = [SortDescriptor(\.cardName)]
        return try modelContext.fetch(descriptor)
    }

    /// Get cache statistics
    func getCacheStats() throws -> CacheStatistics {
        let allPrices = try getAllPrices()
        let stalePrices = try getStalePrices()

        return CacheStatistics(
            totalCards: allPrices.count,
            staleCards: stalePrices.count,
            freshCards: allPrices.count - stalePrices.count,
            oldestPrice: allPrices.last?.lastUpdated,
            newestPrice: allPrices.first?.lastUpdated,
            totalSize: estimateCacheSize(allPrices)
        )
    }

    // MARK: - Update

    /// Update existing cached price
    func updatePrice(_ cachedPrice: CachedPrice) throws {
        cachedPrice.lastUpdated = Date()
        try modelContext.save()
        logger.info("Updated price for card: \(cachedPrice.cardID)")
    }

    /// Refresh price data (update timestamp and values)
    func refreshPrice(
        cardID: String,
        newMarketPrice: Double?,
        newLowPrice: Double?,
        newMidPrice: Double?,
        newHighPrice: Double?
    ) throws {
        guard let cachedPrice = try getPrice(cardID: cardID) else {
            logger.warning("Attempted to refresh non-existent card: \(cardID)")
            return
        }

        cachedPrice.marketPrice = newMarketPrice
        cachedPrice.lowPrice = newLowPrice
        cachedPrice.midPrice = newMidPrice
        cachedPrice.highPrice = newHighPrice
        cachedPrice.lastUpdated = Date()

        try modelContext.save()
        logger.info("Refreshed price for card: \(cardID)")
    }

    // MARK: - Delete

    /// Delete single cached price
    func deletePrice(cardID: String) throws {
        guard let cachedPrice = try getPrice(cardID: cardID) else { return }
        modelContext.delete(cachedPrice)
        try modelContext.save()
        logger.info("Deleted cached price for card: \(cardID)")
    }

    /// Clear all cached prices
    func clearAll() throws {
        let allPrices = try getAllPrices()
        for price in allPrices {
            modelContext.delete(price)
        }
        try modelContext.save()
        logger.info("Cleared all cached prices (\(allPrices.count) cards)")
    }

    /// Delete stale prices only
    func deleteStalePrices(olderThanDays days: Int = 30) throws {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        )!

        let predicate = #Predicate<CachedPrice> { $0.lastUpdated < cutoffDate }
        try modelContext.delete(model: CachedPrice.self, where: predicate)
        try modelContext.save()
        logger.info("Deleted cached prices older than \(days) days")
    }

    // MARK: - Helpers

    /// Estimate total cache size in bytes (approximate)
    private func estimateCacheSize(_ prices: [CachedPrice]) -> Int {
        // Rough estimate: 500 bytes per card + variant data
        return prices.count * 500 + prices.compactMap { $0.variantPricesJSON?.count }.reduce(0, +)
    }
}

// MARK: - Cache Statistics

public struct CacheStatistics: Sendable {
    public let totalCards: Int
    public let staleCards: Int
    public let freshCards: Int
    public let oldestPrice: Date?
    public let newestPrice: Date?
    public let totalSize: Int

    public var totalSizeMB: Double {
        Double(totalSize) / 1_048_576 // Convert bytes to MB
    }

    public var stalePercentage: Double {
        guard totalCards > 0 else { return 0 }
        return Double(staleCards) / Double(totalCards) * 100
    }

    public var freshPercentage: Double {
        guard totalCards > 0 else { return 0 }
        return Double(freshCards) / Double(totalCards) * 100
    }

    public init(totalCards: Int, staleCards: Int, freshCards: Int, oldestPrice: Date?, newestPrice: Date?, totalSize: Int) {
        self.totalCards = totalCards
        self.staleCards = staleCards
        self.freshCards = freshCards
        self.oldestPrice = oldestPrice
        self.newestPrice = newestPrice
        self.totalSize = totalSize
    }
}
