import Foundation
import SwiftData

// MARK: - Price Cache Entry Model

/// Persistent SwiftData model for caching card price data
@Model
public final class PriceCacheEntry {
    @Attribute(.unique) public var cardId: String
    public var cardName: String
    public var setName: String?
    public var lowPrice: Double?
    public var midPrice: Double?
    public var highPrice: Double?
    public var marketPrice: Double?
    public var variantPricingJSON: String?
    public var conditionPricingJSON: String?
    public var priceHistoryJSON: String?
    public var tcgPlayerId: String?
    public var lastUpdated: Date
    public var source: String

    public init(
        cardId: String,
        cardName: String,
        setName: String? = nil,
        lowPrice: Double? = nil,
        midPrice: Double? = nil,
        highPrice: Double? = nil,
        marketPrice: Double? = nil,
        variantPricingJSON: String? = nil,
        conditionPricingJSON: String? = nil,
        priceHistoryJSON: String? = nil,
        tcgPlayerId: String? = nil,
        lastUpdated: Date = Date(),
        source: String = "tcgplayer"
    ) {
        self.cardId = cardId
        self.cardName = cardName
        self.setName = setName
        self.lowPrice = lowPrice
        self.midPrice = midPrice
        self.highPrice = highPrice
        self.marketPrice = marketPrice
        self.variantPricingJSON = variantPricingJSON
        self.conditionPricingJSON = conditionPricingJSON
        self.priceHistoryJSON = priceHistoryJSON
        self.tcgPlayerId = tcgPlayerId
        self.lastUpdated = lastUpdated
        self.source = source
    }

    // MARK: - Computed Properties

    /// Age of cache entry in hours
    public var ageInHours: Double {
        Date().timeIntervalSince(lastUpdated) / 3600
    }

    /// Whether cache is still fresh (< 24 hours)
    public var isFresh: Bool {
        ageInHours < 24
    }
}
