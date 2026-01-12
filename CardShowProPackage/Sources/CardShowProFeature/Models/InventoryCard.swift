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
            estimatedValue: scannedCard.estimatedValue,
            confidence: scannedCard.confidence,
            timestamp: scannedCard.timestamp,
            imageData: imageData
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
