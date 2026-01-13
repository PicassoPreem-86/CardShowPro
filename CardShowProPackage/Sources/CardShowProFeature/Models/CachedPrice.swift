import SwiftData
import Foundation

/// Simple cached pricing model for Pokemon cards
/// Stores pricing data locally for offline access and faster lookups
@Model
public final class CachedPrice {
    // MARK: - Identity

    /// Unique card identifier from PokemonTCG.io API
    @Attribute(.unique) var cardID: String

    /// Card name for display and search
    var cardName: String

    /// Set name (e.g., "Base Set", "Sword & Shield")
    var setName: String

    /// Set ID from API (e.g., "base1", "swsh1")
    var setID: String

    /// Card number in set (e.g., "4/102")
    var cardNumber: String

    // MARK: - Pricing Data

    /// Market price (TCGPlayer aggregated price)
    var marketPrice: Double?

    /// Low price (lowest current listing)
    var lowPrice: Double?

    /// Mid price (calculated average)
    var midPrice: Double?

    /// High price (highest current listing)
    var highPrice: Double?

    // MARK: - Variant Pricing (JSON Storage)

    /// All variant pricing stored as JSON to avoid complex relationships
    /// Contains: normal, holofoil, reverseHolofoil, firstEdition, unlimited
    @Attribute(.externalStorage) var variantPricesJSON: Data?

    // MARK: - Images

    /// Small image URL for list views
    var imageURLSmall: String?

    /// Large image URL for detail views
    var imageURLLarge: String?

    // MARK: - Cache Metadata

    /// When this price data was last fetched from API
    var lastUpdated: Date

    /// When this card was first cached
    var firstCached: Date

    /// Data source (always "PokemonTCG.io" for V1)
    var source: String

    // MARK: - Computed Properties

    /// Whether cached price is stale (> 24 hours old)
    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 86400 // 24 hours
    }

    /// Age of cached data in hours
    var ageInHours: Int {
        Int(Date().timeIntervalSince(lastUpdated) / 3600)
    }

    /// Freshness level for UI indicators
    var freshnessLevel: FreshnessLevel {
        let age = Date().timeIntervalSince(lastUpdated)
        switch age {
        case 0..<3600:        return .fresh       // < 1 hour
        case 3600..<86400:    return .recent      // 1-24 hours
        case 86400..<604800:  return .stale       // 1-7 days
        default:              return .veryStale   // > 7 days
        }
    }

    // MARK: - Initializer

    public init(
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
        imageURLLarge: String? = nil,
        source: String = "PokemonTCG.io"
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
        self.source = source
        self.lastUpdated = Date()
        self.firstCached = Date()
    }
}

// MARK: - Freshness Level

public enum FreshnessLevel: String, Codable, Sendable {
    case fresh
    case recent
    case stale
    case veryStale

    public var displayText: String {
        switch self {
        case .fresh:     return "Just updated"
        case .recent:    return "Updated today"
        case .stale:     return "Needs update"
        case .veryStale: return "Outdated"
        }
    }

    public var icon: String {
        switch self {
        case .fresh:     return "checkmark.circle.fill"
        case .recent:    return "clock.fill"
        case .stale:     return "exclamationmark.triangle.fill"
        case .veryStale: return "exclamationmark.octagon.fill"
        }
    }

    public var colorName: String {
        switch self {
        case .fresh:     return "green"
        case .recent:    return "blue"
        case .stale:     return "orange"
        case .veryStale: return "red"
        }
    }
}

// MARK: - Variant Pricing Structure

/// Codable structure for storing all variant prices as JSON
public struct VariantPricing: Codable, Sendable {
    public var normal: VariantPrice?
    public var holofoil: VariantPrice?
    public var reverseHolofoil: VariantPrice?
    public var firstEdition: VariantPrice?
    public var unlimited: VariantPrice?

    public init(normal: VariantPrice? = nil, holofoil: VariantPrice? = nil, reverseHolofoil: VariantPrice? = nil, firstEdition: VariantPrice? = nil, unlimited: VariantPrice? = nil) {
        self.normal = normal
        self.holofoil = holofoil
        self.reverseHolofoil = reverseHolofoil
        self.firstEdition = firstEdition
        self.unlimited = unlimited
    }
}

public struct VariantPrice: Codable, Sendable {
    public var low: Double?
    public var mid: Double?
    public var high: Double?
    public var market: Double?
    public var directLow: Double?

    public init(low: Double? = nil, mid: Double? = nil, high: Double? = nil, market: Double? = nil, directLow: Double? = nil) {
        self.low = low
        self.mid = mid
        self.high = high
        self.market = market
        self.directLow = directLow
    }
}
