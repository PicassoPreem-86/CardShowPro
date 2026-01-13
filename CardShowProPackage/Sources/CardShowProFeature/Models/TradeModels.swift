import Foundation

/// Represents a card in a trade comparison
struct TradeCard: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let setName: String?
    let marketValue: Decimal
    let imageURL: URL?
    let isFromInventory: Bool

    init(
        id: UUID = UUID(),
        name: String,
        setName: String? = nil,
        marketValue: Decimal,
        imageURL: URL? = nil,
        isFromInventory: Bool
    ) {
        self.id = id
        self.name = name
        self.setName = setName
        self.marketValue = marketValue
        self.imageURL = imageURL
        self.isFromInventory = isFromInventory
    }
}

/// Analysis results comparing two sets of cards in a trade
struct TradeAnalysis: Equatable, Sendable {
    let yourTotal: Decimal
    let theirTotal: Decimal
    let difference: Decimal
    let percentageDifference: Double
    let fairnessLevel: FairnessLevel

    enum FairnessLevel {
        case fair          // Within 10%
        case caution       // 10-25%
        case unfair        // >25%
    }

    /// Calculate trade analysis from two card sets
    static func calculate(yourCards: [TradeCard], theirCards: [TradeCard]) -> TradeAnalysis {
        let yourTotal = yourCards.reduce(Decimal.zero) { $0 + $1.marketValue }
        let theirTotal = theirCards.reduce(Decimal.zero) { $0 + $1.marketValue }
        let difference = theirTotal - yourTotal

        let percentDiff: Double
        if yourTotal == 0 && theirTotal == 0 {
            percentDiff = 0
        } else if yourTotal == 0 {
            percentDiff = 100
        } else {
            percentDiff = abs(Double(truncating: difference as NSNumber) / Double(truncating: yourTotal as NSNumber)) * 100
        }

        let level: FairnessLevel
        if percentDiff < 10 {
            level = .fair
        } else if percentDiff < 25 {
            level = .caution
        } else {
            level = .unfair
        }

        return TradeAnalysis(
            yourTotal: yourTotal,
            theirTotal: theirTotal,
            difference: difference,
            percentageDifference: percentDiff,
            fairnessLevel: level
        )
    }
}

// MARK: - Mock Data

extension TradeCard {
    static let mockYourCards: [TradeCard] = [
        TradeCard(
            name: "Charizard VMAX",
            setName: "Darkness Ablaze",
            marketValue: 350.00,
            imageURL: URL(string: "https://images.pokemontcg.io/swsh3/20_hires.png"),
            isFromInventory: true
        ),
        TradeCard(
            name: "Blastoise",
            setName: "Base Set",
            marketValue: 100.00,
            imageURL: nil,
            isFromInventory: true
        )
    ]

    static let mockTheirCards: [TradeCard] = [
        TradeCard(
            name: "Pikachu VMAX",
            setName: "Vivid Voltage",
            marketValue: 280.00,
            imageURL: URL(string: "https://images.pokemontcg.io/swsh4/188_hires.png"),
            isFromInventory: false
        ),
        TradeCard(
            name: "Mewtwo GX",
            setName: "Shining Legends",
            marketValue: 200.00,
            imageURL: nil,
            isFromInventory: false
        )
    ]
}
