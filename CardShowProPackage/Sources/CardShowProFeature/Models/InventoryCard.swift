import Foundation
import SwiftData
import UIKit

// MARK: - Card Status

/// Lifecycle status for an inventory card
public enum CardStatus: String, CaseIterable, Codable, Sendable {
    case inStock = "In Stock"
    case listed = "Listed"
    case sold = "Sold"
    case shipped = "Shipped"
    case returned = "Returned"
    case disputed = "Disputed"

    public var icon: String {
        switch self {
        case .inStock: return "shippingbox.fill"
        case .listed: return "tag.fill"
        case .sold: return "dollarsign.circle.fill"
        case .shipped: return "paperplane.fill"
        case .returned: return "arrow.uturn.backward.circle.fill"
        case .disputed: return "exclamationmark.triangle.fill"
        }
    }

    public var color: String {
        switch self {
        case .inStock: return "cyan"
        case .listed: return "blue"
        case .sold: return "green"
        case .shipped: return "gray"
        case .returned: return "red"
        case .disputed: return "orange"
        }
    }
}

// MARK: - Card Variant (Inventory)

/// Card variant types for inventory tracking
public enum InventoryCardVariant: String, CaseIterable, Codable, Sendable {
    case normal = "Normal"
    case holofoil = "Holofoil"
    case reverseHolofoil = "Reverse Holofoil"
    case firstEdition = "1st Edition"
    case unlimited = "Unlimited"
    case secretRare = "Secret Rare"
    case fullArt = "Full Art"
    case altArt = "Alt Art"
    case illustrationRare = "Illustration Rare"
    case specialArtRare = "Special Art Rare"
    case hyperRare = "Hyper Rare"
    case goldRare = "Gold Rare"

    public var displayName: String { rawValue }
}

// MARK: - Shipping Carrier

/// Supported shipping carriers
public enum ShippingCarrier: String, CaseIterable, Codable, Sendable {
    case usps = "USPS"
    case ups = "UPS"
    case fedex = "FedEx"
    case dhl = "DHL"
    case other = "Other"

    public var displayName: String { rawValue }

    public var trackingUrlTemplate: String {
        switch self {
        case .usps: return "https://tools.usps.com/go/TrackConfirmAction?tLabels={tracking}"
        case .ups: return "https://www.ups.com/track?tracknum={tracking}"
        case .fedex: return "https://www.fedex.com/fedextrack/?trknbr={tracking}"
        case .dhl: return "https://www.dhl.com/us-en/home/tracking.html?tracking-id={tracking}"
        case .other: return ""
        }
    }
}

// MARK: - Grading Service

/// Supported card grading services
public enum GradingService: String, CaseIterable, Codable, Sendable {
    case psa = "PSA"
    case bgs = "BGS"
    case cgc = "CGC"
    case sgc = "SGC"
    case other = "Other"
}

// MARK: - Acquisition Source

/// Common sources for acquiring cards
public enum AcquisitionSource: String, CaseIterable, Codable, Sendable {
    case localPickup = "Local Pickup"
    case onlinePurchase = "Online Purchase"
    case trade = "Trade"
    case eventShow = "Event/Show"
    case consignment = "Consignment"
    case personalCollection = "Personal Collection"
    case other = "Other"
}

// MARK: - Inventory Card Model

/// Persistent storage model for cards in the inventory
@Model
public final class InventoryCard {
    @Attribute(.unique) public var id: UUID
    public var cardName: String
    public var cardNumber: String
    public var setName: String
    public var gameType: String = CardGame.pokemon.rawValue

    // Value & Cost
    public var estimatedValue: Double
    public var purchaseCost: Double?
    public var confidence: Double
    public var timestamp: Date

    // Persisted fields (previously missing or transient)
    public var category: String = "Raw Singles"
    public var condition: String = "Near Mint"
    public var notes: String = ""
    public var quantity: Int = 1

    // Card lifecycle
    public var status: String = "In Stock"
    public var platform: String?

    // Acquisition tracking
    public var acquisitionSource: String?
    public var acquisitionDate: Date?
    public var contactId: UUID?

    // Grading info
    public var gradingService: String?
    public var grade: String?
    public var certNumber: String?
    public var gradingCost: Double?

    // Sale tracking
    public var soldPrice: Double?
    public var soldDate: Date?
    public var listingPrice: Double?
    public var listedDate: Date?

    // Card variant
    public var variant: String?

    // Organization
    public var tags: String?
    public var storageLocation: String?

    // Shipping & fulfillment
    public var trackingNumber: String?
    public var carrier: String?
    public var shippedDate: Date?

    // Listing details
    public var listingUrl: String?
    public var platformListingId: String?

    // Returns
    public var returnReason: String?
    public var refundAmount: Double?
    public var refundDate: Date?

    // Store image as Data since SwiftData doesn't support UIImage directly
    @Attribute(.externalStorage) public var imageData: Data?

