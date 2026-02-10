import Foundation
import SwiftData
import UIKit

/// Persistent storage model for cards in the inventory
@Model
public final class InventoryCard {
    @Attribute(.unique) public var id: UUID
    public var cardName: String
    public var cardNumber: String
    public var setName: String
    public var gameType: String = CardGame.pokemon.rawValue // Default for existing records
    public var estimatedValue: Double
    public var confidence: Double
    public var timestamp: Date

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
        imageData: Data? = nil
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

    /// Convert to UIImage if data exists
    public var image: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }

    /// Get the CardGame enum from the stored string
    public var game: CardGame {
        CardGame(rawValue: gameType) ?? .pokemon
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

    /// Optional purchase cost for profit calculations
    @Transient public var purchaseCost: Double? = nil

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
}
