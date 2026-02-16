import Foundation

/// Observable view model for managing trade comparison state
@Observable
@MainActor
final class TradeAnalyzerViewModel {
    var yourCards: [TradeCard] = []
    var theirCards: [TradeCard] = []
    var showingAddYourCard = false
    var showingAddTheirCard = false
    var showingInventoryPicker = false
    var showingYourCardSourcePicker = false
    var manualCardName = ""
    var manualSetName = ""
    var manualValue = ""
    var isAddingToYourSide = true

    /// Current trade analysis based on card lists
    var analysis: TradeAnalysis {
        TradeAnalysis.calculate(yourCards: yourCards, theirCards: theirCards)
    }

    /// Add a card to the specified side
    func addCard(to side: TradeSide) {
        isAddingToYourSide = (side == .yours)
        if side == .yours {
            showingYourCardSourcePicker = true
        } else {
            showingAddTheirCard = true
        }
    }

    /// Remove a card from the specified side
    func removeCard(_ card: TradeCard, from side: TradeSide) {
        if side == .yours {
            yourCards.removeAll { $0.id == card.id }
        } else {
            theirCards.removeAll { $0.id == card.id }
        }
    }

    /// Add a manually entered card
    func addManualCard() {
        guard !manualCardName.isEmpty,
              let value = Decimal(string: manualValue),
              value > 0 else {
            return
        }

        let card = TradeCard(
            name: manualCardName,
            setName: manualSetName.isEmpty ? nil : manualSetName,
            estimatedValue: value,
            imageURL: nil,
            isFromInventory: false
        )

        if isAddingToYourSide {
            yourCards.append(card)
        } else {
            theirCards.append(card)
        }

        resetManualEntry()
    }

    /// Add a card from the user's inventory
    func addCardFromInventory(_ inventoryCard: InventoryCard) {
        let card = TradeCard(
            name: inventoryCard.cardName,
            setName: inventoryCard.setName,
            estimatedValue: Decimal(inventoryCard.estimatedValue),
            imageURL: nil,
            isFromInventory: true,
            condition: inventoryCard.condition,
            imageData: inventoryCard.imageData
        )

        yourCards.append(card)
    }

    /// Reset manual entry form fields
    func resetManualEntry() {
        manualCardName = ""
        manualSetName = ""
        manualValue = ""
    }

    /// Which side of the trade a card belongs to
    enum TradeSide {
        case yours
        case theirs
    }
}
