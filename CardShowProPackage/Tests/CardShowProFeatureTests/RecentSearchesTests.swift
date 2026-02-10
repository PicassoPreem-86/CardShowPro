import Testing
@testable import CardShowProFeature
import Foundation

/// Tests for Recent Searches functionality
@Suite("Recent Searches Tests")
@MainActor
struct RecentSearchesTests {

    // MARK: - Basic Functionality

    @Test("Recent search appears after lookup")
    func recentSearchAppearsAfterLookup() async throws {
        let state = PriceLookupState()
        #expect(state.recentSearches.isEmpty)

        state.addToRecentSearches("Pikachu")

        #expect(state.recentSearches.count == 1)
        #expect(state.recentSearches[0].cardName == "Pikachu")
    }

    @Test("Recent search moves to front when re-searched")
    func recentSearchMovesToFront() async throws {
        let state = PriceLookupState()
        state.addToRecentSearches("Pikachu")
        state.addToRecentSearches("Charizard")

        #expect(state.recentSearches.count == 2)
        #expect(state.recentSearches[0].cardName == "Charizard")
        #expect(state.recentSearches[1].cardName == "Pikachu")

        state.addToRecentSearches("Pikachu")

        #expect(state.recentSearches.count == 2)
        #expect(state.recentSearches[0].cardName == "Pikachu")
        #expect(state.recentSearches[1].cardName == "Charizard")
    }

    @Test("Max 10 recent searches maintained")
    func maxTenRecentSearches() async throws {
        let state = PriceLookupState()
        for i in 1...10 {
            state.addToRecentSearches("Card\(i)")
        }

        #expect(state.recentSearches.count == 10)
        #expect(state.recentSearches[0].cardName == "Card10")
        #expect(state.recentSearches[9].cardName == "Card1")

        state.addToRecentSearches("Card11")

        #expect(state.recentSearches.count == 10)
        #expect(state.recentSearches[0].cardName == "Card11")
        #expect(state.recentSearches[9].cardName == "Card2")
    }

    // MARK: - Clear

    @Test("Clear removes all searches")
    func clearRemovesAllSearches() async throws {
        let state = PriceLookupState()
        state.addToRecentSearches("Pikachu")
        state.addToRecentSearches("Charizard")
        #expect(state.recentSearches.count == 2)

        state.clearRecentSearches()

        #expect(state.recentSearches.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("Case insensitive deduplication")
    func caseInsensitiveDeduplication() async throws {
        let state = PriceLookupState()
        state.addToRecentSearches("Pikachu")

        state.addToRecentSearches("pikachu")

        #expect(state.recentSearches.count == 1)
        #expect(state.recentSearches[0].cardName == "pikachu")
    }

    @Test("Whitespace trimmed from searches")
    func whitespaceTrimmed() async throws {
        let state = PriceLookupState()

        state.addToRecentSearches("  Pikachu  ")

        #expect(state.recentSearches.count == 1)
        #expect(state.recentSearches[0].cardName == "Pikachu")
    }

    @Test("Empty string not added")
    func emptyStringNotAdded() async throws {
        let state = PriceLookupState()

        state.addToRecentSearches("")
        state.addToRecentSearches("   ")

        #expect(state.recentSearches.isEmpty)
    }

    @Test("Long card names handled")
    func longCardNamesHandled() async throws {
        let state = PriceLookupState()
        let longName = "Pikachu ex (Full Art) (Special Illustration Rare) from Scarlet & Violet - Base Set"

        state.addToRecentSearches(longName)

        #expect(state.recentSearches.count == 1)
        #expect(state.recentSearches[0].cardName == longName)
    }

    // MARK: - RecentSearch Model Tests

    @Test("RecentSearch has unique ID")
    func recentSearchUniqueID() async throws {
        let search1 = RecentSearch(cardName: "Pikachu", timestamp: Date())
        let search2 = RecentSearch(cardName: "Pikachu", timestamp: Date())

        #expect(search1.id != search2.id)
    }

    @Test("RecentSearch timestamp preserved")
    func timestampPreserved() async throws {
        let now = Date()
        let search = RecentSearch(cardName: "Pikachu", timestamp: now)

        #expect(search.timestamp == now)
    }

    // MARK: - Integration Tests

    @Test("Multiple rapid additions handled correctly")
    func multipleRapidAdditions() async throws {
        let state = PriceLookupState()

        for i in 1...20 {
            state.addToRecentSearches("Card\(i)")
        }

        #expect(state.recentSearches.count == 10)
        #expect(state.recentSearches[0].cardName == "Card20")
        #expect(state.recentSearches[9].cardName == "Card11")
    }

    @Test("Interleaved additions and clears")
    func interleavedAdditionsAndClears() async throws {
        let state = PriceLookupState()

        state.addToRecentSearches("Pikachu")
        state.addToRecentSearches("Charizard")
        #expect(state.recentSearches.count == 2)

        state.clearRecentSearches()
        #expect(state.recentSearches.isEmpty)

        state.addToRecentSearches("Mewtwo")
        #expect(state.recentSearches.count == 1)
        #expect(state.recentSearches[0].cardName == "Mewtwo")
    }
}
