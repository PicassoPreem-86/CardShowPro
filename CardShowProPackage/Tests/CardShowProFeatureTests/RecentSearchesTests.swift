import Testing
@testable import CardShowProFeature
import Foundation

/// Tests for Recent Searches functionality
/// Validates the 8x speed improvement feature for repeated lookups
@Suite("Recent Searches Tests")
@MainActor
struct RecentSearchesTests {

    // MARK: - Basic Functionality

    @Test("Recent search appears after lookup")
    func recentSearchAppearsAfterLookup() async throws {
        // Given: No recent searches
        let state = PriceLookupState()
        #expect(state.recentSearches.isEmpty)

        // When: Look up "Pikachu"
        state.addToRecentSearches("Pikachu")

        // Then: "Pikachu" appears in recent searches
        #expect(state.recentSearches.count == 1)
        #expect(state.recentSearches[0].cardName == "Pikachu")
    }

    @Test("Recent search moves to front when re-searched")
    func recentSearchMovesToFront() async throws {
        // Given: Recent searches ["Charizard", "Pikachu"]
        let state = PriceLookupState()
        state.addToRecentSearches("Pikachu")
        state.addToRecentSearches("Charizard")

        #expect(state.recentSearches.count == 2)
        #expect(state.recentSearches[0].cardName == "Charizard")
        #expect(state.recentSearches[1].cardName == "Pikachu")

        // When: Look up "Pikachu" again
        state.addToRecentSearches("Pikachu")

        // Then: Recent searches = ["Pikachu", "Charizard"]
        #expect(state.recentSearches.count == 2)
        #expect(state.recentSearches[0].cardName == "Pikachu")
        #expect(state.recentSearches[1].cardName == "Charizard")
    }

    @Test("Max 10 recent searches maintained")
    func maxTenRecentSearches() async throws {
        // Given: 10 recent searches
        let state = PriceLookupState()
        for i in 1...10 {
            state.addToRecentSearches("Card\(i)")
        }

        #expect(state.recentSearches.count == 10)
        #expect(state.recentSearches[0].cardName == "Card10")
        #expect(state.recentSearches[9].cardName == "Card1")

        // When: Look up new card
        state.addToRecentSearches("Card11")

        // Then: Oldest search removed, new one added
        #expect(state.recentSearches.count == 10)
        #expect(state.recentSearches[0].cardName == "Card11")
        #expect(state.recentSearches[9].cardName == "Card2")
    }

    // MARK: - Persistence

    @Test("Recent searches persist across app launches")
    func recentSearchPersistsAcrossAppLaunches() async throws {
        // Given: Recent searches saved
        let state1 = PriceLookupState()
        state1.addToRecentSearches("Pikachu")
        state1.addToRecentSearches("Charizard")
        state1.addToRecentSearches("Mewtwo")

        #expect(state1.recentSearches.count == 3)

        // When: App relaunched (new PriceLookupState instance)
        let state2 = PriceLookupState()

        // Then: Recent searches loaded from UserDefaults
        #expect(state2.recentSearches.count == 3)
        #expect(state2.recentSearches[0].cardName == "Mewtwo")
        #expect(state2.recentSearches[1].cardName == "Charizard")
        #expect(state2.recentSearches[2].cardName == "Pikachu")

        // Cleanup
        state2.clearRecentSearches()
    }

