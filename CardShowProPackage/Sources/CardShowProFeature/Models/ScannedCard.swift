import Foundation
import SwiftUI

/// Represents a card that has been scanned during a capture session
struct ScannedCard: Identifiable, Sendable {
    let id: UUID
    let image: UIImage
    let timestamp: Date
    var cardName: String
    var cardNumber: String
    var setName: String
    var game: CardGame
    var estimatedValue: Double
    var confidence: Double // 0.0 to 1.0 for AI confidence

    init(
        id: UUID = UUID(),
        image: UIImage,
        timestamp: Date = Date(),
        cardName: String = "Unknown Card",
        cardNumber: String = "",
        setName: String = "",
        game: CardGame = .pokemon,
        estimatedValue: Double = 0.0,
        confidence: Double = 0.0
    ) {
        self.id = id
        self.image = image
        self.timestamp = timestamp
        self.cardName = cardName
        self.cardNumber = cardNumber
        self.setName = setName
        self.game = game
        self.estimatedValue = estimatedValue
        self.confidence = confidence
    }
}

/// Manages a card scanning session with multiple cards
@Observable
@MainActor
final class ScanSession {
    var scannedCards: [ScannedCard] = []
    var isProcessing: Bool = false

    var totalValue: Double {
        scannedCards.reduce(0) { $0 + $1.estimatedValue }
    }

    var cardCount: Int {
        scannedCards.count
    }

    func addCard(_ card: ScannedCard) {
        scannedCards.append(card)
    }

    func removeCard(_ card: ScannedCard) {
        scannedCards.removeAll { $0.id == card.id }
    }

    func updateCard(_ card: ScannedCard) {
        if let index = scannedCards.firstIndex(where: { $0.id == card.id }) {
            scannedCards[index] = card
        }
    }

    func clear() {
        scannedCards.removeAll()
    }
}
