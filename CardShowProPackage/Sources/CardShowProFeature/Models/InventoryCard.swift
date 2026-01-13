import Foundation
import SwiftData
import SwiftUI

/// Persistent storage model for cards in the inventory
@Model
public final class InventoryCard {
    @Attribute(.unique) public var id: UUID
    public var cardName: String
    public var cardNumber: String
    public var setName: String
    public var gameType: String = CardGame.pokemon.rawValue // Default for existing records

    // Financial (renamed estimatedValue -> marketValue)
    public var purchaseCost: Double?
    public var marketValue: Double
    public var lastPriceUpdate: Date

    // Acquisition (renamed timestamp -> acquiredDate)
    public var acquiredDate: Date
    public var acquiredFrom: String?

    // Details
    public var conditionRawValue: String // Stores CardCondition.rawValue
    public var variant: String
    public var notes: String?
    public var tags: [String]

    // Computed property for CardCondition enum
    public var condition: CardCondition {
        get { CardCondition(rawValue: conditionRawValue) ?? .nearMint }
        set { conditionRawValue = newValue.rawValue }
    }

    // Images
    public var imageURL: String?
    @Attribute(.externalStorage) public var imageData: Data?

    // Grading (future)
    public var isGraded: Bool
    public var gradingCompany: String?
    public var grade: Int?
    public var certNumber: String?

    // Legacy field for migration compatibility
    public var confidence: Double

    // Computed Properties
    public var profit: Double {
        guard let cost = purchaseCost else { return 0 }
        return marketValue - cost
    }

    public var profitMargin: Double {
        guard let cost = purchaseCost, cost > 0 else { return 0 }
        return (marketValue - cost) / cost
    }

    public var roi: Double {
        profitMargin * 100
    }

    public var displayName: String {
        "\(cardName) #\(cardNumber)"
    }

    public init(
        id: UUID = UUID(),
        cardName: String,
        cardNumber: String,
        setName: String,
        gameType: String = CardGame.pokemon.rawValue,
        marketValue: Double,
        purchaseCost: Double? = nil,
        acquiredDate: Date = Date(),
        acquiredFrom: String? = nil,
        condition: CardCondition = .nearMint,
        variant: String = "Standard",
        notes: String? = nil,
        tags: [String] = [],
        imageURL: String? = nil,
        imageData: Data? = nil,
        isGraded: Bool = false,
        gradingCompany: String? = nil,
        grade: Int? = nil,
        certNumber: String? = nil,
        confidence: Double = 1.0,
        lastPriceUpdate: Date = Date()
    ) {
        self.id = id
        self.cardName = cardName
        self.cardNumber = cardNumber
        self.setName = setName
        self.gameType = gameType
        self.marketValue = marketValue
        self.purchaseCost = purchaseCost
        self.acquiredDate = acquiredDate
        self.acquiredFrom = acquiredFrom
        self.conditionRawValue = condition.rawValue
        self.variant = variant
        self.notes = notes
        self.tags = tags
        self.imageURL = imageURL
        self.imageData = imageData
        self.isGraded = isGraded
        self.gradingCompany = gradingCompany
        self.grade = grade
        self.certNumber = certNumber
        self.confidence = confidence
        self.lastPriceUpdate = lastPriceUpdate
    }

    /// Convenience initializer from ScannedCard
    convenience init(from scannedCard: ScannedCard) {
        // Convert Image to PNG data
        #if canImport(UIKit)
        let imageData = scannedCard.image.pngData()
        #else
        let imageData: Data? = nil
        #endif

        self.init(
            id: scannedCard.id,
            cardName: scannedCard.cardName,
            cardNumber: scannedCard.cardNumber,
            setName: scannedCard.setName,
            gameType: scannedCard.game.rawValue,
            marketValue: scannedCard.marketValue,
            acquiredDate: scannedCard.timestamp,
            imageData: imageData,
            confidence: scannedCard.confidence
        )
    }

    /// Convert to UIImage if data exists (iOS only)
    #if canImport(UIKit)
    public var image: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }
    #endif

    /// Get the CardGame enum from the stored string
    public var game: CardGame {
        CardGame(rawValue: gameType) ?? .pokemon
    }
}