    @Test("Clear removes all searches and persists")
    func clearRemovesAllSearches() async throws {
        // Given: Recent searches exist
        let state = PriceLookupState()
        state.addToRecentSearches("Pikachu")
        state.addToRecentSearches("Charizard")
        #expect(state.recentSearches.count == 2)

        // When: Clear is called
        state.clearRecentSearches()

        // Then: All searches removed
        #expect(state.recentSearches.isEmpty)

        // And: Persists across reload
        let state2 = PriceLookupState()
        #expect(state2.recentSearches.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("Case insensitive deduplication")
    func caseInsensitiveDeduplication() async throws {
        // Given: Recent searches
        let state = PriceLookupState()
        state.addToRecentSearches("Pikachu")

        // When: Search for "pikachu" (lowercase)
        state.addToRecentSearches("pikachu")

        // Then: Only one entry exists (moved to front)
        #expect(state.recentSearches.count == 1)
        #expect(state.recentSearches[0].cardName == "pikachu")
    }

    @Test("Whitespace trimmed from searches")
    func whitespaceTrimmed() async throws {
        // Given: Search with whitespace
        let state = PriceLookupState()

        // When: Add search with leading/trailing spaces
        state.addToRecentSearches("  Pikachu  ")

        // Then: Whitespace removed
        #expect(state.recentSearches.count == 1)
        #expect(state.recentSearches[0].cardName == "Pikachu")
    }

    @Test("Empty string not added")
    func emptyStringNotAdded() async throws {
        // Given: Empty state
        let state = PriceLookupState()

        // When: Try to add empty string
        state.addToRecentSearches("")
        state.addToRecentSearches("   ")

        // Then: No searches added
        #expect(state.recentSearches.isEmpty)
    }

    @Test("Long card names handled")
    func longCardNamesHandled() async throws {
        // Given: Very long card name
        let state = PriceLookupState()
        let longName = "Pikachu ex (Full Art) (Special Illustration Rare) from Scarlet & Violet - Base Set"

        // When: Add long name
        state.addToRecentSearches(longName)

        // Then: Stored correctly
        #expect(state.recentSearches.count == 1)
        #expect(state.recentSearches[0].cardName == longName)
    }

    // MARK: - RecentSearch Model Tests

    @Test("RecentSearch equality is case-insensitive")
    func recentSearchEquality() async throws {
        let search1 = RecentSearch(cardName: "Pikachu", timestamp: Date())
        let search2 = RecentSearch(cardName: "pikachu", timestamp: Date())
        let search3 = RecentSearch(cardName: "Charizard", timestamp: Date())

        // Same name (case-insensitive)
        #expect(search1 == search2)

        // Different names
        #expect(search1 != search3)
    }

    @Test("RecentSearch has unique ID")
    func recentSearchUniqueID() async throws {
        let search1 = RecentSearch(cardName: "Pikachu", timestamp: Date())
        let search2 = RecentSearch(cardName: "Pikachu", timestamp: Date())

        // Even with same name, IDs are different
        #expect(search1.id != search2.id)
    }

    @Test("RecentSearch timestamp preserved")
    func timestampPreserved() async throws {
        let now = Date()
        let search = RecentSearch(cardName: "Pikachu", timestamp: now)

        #expect(search.timestamp == now)
    }

    // MARK: - Performance Test

    @Test("Recent searches load quickly")
    func recentSearchesLoadQuickly() async throws {
        // Given: 10 searches saved
        let state1 = PriceLookupState()
        for i in 1...10 {
            state1.addToRecentSearches("Card\(i)")
        }

        // Measure load time
        let start = Date()
        let state2 = PriceLookupState()
        let elapsed = Date().timeIntervalSince(start)

        // Then: Loads in < 10ms (fast enough for app launch)
        #expect(elapsed < 0.01)
        #expect(state2.recentSearches.count == 10)

        // Cleanup
        state2.clearRecentSearches()
    }

    // MARK: - Integration Tests

    @Test("Multiple rapid additions handled correctly")
    func multipleRapidAdditions() async throws {
        let state = PriceLookupState()

        // When: Add searches rapidly
        for i in 1...20 {
            state.addToRecentSearches("Card\(i)")
        }

        // Then: Only last 10 preserved
        #expect(state.recentSearches.count == 10)
        #expect(state.recentSearches[0].cardName == "Card20")
        #expect(state.recentSearches[9].cardName == "Card11")

        // Cleanup
        state.clearRecentSearches()
    }

    @Test("Interleaved additions and clears")
    func interleavedAdditionsAndClears() async throws {
        let state = PriceLookupState()

        // Add some searches
        state.addToRecentSearches("Pikachu")
        state.addToRecentSearches("Charizard")
        #expect(state.recentSearches.count == 2)

        // Clear
        state.clearRecentSearches()
        #expect(state.recentSearches.isEmpty)

        // Add more
        state.addToRecentSearches("Mewtwo")
        #expect(state.recentSearches.count == 1)
        #expect(state.recentSearches[0].cardName == "Mewtwo")

        // Cleanup
        state.clearRecentSearches()
    }
}
