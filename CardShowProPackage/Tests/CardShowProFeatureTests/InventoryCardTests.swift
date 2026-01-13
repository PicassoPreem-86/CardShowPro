import Testing
import Foundation
@testable import CardShowProFeature

@Suite("InventoryCard Model Tests")
struct InventoryCardTests {

    // MARK: - Initialization Tests

    @Test("Create card with minimal parameters")
    func createMinimalCard() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 50.0
        )

        #expect(card.cardName == "Pikachu")
        #expect(card.cardNumber == "25")
        #expect(card.setName == "Base Set")
        #expect(card.marketValue == 50.0)
        #expect(card.condition == .nearMint)
        #expect(card.variant == "Standard")
        #expect(card.tags == [])
        #expect(card.isGraded == false)
        #expect(card.purchaseCost == nil)
    }

    @Test("Create card with all parameters")
    func createFullCard() {
        let card = InventoryCard(
            cardName: "Charizard",
            cardNumber: "4",
            setName: "Base Set",
            marketValue: 500.0,
            purchaseCost: 300.0,
            acquiredFrom: "Card Show Phoenix",
            condition: .mint,
            variant: "Holo",
            notes: "First edition",
            tags: ["High Value", "Featured"],
            isGraded: true,
            gradingCompany: "PSA",
            grade: 10,
            certNumber: "12345678"
        )

        #expect(card.cardName == "Charizard")
        #expect(card.marketValue == 500.0)
        #expect(card.purchaseCost == 300.0)
        #expect(card.acquiredFrom == "Card Show Phoenix")
        #expect(card.condition == .mint)
        #expect(card.variant == "Holo")
        #expect(card.notes == "First edition")
        #expect(card.tags == ["High Value", "Featured"])
        #expect(card.isGraded == true)
        #expect(card.gradingCompany == "PSA")
        #expect(card.grade == 10)
        #expect(card.certNumber == "12345678")
    }

    // MARK: - Profit Calculation Tests

    @Test("Calculate profit with purchase cost")
    func profitWithCost() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 100.0,
            purchaseCost: 60.0
        )

        #expect(card.profit == 40.0)
    }

    @Test("Profit is zero when no purchase cost")
    func profitNoCost() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 100.0,
            purchaseCost: nil
        )

        #expect(card.profit == 0.0)
    }

    @Test("Profit can be negative")
    func profitNegative() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 50.0,
            purchaseCost: 80.0
        )

        #expect(card.profit == -30.0)
    }

    @Test("Profit is zero when market value equals cost")
    func profitBreakEven() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 75.0,
            purchaseCost: 75.0
        )

        #expect(card.profit == 0.0)
    }

    // MARK: - Profit Margin Tests

    @Test("Calculate profit margin")
    func profitMarginNormal() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 150.0,
            purchaseCost: 100.0
        )

        // (150 - 100) / 100 = 0.5 (50%)
        #expect(card.profitMargin == 0.5)
    }

    @Test("Profit margin is zero when no purchase cost")
    func profitMarginNoCost() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 100.0,
            purchaseCost: nil
        )

        #expect(card.profitMargin == 0.0)
    }

    @Test("Profit margin is zero when cost is zero")
    func profitMarginZeroCost() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 100.0,
            purchaseCost: 0.0
        )

        #expect(card.profitMargin == 0.0)
    }

    @Test("Profit margin can be negative")
    func profitMarginNegative() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 60.0,
            purchaseCost: 100.0
        )

        // (60 - 100) / 100 = -0.4 (-40%)
        #expect(card.profitMargin == -0.4)
    }

    @Test("Profit margin is zero at break even")
    func profitMarginBreakEven() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 100.0,
            purchaseCost: 100.0
        )

        #expect(card.profitMargin == 0.0)
    }

    // MARK: - ROI Tests

    @Test("Calculate ROI percentage")
    func roiNormal() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 200.0,
            purchaseCost: 100.0
        )

        // ((200 - 100) / 100) * 100 = 100%
        #expect(card.roi == 100.0)
    }

    @Test("ROI is zero when no purchase cost")
    func roiNoCost() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 100.0,
            purchaseCost: nil
        )

        #expect(card.roi == 0.0)
    }

    @Test("ROI can be negative")
    func roiNegative() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 50.0,
            purchaseCost: 100.0
        )

        // ((50 - 100) / 100) * 100 = -50%
        #expect(card.roi == -50.0)
    }

    @Test("ROI with 50% profit margin is 50%")
    func roiFiftyPercent() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 75.0,
            purchaseCost: 50.0
        )

        // ((75 - 50) / 50) * 100 = 50%
        #expect(card.roi == 50.0)
    }

    // MARK: - Display Name Tests

    @Test("Display name format")
    func displayNameFormat() {
        let card = InventoryCard(
            cardName: "Charizard",
            cardNumber: "4",
            setName: "Base Set",
            marketValue: 500.0
        )

        #expect(card.displayName == "Charizard #4")
    }

    @Test("Display name with long card number")
    func displayNameLongNumber() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "025/165",
            setName: "Base Set",
            marketValue: 50.0
        )

        #expect(card.displayName == "Pikachu #025/165")
    }

    // MARK: - Edge Case Tests

    @Test("Very large market value")
    func veryLargeMarketValue() {
        let card = InventoryCard(
            cardName: "Pikachu Illustrator",
            cardNumber: "1",
            setName: "Promo",
            marketValue: 5_000_000.0,
            purchaseCost: 2_000_000.0
        )

        #expect(card.profit == 3_000_000.0)
        #expect(card.profitMargin == 1.5)
        #expect(card.roi == 150.0)
    }

    @Test("Very small values")
    func verySmallValues() {
        let card = InventoryCard(
            cardName: "Common Card",
            cardNumber: "100",
            setName: "Recent Set",
            marketValue: 0.25,
            purchaseCost: 0.10
        )

        #expect(card.profit == 0.15)
        #expect(card.profitMargin == 1.5)
        #expect(card.roi == 150.0)
    }

    @Test("Zero market value with purchase cost")
    func zeroMarketValue() {
        let card = InventoryCard(
            cardName: "Damaged Card",
            cardNumber: "50",
            setName: "Old Set",
            marketValue: 0.0,
            purchaseCost: 10.0
        )

        #expect(card.profit == -10.0)
        #expect(card.profitMargin == -1.0)
        #expect(card.roi == -100.0)
    }

    // MARK: - Tag Management Tests

    @Test("Empty tags by default")
    func emptyTags() {
        let card = InventoryCard(
            cardName: "Pikachu",
            cardNumber: "25",
            setName: "Base Set",
            marketValue: 50.0
        )

        #expect(card.tags.isEmpty)
    }

    @Test("Multiple tags")
    func multipleTags() {
        let card = InventoryCard(
            cardName: "Charizard",
            cardNumber: "4",
            setName: "Base Set",
            marketValue: 500.0,
            tags: ["High Value", "Holo", "Featured", "First Edition"]
        )

        #expect(card.tags.count == 4)
        #expect(card.tags.contains("High Value"))
        #expect(card.tags.contains("First Edition"))
    }
}
