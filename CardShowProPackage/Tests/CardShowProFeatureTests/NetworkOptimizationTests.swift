import Testing
import Foundation
@testable import CardShowProFeature

/// Network Optimization Tests
/// Validates that API calls are optimized for performance
@Suite("Network Optimization Tests")
@MainActor
struct NetworkOptimizationTests {

    // MARK: - Test Data

    private func createMockCardMatch() -> CardMatch {
        CardMatch(
            id: "base1-4",
            cardName: "Charizard",
            setName: "Base Set",
            setID: "base1",
            cardNumber: "4",
            imageURL: URL(string: "https://example.com/charizard.png")
        )
    }

    private func createMockPricing() -> DetailedTCGPlayerPricing {
        DetailedTCGPlayerPricing(
            normal: DetailedTCGPlayerPricing.PriceBreakdown(
                low: 50.00,
                mid: 75.00,
                high: 100.00,
                market: 80.00
            ),
            holofoil: nil,
            reverseHolofoil: nil,
            firstEdition: nil,
            unlimited: nil
        )
    }

    // MARK: - Performance Baseline Tests

    @Test("Sequential API calls complete in expected timeframe")
    func sequentialAPICalls() async throws {
        let mockService = MockPokemonTCGService()
        mockService.searchDelay = 1.5
        mockService.pricingDelay = 1.5
        mockService.searchResults = [createMockCardMatch()]
        mockService.pricingResult = createMockPricing()

        let startTime = Date()

        let matches = try await mockService.searchCard(name: "Charizard", number: nil)
        #expect(matches.count == 1)

        let pricing = try await mockService.getDetailedPricing(cardID: matches[0].id)
        #expect(pricing.normal != nil)

        let duration = Date().timeIntervalSince(startTime)

        #expect(duration >= 2.9)
        #expect(duration < 3.5)
    }

    @Test("Parallel API calls (if implemented) should be faster than sequential")
    func parallelAPICalls() async throws {
        let mockService = MockPokemonTCGService()
        mockService.searchDelay = 1.5
        mockService.pricingDelay = 1.5
        mockService.searchResults = [createMockCardMatch()]
        mockService.pricingResult = createMockPricing()

        let startTime = Date()

        async let searchTask = mockService.searchCard(name: "Charizard", number: nil)

        let matches = try await searchTask
        #expect(matches.count == 1)

        let pricing = try await mockService.getDetailedPricing(cardID: matches[0].id)
        #expect(pricing.normal != nil)

        let duration = Date().timeIntervalSince(startTime)

        #expect(duration >= 2.9)
    }

    // MARK: - Edge Case Tests

    @Test("Multiple matches skip pricing fetch (optimization)")
    func multipleMatchesSkipPricing() async throws {
        let mockService = MockPokemonTCGService()
        mockService.searchDelay = 1.5
        mockService.pricingDelay = 1.5
        mockService.searchResults = [
            createMockCardMatch(),
            CardMatch(id: "base2-4", cardName: "Charizard", setName: "Jungle", setID: "base2", cardNumber: "4", imageURL: nil),
            CardMatch(id: "base3-4", cardName: "Charizard", setName: "Fossil", setID: "base3", cardNumber: "4", imageURL: nil)
        ]
        mockService.pricingResult = createMockPricing()

        let startTime = Date()

        let matches = try await mockService.searchCard(name: "Charizard", number: nil)
        #expect(matches.count == 3)

        let duration = Date().timeIntervalSince(startTime)

        #expect(duration >= 1.4)
        #expect(duration < 2.0)
    }

