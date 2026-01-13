import Testing
import SwiftData
@testable import CardShowProFeature

@Suite("Price Cache Tests")
@MainActor
struct PriceCacheTests {
    let container: ModelContainer
    let context: ModelContext
    let repository: PriceCacheRepository

    init() {
        // Create in-memory container for testing
        let schema = Schema([CachedPrice.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        repository = PriceCacheRepository(modelContext: context)
    }

    @Test("Create and fetch cached price")
    func createAndFetch() async throws {
        // Create test price
        let price = CachedPrice(
            cardID: "base1-4",
            cardName: "Charizard",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "4/102",
            marketPrice: 500.00
        )

        try repository.savePrice(price)

        // Fetch it back
        let fetched = try repository.getPrice(cardID: "base1-4")

        #expect(fetched != nil)
        #expect(fetched?.cardName == "Charizard")
        #expect(fetched?.marketPrice == 500.00)
    }

    @Test("Freshness levels calculated correctly")
    func freshnessLevels() async throws {
        // Create fresh price (<1 hour)
        let freshPrice = CachedPrice(
            cardID: "test-1",
            cardName: "Test Card",
            setName: "Test Set",
            setID: "test",
            cardNumber: "1"
        )
        #expect(freshPrice.freshnessLevel == .fresh)
        #expect(freshPrice.isStale == false)

        // Create stale price (25 hours old)
        let stalePrice = CachedPrice(
            cardID: "test-2",
            cardName: "Old Card",
            setName: "Test Set",
            setID: "test",
            cardNumber: "2"
        )
        stalePrice.lastUpdated = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!

        #expect(stalePrice.isStale == true)
        #expect(stalePrice.freshnessLevel == .stale)
    }

    @Test("Search cached prices by name")
    func searchByName() async throws {
        // Add multiple cards
        let cards = [
            CachedPrice(cardID: "xy1-1", cardName: "Charizard", setName: "XY", setID: "xy1", cardNumber: "1"),
            CachedPrice(cardID: "xy1-2", cardName: "Pikachu", setName: "XY", setID: "xy1", cardNumber: "2"),
            CachedPrice(cardID: "xy1-3", cardName: "Charmander", setName: "XY", setID: "xy1", cardNumber: "3")
        ]

        for card in cards {
            try repository.savePrice(card)
        }

        // Search for "Char"
        let results = try repository.searchPrices(query: "Char")

        #expect(results.count == 2) // Charizard and Charmander
        #expect(results.contains { $0.cardName == "Charizard" })
        #expect(results.contains { $0.cardName == "Charmander" })
    }

    @Test("Update price refreshes timestamp")
    func updatePrice() async throws {
        // Create initial price
        let price = CachedPrice(
            cardID: "test-update",
            cardName: "Test Card",
            setName: "Test",
            setID: "test",
            cardNumber: "1",
            marketPrice: 50.00
        )
        try repository.savePrice(price)

        let originalTimestamp = price.lastUpdated

        // Wait a moment
        try await Task.sleep(for: .milliseconds(100))

        // Update price
        try repository.refreshPrice(
            cardID: "test-update",
            newMarketPrice: 75.00,
            newLowPrice: 70.00,
            newMidPrice: 72.50,
            newHighPrice: 80.00
        )

        // Fetch updated price
        let updated = try repository.getPrice(cardID: "test-update")

        #expect(updated?.marketPrice == 75.00)
        #expect(updated?.lastUpdated > originalTimestamp)
    }

    @Test("Delete cached price")
    func deletePrice() async throws {
        // Create and save price
        let price = CachedPrice(
            cardID: "delete-test",
            cardName: "Delete Me",
            setName: "Test",
            setID: "test",
            cardNumber: "1"
        )
        try repository.savePrice(price)

        // Verify it exists
        let exists = try repository.getPrice(cardID: "delete-test")
        #expect(exists != nil)

        // Delete it
        try repository.deletePrice(cardID: "delete-test")

        // Verify it's gone
        let deleted = try repository.getPrice(cardID: "delete-test")
        #expect(deleted == nil)
    }

    @Test("Cache statistics calculation")
    func cacheStats() async throws {
        // Add 10 cards (5 fresh, 5 stale)
        for i in 1...10 {
            let card = CachedPrice(
                cardID: "stats-\(i)",
                cardName: "Card \(i)",
                setName: "Test",
                setID: "test",
                cardNumber: "\(i)"
            )

            // Make half of them stale (>24 hours)
            if i > 5 {
                card.lastUpdated = Calendar.current.date(byAdding: .hour, value: -30, to: Date())!
            }

            try repository.savePrice(card)
        }

        // Get statistics
        let stats = try repository.getCacheStats()

        #expect(stats.totalCards == 10)
        #expect(stats.freshCards == 5)
        #expect(stats.staleCards == 5)
        #expect(stats.stalePercentage == 50.0)
        #expect(stats.freshPercentage == 50.0)
    }

    @Test("Clear all cached prices")
    func clearAll() async throws {
        // Add some cards
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
        let before = try repository.getAllPrices()
        #expect(before.count >= 5)

        // Clear all
        try repository.clearAll()

        // Verify all gone
        let after = try repository.getAllPrices()
        #expect(after.count == 0)
    }

    @Test("Stale prices detected correctly")
    func stalePriceDetection() async throws {
        // Add fresh card
        let freshCard = CachedPrice(
            cardID: "fresh-card",
            cardName: "Fresh Card",
            setName: "Test",
            setID: "test",
            cardNumber: "1"
        )
        try repository.savePrice(freshCard)

        // Add stale card (30 hours old)
        let staleCard = CachedPrice(
            cardID: "stale-card",
            cardName: "Stale Card",
            setName: "Test",
            setID: "test",
            cardNumber: "2"
        )
        staleCard.lastUpdated = Calendar.current.date(byAdding: .hour, value: -30, to: Date())!
        try repository.savePrice(staleCard)

        // Fetch stale prices
        let stalePrices = try repository.getStalePrices(olderThanHours: 24)

        #expect(stalePrices.count == 1)
        #expect(stalePrices.first?.cardID == "stale-card")
    }
}
