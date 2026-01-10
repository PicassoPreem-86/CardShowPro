import Foundation

// MARK: - Listing Condition

/// Card condition levels with corresponding value multipliers for listings
public enum ListingCondition: String, CaseIterable, Identifiable, Sendable {
    case mint = "Mint"
    case nearMint = "Near Mint"
    case lightlyPlayed = "Lightly Played"
    case moderatelyPlayed = "Moderately Played"
    case heavilyPlayed = "Heavily Played"
    case damaged = "Damaged"

    public var id: String { rawValue }

    /// Value multiplier for pricing calculations
    public var valueMultiplier: Double {
        switch self {
        case .mint: return 1.0
        case .nearMint: return 0.85
        case .lightlyPlayed: return 0.70
        case .moderatelyPlayed: return 0.50
        case .heavilyPlayed: return 0.30
        case .damaged: return 0.15
        }
    }

    /// Description for use in listing text
    public var description: String {
        switch self {
        case .mint:
            return "Perfect condition, fresh from pack"
        case .nearMint:
            return "Minimal wear visible on close inspection"
        case .lightlyPlayed:
            return "Minor edge wear, light surface scratches"
        case .moderatelyPlayed:
            return "Visible edge wear, surface scratches, possible minor creases"
        case .heavilyPlayed:
            return "Significant wear, multiple creases, surface damage"
        case .damaged:
            return "Major damage, tears, heavy creasing, water damage"
        }
    }
}

// MARK: - Listing Platform

/// Supported selling platforms with character limits and requirements
public enum ListingPlatform: String, CaseIterable, Identifiable, Sendable {
    case ebay = "eBay"
    case tcgplayer = "TCGplayer"
    case facebook = "Facebook Marketplace"
    case stockx = "StockX"
    case mercari = "Mercari"

    public var id: String { rawValue }

    /// Title character limit for this platform
    public var titleCharLimit: Int {
        switch self {
        case .ebay: return 80
        case .tcgplayer: return 100
        case .facebook: return 100
        case .stockx: return 80
        case .mercari: return 80
        }
    }

    /// Description character limit for this platform
    public var descriptionCharLimit: Int {
        switch self {
        case .ebay: return 5000
        case .tcgplayer: return 1000
        case .facebook: return 5000
        case .stockx: return 500
        case .mercari: return 1000
        }
    }

    /// Icon name for platform
    public var iconName: String {
        switch self {
        case .ebay: return "cart.fill"
        case .tcgplayer: return "gamecontroller.fill"
        case .facebook: return "person.2.fill"
        case .stockx: return "chart.line.uptrend.xyaxis"
        case .mercari: return "bag.fill"
        }
    }

    /// Platform-specific title format guidelines
    public var titleFormat: String {
        switch self {
        case .ebay:
            return "[Card Name] - [Set] - [Condition] - Pokemon TCG"
        case .tcgplayer:
            return "[Card Name] ([Set] [Card Number]) [Condition]"
        case .facebook:
            return "[Card Name] - [Set] Pokemon Card - [Condition]"
        case .stockx:
            return "[Card Name] - Pokemon [Set]"
        case .mercari:
            return "Pokemon [Card Name] [Set] [Condition]"
        }
    }
}

// MARK: - Pricing Strategy

/// Pricing strategies for automated price calculation
public enum PricingStrategy: String, CaseIterable, Identifiable, Sendable {
    case market = "Market Price"
    case premium = "Premium (+10%)"
    case discount = "Quick Sale (-10%)"
    case custom = "Custom Price"

    public var id: String { rawValue }

    /// Price multiplier for strategy
    public var priceMultiplier: Double {
        switch self {
        case .market: return 1.0
        case .premium: return 1.10
        case .discount: return 0.90
        case .custom: return 1.0 // User enters their own
        }
    }

    /// Icon for strategy
    public var iconName: String {
        switch self {
        case .market: return "chart.bar.fill"
        case .premium: return "arrow.up.circle.fill"
        case .discount: return "arrow.down.circle.fill"
        case .custom: return "pencil.circle.fill"
        }
    }
}

// MARK: - Card Source

/// Where the card information came from
/// Note: InventoryCard will be made Sendable separately to resolve conformance
public enum CardSource {
    case inventory(InventoryCard)
    case manual(cardName: String, setName: String, cardNumber: String, value: Double)
}

// MARK: - Generated Listing

/// The generated listing output
public struct GeneratedListing: Sendable {
    public let title: String
    public let description: String
    public let suggestedPrice: Double
    public let seoKeywords: [String]
    public let optimizationScore: Int // 0-100
    public let platform: ListingPlatform
    public let condition: ListingCondition

    /// Full formatted text for copying
    public var fullText: String {
        """
        \(title)

        \(description)

        Suggested Price: $\(String(format: "%.2f", suggestedPrice))
        """
    }

    /// Character counts for validation
    public var titleCharCount: Int { title.count }
    public var descriptionCharCount: Int { description.count }

    /// Validation flags
    public var isTitleOverLimit: Bool {
        titleCharCount > platform.titleCharLimit
    }

    public var isDescriptionOverLimit: Bool {
        descriptionCharCount > platform.descriptionCharLimit
    }
}

// MARK: - Listing Template

/// Custom listing templates (for future Phase 4)
public struct ListingTemplate: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let titleTemplate: String
    public let descriptionTemplate: String
    public let platform: ListingPlatform

    public init(
        id: UUID = UUID(),
        name: String,
        titleTemplate: String,
        descriptionTemplate: String,
        platform: ListingPlatform
    ) {
        self.id = id
        self.name = name
        self.titleTemplate = titleTemplate
        self.descriptionTemplate = descriptionTemplate
        self.platform = platform
    }
}

// MARK: - SEO Analysis

/// SEO keyword analysis for listing optimization
public struct SEOAnalysis: Sendable {
    public let keywords: [String]
    public let optimizationScore: Int // 0-100
    public let suggestions: [String]

    public init(keywords: [String], optimizationScore: Int, suggestions: [String]) {
        self.keywords = keywords
        self.optimizationScore = optimizationScore
        self.suggestions = suggestions
    }
}
