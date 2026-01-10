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
        estimatedValue: Double,
        confidence: Double,
        timestamp: Date = Date(),
        imageData: Data? = nil
    ) {
        self.id = id
        self.cardName = cardName
        self.cardNumber = cardNumber
        self.setName = setName
        self.estimatedValue = estimatedValue
        self.confidence = confidence
        self.timestamp = timestamp
        self.imageData = imageData
    }

    /// Convenience initializer from ScannedCard
    convenience init(from scannedCard: ScannedCard) {
        // Convert UIImage to PNG data
        let imageData = scannedCard.image.pngData()

        self.init(
            id: scannedCard.id,
            cardName: scannedCard.cardName,
            cardNumber: scannedCard.cardNumber,
            setName: scannedCard.setName,
            estimatedValue: scannedCard.estimatedValue,
            confidence: scannedCard.confidence,
            timestamp: scannedCard.timestamp,
            imageData: imageData
        )
    }

    /// Convert to UIImage if data exists
    public var image: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }
}
