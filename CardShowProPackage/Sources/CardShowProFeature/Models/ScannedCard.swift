import Foundation
import SwiftUI

/// Represents a card that has been scanned during a capture session
/// @Observable class to support @Bindable in detail views and mutable pricing state
@Observable
@MainActor
final class ScannedCard: Identifiable, Hashable {
    nonisolated static func == (lhs: ScannedCard, rhs: ScannedCard) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: UUID
    let timestamp: Date

    // Card identity
    var name: String
    var cardNumber: String
    var setName: String
    var setID: String
    var cardID: String

    // Image
    var imageURL: URL?

    // Pricing (populated async after scan)
    var marketPrice: Double?
    var displayPrice: Double?
    var isLoadingPrice: Bool = false
    var pricingError: String?

    // Detailed pricing data
    var conditionPrices: ConditionPrices?
    var priceChange7d: Double?
    var priceChange30d: Double?
    var priceHistory: [PricePoint]?
    var tcgPlayerBuyURL: URL?
    var rarity: String?

    // Convenience: card name alias for backward compatibility
    var cardName: String {
        get { name }
        set { name = newValue }
    }

    /// Relative time description (e.g. "2m ago", "1h ago")
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        let seconds = Int(interval)
        if seconds < 60 { return "Just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }

    /// Formatted price string for display
    var formattedPrice: String {
        if let price = displayPrice ?? marketPrice {
            return "$\(String(format: "%.2f", price))"
        }
        return "—"
    }

    /// Primary initializer for scan results
    init(
        cardID: String,
        name: String,
        setName: String,
        setID: String,
        cardNumber: String,
        imageURL: URL? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.cardID = cardID
        self.name = name
        self.setName = setName
        self.setID = setID
        self.cardNumber = cardNumber
        self.imageURL = imageURL
    }
}

// MARK: - Preview Mocks

#if DEBUG
extension ScannedCard {
    static var mockCharizard: ScannedCard {
        let card = ScannedCard(
            cardID: "base1-4",
            name: "Charizard",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "4",
            imageURL: URL(string: "https://images.pokemontcg.io/base1/4_hires.png")
        )
        card.marketPrice = 350.00
        card.displayPrice = 350.00
        card.rarity = "Holo Rare"
        card.priceChange7d = 12.50
        card.priceChange30d = 25.00
        return card
    }

    static var mockLoading: ScannedCard {
        let card = ScannedCard(
            cardID: "base1-58",
            name: "Pikachu",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "58",
            imageURL: URL(string: "https://images.pokemontcg.io/base1/58_hires.png")
        )
        card.isLoadingPrice = true
        return card
    }
}
#endif

/// Manages a card scanning session with multiple cards
@Observable
@MainActor
final class ScanSession {
    var scannedCards: [ScannedCard] = []
    var isProcessing: Bool = false

    var totalValue: Double {
        scannedCards.compactMap { $0.marketPrice }.reduce(0, +)
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

    func clear() {
        scannedCards.removeAll()
    }
}