    public init(
        id: UUID = UUID(),
        cardName: String,
        cardNumber: String,
        setName: String,
        gameType: String = CardGame.pokemon.rawValue,
        estimatedValue: Double,
        confidence: Double,
        timestamp: Date = Date(),
        imageData: Data? = nil,
        purchaseCost: Double? = nil,
        category: String = "Raw Singles",
        condition: String = "Near Mint",
        notes: String = "",
        quantity: Int = 1,
        status: String = "In Stock",
        acquisitionSource: String? = nil
    ) {
        self.id = id
        self.cardName = cardName
        self.cardNumber = cardNumber
        self.setName = setName
        self.gameType = gameType
        self.estimatedValue = estimatedValue
        self.confidence = confidence
        self.timestamp = timestamp
        self.imageData = imageData
        self.purchaseCost = purchaseCost
        self.category = category
        self.condition = condition
        self.notes = notes
        self.quantity = quantity
        self.status = status
        self.acquisitionSource = acquisitionSource
    }

    /// Convenience initializer from ScannedCard
    @MainActor convenience init(from scannedCard: ScannedCard) {
        self.init(
            id: scannedCard.id,
            cardName: scannedCard.name,
            cardNumber: scannedCard.cardNumber,
            setName: scannedCard.setName,
            gameType: CardGame.pokemon.rawValue,
            estimatedValue: scannedCard.marketPrice ?? 0,
            confidence: 1.0,
            timestamp: scannedCard.timestamp,
            imageData: nil
        )
    }

    // MARK: - Computed Properties

    /// Convert to UIImage if data exists
    public var image: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }

    /// Get the CardGame enum from the stored string
    public var game: CardGame {
        CardGame(rawValue: gameType) ?? .pokemon
    }

    /// Get the CardCategory enum from the stored string
    var cardCategory: CardCategory {
        CardCategory(rawValue: category) ?? .rawSingles
    }

    /// Get the CardCondition enum from the stored string
    var cardCondition: CardCondition {
        CardCondition(rawValue: condition) ?? .nearMint
    }

    /// Get the CardStatus enum from the stored string
    public var cardStatus: CardStatus {
        CardStatus(rawValue: status) ?? .inStock
    }

    /// Get the GradingService enum from the stored string
    public var cardGradingService: GradingService? {
        guard let gradingService else { return nil }
        return GradingService(rawValue: gradingService)
    }

    /// Get the AcquisitionSource enum from the stored string
    public var cardAcquisitionSource: AcquisitionSource? {
        guard let acquisitionSource else { return nil }
        return AcquisitionSource(rawValue: acquisitionSource)
    }

    // MARK: - Convenience Aliases

    /// Alias for estimatedValue used throughout the UI
    public var marketValue: Double {
        get { estimatedValue }
        set { estimatedValue = newValue }
    }

    /// Alias for timestamp used throughout the UI
    public var acquiredDate: Date {
        get { timestamp }
        set { timestamp = newValue }
    }

    // MARK: - Profit Tracking

    /// Calculated profit (market value minus purchase cost)
    public var profit: Double {
        guard let cost = purchaseCost else { return 0 }
        return estimatedValue - cost
    }

    /// Return on investment percentage
    public var roi: Double {
        guard let cost = purchaseCost, cost > 0 else { return 0 }
        return (profit / cost) * 100
    }

    /// Profit from actual sale (soldPrice minus costs)
    public var saleProfit: Double? {
        guard let sold = soldPrice else { return nil }
        let cost = purchaseCost ?? 0
        let grading = gradingCost ?? 0
        return sold - cost - grading
    }

    // MARK: - Status Helpers

    /// Whether the card is available for sale
    public var isAvailable: Bool {
        cardStatus == .inStock || cardStatus == .listed
    }

    /// Whether the card has been sold
    public var isSold: Bool {
        cardStatus == .sold || cardStatus == .shipped
    }

    /// Whether the card has grading information
    public var isGraded: Bool {
        gradingService != nil && grade != nil
    }

    /// Formatted grade display (e.g. "PSA 10")
    public var gradeDisplay: String? {
        guard let service = gradingService, let grade else { return nil }
        return "\(service) \(grade)"
    }

    /// Days in inventory (since added or acquired)
    public var daysInInventory: Int {
        let reference = acquisitionDate ?? timestamp
        return Calendar.current.dateComponents([.day], from: reference, to: Date()).day ?? 0
    }

    // MARK: - Variant & Carrier Helpers

    /// Split comma-separated tags into an array
    public var tagsArray: [String] {
        guard let tags, !tags.isEmpty else { return [] }
        return tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Get the InventoryCardVariant enum from the stored string
    public var variantType: InventoryCardVariant? {
        guard let variant else { return nil }
        return InventoryCardVariant(rawValue: variant)
    }

    /// Get the ShippingCarrier enum from the stored string
    public var carrierType: ShippingCarrier? {
        guard let carrier else { return nil }
        return ShippingCarrier(rawValue: carrier)
    }

    /// Whether the card has been returned
    public var isReturned: Bool {
        refundDate != nil
    }

    /// Net profit accounting for refunds (soldPrice - purchaseCost - gradingCost - refundAmount)
    public var netProfit: Double? {
        guard let sold = soldPrice else { return nil }
        let cost = purchaseCost ?? 0
        let grading = gradingCost ?? 0
        let refund = refundAmount ?? 0
        return sold - cost - grading - refund
    }
}