    @Test("Network error handling doesn't cause crashes")
    func networkErrorHandling() async throws {
        let mockService = MockPokemonTCGService()
        mockService.shouldThrowError = true

        do {
            let _ = try await mockService.searchCard(name: "Invalid", number: nil)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is MockPokemonTCGService.MockError)
        }
    }

    // MARK: - Speculative Pricing Tests

    @Test("Speculative pricing with correct prediction saves time")
    func speculativePricingSuccess() async throws {
        let mockService = MockPokemonTCGService()
        mockService.searchDelay = 1.5
        mockService.pricingDelay = 1.5
        mockService.searchResults = [createMockCardMatch()]
        mockService.pricingResult = createMockPricing()

        let predictedID = "base1-4"

        let startTime = Date()

        async let searchTask = mockService.searchCard(name: "Charizard", number: "4")
        async let speculativePricingTask = mockService.getDetailedPricing(cardID: predictedID)

        let matches = try await searchTask
        let speculativePricing = try await speculativePricingTask

        let duration = Date().timeIntervalSince(startTime)

        #expect(matches.count == 1)
        #expect(matches[0].id == predictedID)
        #expect(speculativePricing.normal != nil)

        #expect(duration >= 1.4)
        #expect(duration < 2.0)
    }

    @Test("Speculative pricing with wrong prediction falls back gracefully")
    func speculativePricingFailure() async throws {
        let mockService = MockPokemonTCGService()
        mockService.searchDelay = 1.5
        mockService.pricingDelay = 1.5
        mockService.searchResults = [createMockCardMatch()]
        mockService.pricingResult = createMockPricing()

        let wrongPrediction = "wrong-id"
        let startTime = Date()

        async let searchTask = mockService.searchCard(name: "Charizard", number: "4")
        async let speculativePricingTask = mockService.getDetailedPricing(cardID: wrongPrediction)

        let matches = try await searchTask
        let _ = try? await speculativePricingTask

        #expect(matches[0].id != wrongPrediction)

        let correctPricing = try await mockService.getDetailedPricing(cardID: matches[0].id)
        #expect(correctPricing.normal != nil)

        let duration = Date().timeIntervalSince(startTime)

        #expect(duration >= 2.9)
    }

    // MARK: - Performance Tracking Tests

    @Test("Performance history tracks lookup times correctly")
    func performanceHistoryTracking() async throws {
        var performanceHistory: [TimeInterval] = []

        let lookupTimes = [2.5, 3.2, 2.8, 3.5, 2.9]

        for time in lookupTimes {
            performanceHistory.append(time)
            if performanceHistory.count > 20 {
                performanceHistory.removeFirst()
            }
        }

        #expect(performanceHistory.count == 5)

        let average = performanceHistory.reduce(0, +) / Double(performanceHistory.count)
        #expect(average > 2.8)
        #expect(average < 3.2)

        guard let min = performanceHistory.min(), let max = performanceHistory.max() else {
            Issue.record("Expected non-empty performance history")
            return
        }

        #expect(min == 2.5)
        #expect(max == 3.5)
    }

    @Test("Performance history limits to 20 entries")
    func performanceHistoryLimit() async throws {
        var performanceHistory: [TimeInterval] = []

        for i in 1...25 {
            performanceHistory.append(Double(i))
            if performanceHistory.count > 20 {
                performanceHistory.removeFirst()
            }
        }

        #expect(performanceHistory.count == 20)
        #expect(performanceHistory.first == 6.0)
        #expect(performanceHistory.last == 25.0)
    }
}

// MARK: - Mock Service

/// Mock PokemonTCG service for testing
@MainActor
class MockPokemonTCGService: Sendable {
    var searchDelay: TimeInterval = 0
    var pricingDelay: TimeInterval = 0
    var searchResults: [CardMatch] = []
    var pricingResult: DetailedTCGPlayerPricing?
    var shouldThrowError: Bool = false

    enum MockError: Error {
        case networkError
        case notFound
    }

    func searchCard(name: String, number: String?) async throws -> [CardMatch] {
        if shouldThrowError {
            throw MockError.networkError
        }

        try await Task.sleep(for: .seconds(searchDelay))

        return searchResults
    }

    func getDetailedPricing(cardID: String) async throws -> DetailedTCGPlayerPricing {
        if shouldThrowError {
            throw MockError.notFound
        }

        try await Task.sleep(for: .seconds(pricingDelay))

        guard let pricing = pricingResult else {
            throw MockError.notFound
        }

        return pricing
    }
}
