import Testing
import Foundation
@testable import CardShowProFeature

@Suite("Price Cache Tests")
@MainActor
struct PriceCacheTests {
    let repository: PriceCacheRepository

    init() {
        repository = PriceCacheRepository()
    }

    @Test("Create and fetch cached price")
    func createAndFetch() async throws {
        let price = CachedPrice(
            cardID: "base1-4",
            cardName: "Charizard",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "4/102",
            marketPrice: 500.00
        )

        try repository.savePrice(price)

        let fetched = try repository.getPrice(cardID: "base1-4")

        #expect(fetched != nil)
        #expect(fetched?.cardName == "Charizard")
        #expect(fetched?.marketPrice == 500.00)
    }

    @Test("Freshness calculated correctly for new entry")
    func freshnessForNewEntry() async throws {
        let freshPrice = CachedPrice(
            cardID: "test-1",
            cardName: "Test Card",
            setName: "Test Set",
            setID: "test",
            cardNumber: "1"
        )

        #expect(freshPrice.isFresh == true)
        #expect(freshPrice.isStale == false)
        #expect(freshPrice.ageInHours < 1)
    }

    @Test("Save and retrieve multiple prices")
    func saveAndRetrieveMultiple() async throws {
        let cards = [
            CachedPrice(cardID: "xy1-1", cardName: "Charizard", setName: "XY", setID: "xy1", cardNumber: "1"),
            CachedPrice(cardID: "xy1-2", cardName: "Pikachu", setName: "XY", setID: "xy1", cardNumber: "2"),
            CachedPrice(cardID: "xy1-3", cardName: "Charmander", setName: "XY", setID: "xy1", cardNumber: "3")
        ]

        for card in cards {
            try repository.savePrice(card)
        }

        let char = try repository.getPrice(cardID: "xy1-1")
        let pika = try repository.getPrice(cardID: "xy1-2")
        let charm = try repository.getPrice(cardID: "xy1-3")

        #expect(char?.cardName == "Charizard")
        #expect(pika?.cardName == "Pikachu")
        #expect(charm?.cardName == "Charmander")
    }

    @Test("Overwrite existing price")
    func overwritePrice() async throws {
        let original = CachedPrice(
            cardID: "test-update",
            cardName: "Test Card",
            setName: "Test",
            setID: "test",
            cardNumber: "1",
            marketPrice: 50.00
        )
        try repository.savePrice(original)

        let updated = CachedPrice(
            cardID: "test-update",
            cardName: "Test Card",
            setName: "Test",
            setID: "test",
            cardNumber: "1",
            marketPrice: 75.00
        )
        try repository.savePrice(updated)

        let fetched = try repository.getPrice(cardID: "test-update")

        #expect(fetched?.marketPrice == 75.00)
    }

    @Test("Missing price returns nil")
    func missingPriceReturnsNil() async throws {
        let result = try repository.getPrice(cardID: "nonexistent")

        #expect(result == nil)
    }

    @Test("Clear all cached prices")
    func clearAllPrices() async throws {
        for i in 1...5 {
            let card = CachedPrice(
                cardID: "clear-\(i)",
                cardName: "Card \(i)",
                setName: "Test",
                setID: "test",
                cardNumber: "\(i)"
            )
            try repository.savePrice(card)
        }

        // Verify they exist
        #expect(try repository.getPrice(cardID: "clear-1") != nil)

        // Clear all
        repository.clearAll()

        // Verify all gone
        #expect(try repository.getPrice(cardID: "clear-1") == nil)
        #expect(try repository.getPrice(cardID: "clear-5") == nil)
    }

    @Test("Condition prices can be set on cached price")
    func conditionPricesCanBeSet() async throws {
        let price = CachedPrice(
            cardID: "cond-test",
            cardName: "Test",
            setName: "Test",
            setID: "test",
            cardNumber: "1",
            marketPrice: 100.00
        )

        #expect(price.conditionPrices == nil)

        let conditions = ConditionPrices(
            nearMint: 100.00,
            lightlyPlayed: 85.00,
            moderatelyPlayed: 70.00,
            heavilyPlayed: 50.00,
            damaged: 30.00
        )
        price.setConditionPrices(conditions)

        #expect(price.conditionPrices != nil)
        #expect(price.conditionPrices?.nearMint == 100.00)
        #expect(price.conditionPrices?.lightlyPlayed == 85.00)
    }

    @Test("Price history can be set on cached price")
    func priceHistoryCanBeSet() async throws {
        let price = CachedPrice(
            cardID: "hist-test",
            cardName: "Test",
            setName: "Test",
            setID: "test",
            cardNumber: "1"
        )

        #expect(price.priceHistory == nil)

        let history = [
            PricePoint(p: 90.00, t: Int(Date().addingTimeInterval(-86400).timeIntervalSince1970)),
            PricePoint(p: 100.00, t: Int(Date().timeIntervalSince1970))
        ]
        price.setPriceHistory(history)

        #expect(price.priceHistory?.count == 2)
    }

    @Test("CachedPrice stores all price tiers")
    func allPriceTiersStored() async throws {
        let price = CachedPrice(
            cardID: "tiers-test",
            cardName: "Test",
            setName: "Test",
            setID: "test",
            cardNumber: "1",
            marketPrice: 100.00,
            lowPrice: 80.00,
            midPrice: 95.00,
            highPrice: 120.00
        )

        #expect(price.marketPrice == 100.00)
        #expect(price.lowPrice == 80.00)
        #expect(price.midPrice == 95.00)
        #expect(price.highPrice == 120.00)
    }
}
