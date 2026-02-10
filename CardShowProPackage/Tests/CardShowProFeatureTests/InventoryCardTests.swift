import Testing
import Foundation
@testable import CardShowProFeature

@Suite("InventoryCard Model Tests")
struct InventoryCardTests {

    // MARK: - Initialization Tests

    @Test("Create card with required parameters")
    func createCard() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 50.0,
            confidence: 0.95
        )

        #expect(card.cardName == "Pikachu")
        #expect(card.cardNumber == "25")
        #expect(card.setName == "Base Set")
        #expect(card.estimatedValue == 50.0)
        #expect(card.confidence == 0.95)
        #expect(card.imageData == nil)
    }

    @Test("Create card with all parameters")
    func createFullCard() {
        let card = InventoryCard(
            cardName: "Charizard",
            cardNumber: "4",
            setName: "Base Set",
            gameType: "pokemon",
            estimatedValue: 500.0,
            confidence: 1.0,
            imageData: nil
        )

        #expect(card.cardName == "Charizard")
        #expect(card.estimatedValue == 500.0)
        #expect(card.gameType == "pokemon")
        #expect(card.confidence == 1.0)
    }

    @Test("Default game type is pokemon")
    func defaultGameType() {
        let card = InventoryCard(
            cardName: "Test",
            cardNumber: "1",
            setName: "Test Set",
            estimatedValue: 10.0,
            confidence: 0.5
        )

        #expect(card.game == CardGame.pokemon)
    }

    // MARK: - Alias Tests

    @Test("marketValue alias maps to estimatedValue")
    func marketValueAlias() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 50.0,
            confidence: 0.9
        )

        #expect(card.marketValue == 50.0)
        #expect(card.marketValue == card.estimatedValue)

        card.marketValue = 75.0
        #expect(card.estimatedValue == 75.0)
    }

    @Test("acquiredDate alias maps to timestamp")
    func acquiredDateAlias() {
        let date = Date()
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 50.0,
            confidence: 0.9,
            timestamp: date
        )

        #expect(card.acquiredDate == date)
    }

    // MARK: - Profit Calculation Tests

    @Test("Profit with purchase cost")
    func profitWithCost() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 100.0,
            confidence: 0.9
        )
        card.purchaseCost = 60.0

        #expect(card.profit == 40.0)
    }

    @Test("Profit is zero when no purchase cost")
    func profitNoCost() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 100.0,
            confidence: 0.9
        )

        #expect(card.profit == 0.0)
    }

    @Test("Profit can be negative")
    func profitNegative() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 50.0,
            confidence: 0.9
        )
        card.purchaseCost = 80.0

        #expect(card.profit == -30.0)
    }

    @Test("Profit is zero at break even")
    func profitBreakEven() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 75.0,
            confidence: 0.9
        )
        card.purchaseCost = 75.0

        #expect(card.profit == 0.0)
    }

    // MARK: - ROI Tests

    @Test("Calculate ROI percentage")
    func roiNormal() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 200.0,
            confidence: 0.9
        )
        card.purchaseCost = 100.0

        // ((200 - 100) / 100) * 100 = 100%
        #expect(card.roi == 100.0)
    }

    @Test("ROI is zero when no purchase cost")
    func roiNoCost() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 100.0,
            confidence: 0.9
        )

        #expect(card.roi == 0.0)
    }

    @Test("ROI can be negative")
    func roiNegative() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 50.0,
            confidence: 0.9
        )
        card.purchaseCost = 100.0

        // ((50 - 100) / 100) * 100 = -50%
        #expect(card.roi == -50.0)
    }

    @Test("ROI is zero when purchase cost is zero")
    func roiZeroCost() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 100.0,
            confidence: 0.9
        )
        card.purchaseCost = 0.0

        #expect(card.roi == 0.0)
    }

    // MARK: - Edge Case Tests

    @Test("Very large market value")
    func veryLargeMarketValue() {
        let card = InventoryCard(
            cardName: "Pikachu Illustrator",
            cardNumber: "1",
            setName: "Promo",
            estimatedValue: 5_000_000.0,
            confidence: 1.0
        )
        card.purchaseCost = 2_000_000.0

        #expect(card.profit == 3_000_000.0)
        #expect(card.roi == 150.0)
    }

    @Test("Very small values")
    func verySmallValues() {
        let card = InventoryCard(
            cardName: "Common Card",
            cardNumber: "100",
            setName: "Recent Set",
            estimatedValue: 0.25,
            confidence: 0.8
        )
        card.purchaseCost = 0.10

        #expect(abs(card.profit - 0.15) < 0.001)
        #expect(abs(card.roi - 150.0) < 0.01)
    }

    @Test("Zero market value with purchase cost")
    func zeroMarketValue() {
        let card = InventoryCard(
            cardName: "Damaged Card",
            cardNumber: "50",
            setName: "Old Set",
            estimatedValue: 0.0,
            confidence: 0.5
        )
        card.purchaseCost = 10.0

        #expect(card.profit == -10.0)
        #expect(card.roi == -100.0)
    }

    @Test("Unique ID is generated")
    func uniqueIdGenerated() {
        let card1 = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 50.0,
            confidence: 0.9
        )
        let card2 = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            estimatedValue: 50.0,
            confidence: 0.9
        )

        #expect(card1.id != card2.id)
    }
}
