import Testing
import Foundation
@testable import CardShowProFeature

/// Integration tests for price cache functionality
/// Tests the full cache workflow: miss → API → save → hit
@MainActor
@Suite("Price Cache Integration Tests")
struct PriceCacheIntegrationTests {

    // MARK: - Cache Hit Tests

    @Test("Cache hit returns instantly for fresh data")
    func cacheHitReturnsInstantly() async throws {
        let repository = PriceCacheRepository()

        let cachedPrice = CachedPrice(
            cardID: "base1-25",
            cardName: "Pikachu",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "25",
            marketPrice: 15.50,
            lowPrice: 10.00,
            midPrice: 14.00,
            highPrice: 20.00
        )

        try repository.savePrice(cachedPrice)

        let startTime = Date()
        let result = try repository.getPrice(cardID: "base1-25")
        let duration = Date().timeIntervalSince(startTime)

        #expect(duration < 0.1)
        #expect(result != nil)
        #expect(result?.cardName == "Pikachu")
        #expect(result?.marketPrice == 15.50)
        #expect(result?.isFresh == true)
    }

    @Test("Cache miss returns nil then hit after save")
    func cacheMissSavesAndRetrievesData() async throws {
        let repository = PriceCacheRepository()

        let result1 = try repository.getPrice(cardID: "base1-4")
        #expect(result1 == nil)

        let charizard = CachedPrice(
            cardID: "base1-4",
            cardName: "Charizard",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "4",
            marketPrice: 350.00,
            lowPrice: 250.00,
            midPrice: 320.00,
            highPrice: 450.00
        )

        try repository.savePrice(charizard)

        let result2 = try repository.getPrice(cardID: "base1-4")
        #expect(result2 != nil)
        #expect(result2?.cardName == "Charizard")
        #expect(result2?.marketPrice == 350.00)
    }

    // MARK: - Performance Tests

    @Test("Cache provides 10x+ speed improvement over simulated API")
    func cacheProvidesMajorSpeedImprovement() async throws {
        let repository = PriceCacheRepository()

        let cachedPrice = CachedPrice(
            cardID: "base1-25",
            cardName: "Pikachu",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "25",
            marketPrice: 15.50
        )
        try repository.savePrice(cachedPrice)

        let cacheStart = Date()
        let _ = try repository.getPrice(cardID: "base1-25")
        let cacheDuration = Date().timeIntervalSince(cacheStart)

        let apiStart = Date()
        try await Task.sleep(for: .milliseconds(100))
        let apiDuration = Date().timeIntervalSince(apiStart)

        #expect(cacheDuration < 0.01)
        #expect(apiDuration > 0.1)
        #expect(apiDuration / max(cacheDuration, 0.000001) > 10)
    }

    @Test("Multiple sequential lookups demonstrate cache benefit")
    func multipleLookupsShowCacheBenefit() async throws {
        let repository = PriceCacheRepository()

        let cards = [
            ("base1-25", "Pikachu", 15.50),
            ("base1-4", "Charizard", 350.00),
            ("base1-1", "Alakazam", 45.00),
            ("base1-2", "Blastoise", 120.00),
            ("base1-15", "Venusaur", 95.00)
        ]

        for (id, name, price) in cards {
            let cached = CachedPrice(
                cardID: id,
                cardName: name,
                setName: "Base Set",
                setID: "base1",
                cardNumber: String(id.split(separator: "-")[1]),
                marketPrice: price
            )
            try repository.savePrice(cached)
        }

        let startTime = Date()
        for _ in 0..<3 {
            for (id, _, _) in cards {
                let _ = try repository.getPrice(cardID: id)
            }
        }
        let totalDuration = Date().timeIntervalSince(startTime)

        #expect(totalDuration < 0.1)
    }

    // MARK: - Data Integrity Tests

    @Test("Cached prices maintain data integrity")
    func cachedPricesMaintainDataIntegrity() async throws {
        let repository = PriceCacheRepository()

        let originalPrice = CachedPrice(
            cardID: "base1-25",
            cardName: "Pikachu",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "25",
            marketPrice: 15.50,
            lowPrice: 10.00,
            midPrice: 14.00,
            highPrice: 20.00,
            imageURLSmall: "https://example.com/pikachu-small.png",
            imageURLLarge: "https://example.com/pikachu-large.png"
        )

        try repository.savePrice(originalPrice)

        let retrieved = try repository.getPrice(cardID: "base1-25")

        #expect(retrieved?.cardID == "base1-25")
        #expect(retrieved?.cardName == "Pikachu")
        #expect(retrieved?.setName == "Base Set")
        #expect(retrieved?.setID == "base1")
        #expect(retrieved?.cardNumber == "25")
        #expect(retrieved?.marketPrice == 15.50)
        #expect(retrieved?.lowPrice == 10.00)
        #expect(retrieved?.midPrice == 14.00)
        #expect(retrieved?.highPrice == 20.00)
        #expect(retrieved?.imageURLSmall == "https://example.com/pikachu-small.png")
        #expect(retrieved?.imageURLLarge == "https://example.com/pikachu-large.png")
    }

    // MARK: - Cache Management Tests

    @Test("Clear all removes everything")
    func clearAllRemovesEverything() async throws {
        let repository = PriceCacheRepository()

        let cards = [
            CachedPrice(cardID: "base1-25", cardName: "Pikachu", setName: "Base Set", setID: "base1", cardNumber: "25"),
            CachedPrice(cardID: "base1-26", cardName: "Raichu", setName: "Base Set", setID: "base1", cardNumber: "26"),
            CachedPrice(cardID: "base1-4", cardName: "Charizard", setName: "Base Set", setID: "base1", cardNumber: "4")
        ]

        for card in cards {
            try repository.savePrice(card)
        }

        #expect(try repository.getPrice(cardID: "base1-25") != nil)

        repository.clearAll()

        #expect(try repository.getPrice(cardID: "base1-25") == nil)
        #expect(try repository.getPrice(cardID: "base1-26") == nil)
        #expect(try repository.getPrice(cardID: "base1-4") == nil)
    }

    @Test("Overwriting price replaces old data")
    func overwritingPriceReplacesOldData() async throws {
        let repository = PriceCacheRepository()

        let original = CachedPrice(
            cardID: "base1-25",
            cardName: "Pikachu",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "25",
            marketPrice: 15.50
        )
        try repository.savePrice(original)

        let updated = CachedPrice(
            cardID: "base1-25",
            cardName: "Pikachu",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "25",
            marketPrice: 18.00
        )
        try repository.savePrice(updated)

        let result = try repository.getPrice(cardID: "base1-25")
        #expect(result?.marketPrice == 18.00)
    }
}
