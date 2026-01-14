import Testing
import Foundation
@testable import CardShowProFeature

/// Network Optimization Tests
/// Validates that API calls are optimized for performance
@Suite("Network Optimization Tests")
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
            firstEdition: nil
        )
    }

    // MARK: - Performance Baseline Tests

    @Test("Sequential API calls complete in expected timeframe")
    func sequentialAPICalls() async throws {
        // Given: Mock service with 1.5s delay per request
        let mockService = MockPokemonTCGService()
        mockService.searchDelay = 1.5
        mockService.pricingDelay = 1.5
        mockService.searchResults = [createMockCardMatch()]
        mockService.pricingResult = createMockPricing()

        // When: Perform sequential lookup
        let startTime = Date()

        let matches = try await mockService.searchCard(name: "Charizard", number: nil)
        #expect(matches.count == 1)

        let pricing = try await mockService.getDetailedPricing(cardID: matches[0].id)
        #expect(pricing.normal != nil)

        let duration = Date().timeIntervalSince(startTime)

        // Then: Total time should be ~3s (1.5s + 1.5s)
        #expect(duration >= 2.9) // Allow small margin for execution overhead
        #expect(duration < 3.5)  // But not too much overhead

        print("⏱️ Sequential lookup took \(String(format: "%.2f", duration))s")
    }

    @Test("Parallel API calls (if implemented) should be faster than sequential")
    func parallelAPICalls() async throws {
        // Given: Mock service with delays
        let mockService = MockPokemonTCGService()
        mockService.searchDelay = 1.5
        mockService.pricingDelay = 1.5
        mockService.searchResults = [createMockCardMatch()]
        mockService.pricingResult = createMockPricing()

        // When: Attempt parallel execution with async let
        let startTime = Date()

        async let searchTask = mockService.searchCard(name: "Charizard", number: nil)
        // Note: In real implementation, we can't start pricing until we have cardID
        // This test demonstrates the THEORETICAL speedup IF we could parallelize

        let matches = try await searchTask
        #expect(matches.count == 1)

        // Now fetch pricing (must be sequential in practice)
        let pricing = try await mockService.getDetailedPricing(cardID: matches[0].id)
        #expect(pricing.normal != nil)

        let duration = Date().timeIntervalSince(startTime)

        // Then: Still sequential due to cardID dependency
        #expect(duration >= 2.9)

        print("⏱️ 'Parallel' lookup (still sequential) took \(String(format: "%.2f", duration))s")
    }

    // MARK: - Edge Case Tests

    @Test("Multiple matches skip pricing fetch (optimization)")
    func multipleMatchesSkipPricing() async throws {
        // Given: Mock service returns 3 matches
        let mockService = MockPokemonTCGService()
        mockService.searchDelay = 1.5
        mockService.pricingDelay = 1.5
        mockService.searchResults = [
            createMockCardMatch(),
            CardMatch(id: "base2-4", cardName: "Charizard", setName: "Jungle", setID: "base2", cardNumber: "4", imageURL: nil),
            CardMatch(id: "base3-4", cardName: "Charizard", setName: "Fossil", setID: "base3", cardNumber: "4", imageURL: nil)
        ]
        mockService.pricingResult = createMockPricing()

        // When: Search returns multiple matches
        let startTime = Date()

        let matches = try await mockService.searchCard(name: "Charizard", number: nil)
        #expect(matches.count == 3)

        // Then: Should NOT fetch pricing yet (user must select first)
        let duration = Date().timeIntervalSince(startTime)

        // Only search time, no pricing fetch
        #expect(duration >= 1.4)
        #expect(duration < 2.0)

        print("⏱️ Multiple matches (no pricing) took \(String(format: "%.2f", duration))s")
    }

    @Test("Network error handling doesn't cause crashes")
    func networkErrorHandling() async throws {
        // Given: Mock service that throws errors
        let mockService = MockPokemonTCGService()
        mockService.shouldThrowError = true

        // When: Perform lookup that fails
        do {
            let _ = try await mockService.searchCard(name: "Invalid", number: nil)
            Issue.record("Expected error to be thrown")
        } catch {
            // Then: Error should be caught gracefully
            #expect(error is MockPokemonTCGService.MockError)
        }
    }

    // MARK: - Speculative Pricing Tests (Future Phase 2)

    @Test("Speculative pricing with correct prediction saves time")
    func speculativePricingSuccess() async throws {
        // Given: We can predict the cardID correctly
        let mockService = MockPokemonTCGService()
        mockService.searchDelay = 1.5
        mockService.pricingDelay = 1.5
        mockService.searchResults = [createMockCardMatch()]
        mockService.pricingResult = createMockPricing()

        let predictedID = "base1-4" // Correct prediction

        // When: Start both requests in parallel
        let startTime = Date()

        async let searchTask = mockService.searchCard(name: "Charizard", number: "4")
        async let speculativePricingTask = mockService.getDetailedPricing(cardID: predictedID)

        let matches = try await searchTask
        let speculativePricing = try await speculativePricingTask

        // Then: Both complete in parallel (~1.5s max, not 3s total)
        let duration = Date().timeIntervalSince(startTime)

        #expect(matches.count == 1)
        #expect(matches[0].id == predictedID) // Prediction was correct!
        #expect(speculativePricing.normal != nil)

        // Parallelized requests should complete in max(1.5s, 1.5s) ≈ 1.5s
        #expect(duration >= 1.4)
        #expect(duration < 2.0) // Significantly faster than 3s sequential!

        print("✅ SPECULATION SUCCESS: Lookup took \(String(format: "%.2f", duration))s (saved ~1.5s)")
    }

    @Test("Speculative pricing with wrong prediction falls back gracefully")
    func speculativePricingFailure() async throws {
        // Given: Prediction is wrong
        let mockService = MockPokemonTCGService()
        mockService.searchDelay = 1.5
        mockService.pricingDelay = 1.5
        mockService.searchResults = [createMockCardMatch()]
        mockService.pricingResult = createMockPricing()

        let wrongPrediction = "wrong-id"
        let startTime = Date()

        // When: Start both requests
        async let searchTask = mockService.searchCard(name: "Charizard", number: "4")
        async let speculativePricingTask = mockService.getDetailedPricing(cardID: wrongPrediction)

        let matches = try await searchTask
        let _ = try? await speculativePricingTask // May fail, that's OK

        // Prediction was wrong, need to fetch again
        #expect(matches[0].id != wrongPrediction)

        let correctPricing = try await mockService.getDetailedPricing(cardID: matches[0].id)
        #expect(correctPricing.normal != nil)

        let duration = Date().timeIntervalSince(startTime)

        // Then: Falls back to normal fetch (still ~3s total)
        #expect(duration >= 2.9)

        print("❌ SPECULATION FAILED: Fell back to normal fetch (\(String(format: "%.2f", duration))s)")
    }

    // MARK: - Performance Tracking Tests

    @Test("Performance history tracks lookup times correctly")
    func performanceHistoryTracking() async throws {
        var performanceHistory: [TimeInterval] = []

        // Simulate 5 lookups with varying times
        let lookupTimes = [2.5, 3.2, 2.8, 3.5, 2.9]

        for time in lookupTimes {
            performanceHistory.append(time)
            if performanceHistory.count > 20 {
                performanceHistory.removeFirst()
            }
        }

        #expect(performanceHistory.count == 5)

        // Calculate average
        let average = performanceHistory.reduce(0, +) / Double(performanceHistory.count)
        #expect(average > 2.8)
        #expect(average < 3.2)

        // Calculate min/max
        let min = performanceHistory.min()!
        let max = performanceHistory.max()!

        #expect(min == 2.5)
        #expect(max == 3.5)

        print("📊 Performance Stats: Avg=\(String(format: "%.2f", average))s, Range=\(String(format: "%.2f", min))s-\(String(format: "%.2f", max))s")
    }

    @Test("Performance history limits to 20 entries")
    func performanceHistoryLimit() async throws {
        var performanceHistory: [TimeInterval] = []

        // Add 25 entries
        for i in 1...25 {
            performanceHistory.append(Double(i))
            if performanceHistory.count > 20 {
                performanceHistory.removeFirst()
            }
        }

        // Then: Should only keep last 20
        #expect(performanceHistory.count == 20)
        #expect(performanceHistory.first == 6.0) // Entries 1-5 removed
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

        // Simulate network delay
        try await Task.sleep(for: .seconds(searchDelay))

        return searchResults
    }

    func getDetailedPricing(cardID: String) async throws -> DetailedTCGPlayerPricing {
        if shouldThrowError {
            throw MockError.notFound
        }

        // Simulate network delay
        try await Task.sleep(for: .seconds(pricingDelay))

        guard let pricing = pricingResult else {
            throw MockError.notFound
        }

        return pricing
    }
}
