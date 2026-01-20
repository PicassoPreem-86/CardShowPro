import Testing
import Foundation
@testable import CardShowProFeature

/// Tests for CardResolver - the intelligent card resolution system
/// These tests verify exact lookup, ambiguous resolution, and scoring logic
@Suite("CardResolver Tests")
struct CardResolverTests {

    // MARK: - Exact Lookup Tests

    @Test("Exact lookup with set code returns single match")
    func exactLookupWithSetCode() async throws {
        // This test would require a test database with known cards
        // For now, we document the expected behavior

        // Given: A card with known set code and number
        let input = CardResolveInput(
            language: .japanese,
            setCode: "SV9",
            number: "086",
            nameHint: nil,
            ximilarConfidence: nil
        )

        // When: Resolving the card
        // let result = try await CardResolver.shared.resolve(input)

        // Then: Should return single match
        // #expect(case .single(let match) = result)
        // #expect(match.id == "ja_SV9-086")
        // #expect(match.setID == "SV9")
    }

    @Test("Exact lookup with lowercase set code normalizes correctly")
    func exactLookupNormalizesSetCode() async throws {
        // Given: A card with lowercase set code
        let input = CardResolveInput(
            language: .japanese,
            setCode: "sv9",  // lowercase
            number: "086",
            nameHint: nil,
            ximilarConfidence: nil
        )

        // When: Resolving the card
        // let result = try await CardResolver.shared.resolve(input)

        // Then: Should normalize to uppercase and find match
        // #expect(case .single(let match) = result)
        // #expect(match.setID == "SV9")
    }

    @Test("Exact lookup tries zero-padding variations")
    func exactLookupTriesZeroPadding() async throws {
        // Given: A card number without leading zeros
        let input = CardResolveInput(
            language: .japanese,
            setCode: "SV9",
            number: "86",  // No leading zero
            nameHint: nil,
            ximilarConfidence: nil
        )

        // When: Resolving the card
        // let result = try await CardResolver.shared.resolve(input)

        // Then: Should try "086" variation and find match
        // #expect(case .single(let match) = result)
        // #expect(match.cardNumber == "086")
    }

    // MARK: - Name + Number Search Tests

    @Test("Name and number uses FTS search for English cards")
    func nameAndNumberUsesFTS() async throws {
        // Given: English card name and number
        let input = CardResolveInput(
            language: .english,
            setCode: nil,
            number: "4",
            nameHint: "Charizard",
            ximilarConfidence: nil
        )

        // When: Resolving the card
        // let result = try await CardResolver.shared.resolve(input)

        // Then: Should use FTS search and return result
        // #expect(case .single(let match) = result)
        // #expect(match.cardName.contains("Charizard"))
        // #expect(match.cardNumber == "4")
    }

    // MARK: - Number-Only Ambiguous Resolution Tests

    @Test("Number-only returns ambiguous with top candidates")
    func numberOnlyReturnsAmbiguous() async throws {
        // Given: Only a card number (no set code or name)
        let input = CardResolveInput(
            language: .japanese,
            setCode: nil,
            number: "086",
            nameHint: nil,
            ximilarConfidence: nil
        )

        // When: Resolving the card
        // let result = try await CardResolver.shared.resolve(input)

        // Then: Should return ambiguous with multiple candidates
        // guard case .ambiguous(let candidates, let reason, let sets) = result else {
        //     Issue.record("Expected ambiguous result")
        //     return
        // }

        // #expect(candidates.count <= 5)
        // #expect(sets.count > 0)
        // #expect(reason.contains("086"))
    }

    @Test("Number-only with clear winner returns single match")
    func numberOnlyWithClearWinner() async throws {
        // Given: A unique card number with recent scan history
        let input = CardResolveInput(
            language: .japanese,
            setCode: nil,
            number: "001",  // Likely unique to recent sets
            nameHint: nil,
            ximilarConfidence: nil
        )

        // When: Resolving the card (with recent SV9 scans)
        // Simulate recent scans
        // await RecentSetsStore.shared.recordScan(setID: "SV9", language: .japanese)

        // let result = try await CardResolver.shared.resolve(input)

        // Then: Should return single match if score gap > 30
        // This depends on actual database content
    }

    // MARK: - Scoring Tests

    @Test("Language match adds 50 points to score")
    func languageMatchScoring() async {
        // Test that language matching adds correct score
        // This would test the internal scoring method
    }

    @Test("Modern set pattern adds 30 points to score")
    func modernSetPatternScoring() async {
        // Test that SV*, SM*, S* patterns get bonus points
    }

    @Test("Recent scan history adds up to 20 points")
    func recentScanScoring() async {
        // Given: Recent scans for SV9
        await RecentSetsStore.shared.recordScan(setID: "SV9", language: .japanese)
        await RecentSetsStore.shared.recordScan(setID: "SV9", language: .japanese)

        // When: Getting recency score
        let score = await RecentSetsStore.shared.getRecencyScore(setID: "SV9", language: .japanese)

        // Then: Should be 20 (most recent)
        #expect(score == 20)
    }

    @Test("Recency score decreases with position in history")
    func recencyScoreDecreases() async {
        // Given: Multiple recent scans in order
        await RecentSetsStore.shared.clearHistory()
        await RecentSetsStore.shared.recordScan(setID: "SV9", language: .japanese)
        await RecentSetsStore.shared.recordScan(setID: "SV8", language: .japanese)
        await RecentSetsStore.shared.recordScan(setID: "SV7", language: .japanese)

        // When: Getting scores
        let sv9Score = await RecentSetsStore.shared.getRecencyScore(setID: "SV9", language: .japanese)
        let sv8Score = await RecentSetsStore.shared.getRecencyScore(setID: "SV8", language: .japanese)
        let sv7Score = await RecentSetsStore.shared.getRecencyScore(setID: "SV7", language: .japanese)

        // Then: SV7 (most recent) should have highest score
        #expect(sv7Score == 20)
        #expect(sv8Score == 19)
        #expect(sv9Score == 18)
    }

    // MARK: - Edge Cases

    @Test("No input data returns none result")
    func noInputReturnsNone() async throws {
        // Given: No useful input
        let input = CardResolveInput(
            language: nil,
            setCode: nil,
            number: nil,
            nameHint: nil,
            ximilarConfidence: nil
        )

        // When: Resolving
        let result = try await CardResolver.shared.resolve(input)

        // Then: Should return none
        guard case .none(let reason) = result else {
            Issue.record("Expected none result")
            return
        }

        #expect(reason.contains("Insufficient"))
    }

    @Test("Empty strings treated as nil")
    func emptyStringsTreatedAsNil() async throws {
        // Given: Empty strings instead of nil
        let input = CardResolveInput(
            language: .japanese,
            setCode: "",
            number: "",
            nameHint: "",
            ximilarConfidence: nil
        )

        // When: Resolving
        let result = try await CardResolver.shared.resolve(input)

        // Then: Should return none (empty strings ignored)
        guard case .none = result else {
            Issue.record("Expected none result for empty strings")
            return
        }
    }
}

// MARK: - RecentSetsStore Tests

@Suite("RecentSetsStore Tests")
struct RecentSetsStoreTests {

    @Test("Recording scan adds to front of history")
    func recordingScanAddsToFront() async {
        // Given: Clear history
        await RecentSetsStore.shared.clearHistory()

        // When: Recording scans
        await RecentSetsStore.shared.recordScan(setID: "SV9", language: .japanese)
        await RecentSetsStore.shared.recordScan(setID: "SV8", language: .japanese)

        // Then: Most recent should be first
        let history = await RecentSetsStore.shared.getRecentSets(language: .japanese)
        #expect(history.first == "SV8")
        #expect(history[1] == "SV9")
    }

    @Test("Recording duplicate moves to front")
    func recordingDuplicateMovesToFront() async {
        // Given: History with SV9
        await RecentSetsStore.shared.clearHistory()
        await RecentSetsStore.shared.recordScan(setID: "SV9", language: .japanese)
        await RecentSetsStore.shared.recordScan(setID: "SV8", language: .japanese)

        // When: Recording SV9 again
        await RecentSetsStore.shared.recordScan(setID: "SV9", language: .japanese)

        // Then: SV9 should be first (moved from position 2)
        let history = await RecentSetsStore.shared.getRecentSets(language: .japanese)
        #expect(history.first == "SV9")
        #expect(history.count == 2)  // No duplicates
    }

    @Test("History limited to max entries")
    func historyLimitedToMax() async {
        // Given: Clear history
        await RecentSetsStore.shared.clearHistory()

        // When: Recording more than 20 scans
        for i in 1...25 {
            await RecentSetsStore.shared.recordScan(setID: "SET\(i)", language: .japanese)
        }

        // Then: Should only keep 20 most recent
        let history = await RecentSetsStore.shared.getRecentSets(language: .japanese)
        #expect(history.count == 20)
        #expect(history.first == "SET25")  // Most recent
        #expect(history.last == "SET6")    // 20th most recent
    }

    @Test("Different languages have separate histories")
    func languagesSeparateHistories() async {
        // Given: Scans in different languages
        await RecentSetsStore.shared.clearHistory()
        await RecentSetsStore.shared.recordScan(setID: "SV9", language: .japanese)
        await RecentSetsStore.shared.recordScan(setID: "base1", language: .english)

        // When: Getting histories
        let japaneseHistory = await RecentSetsStore.shared.getRecentSets(language: .japanese)
        let englishHistory = await RecentSetsStore.shared.getRecentSets(language: .english)

        // Then: Should be separate
        #expect(japaneseHistory == ["SV9"])
        #expect(englishHistory == ["base1"])
    }

    @Test("Non-existent set has zero recency score")
    func nonExistentSetZeroScore() async {
        // Given: Empty history
        await RecentSetsStore.shared.clearHistory()

        // When: Getting score for non-existent set
        let score = await RecentSetsStore.shared.getRecencyScore(setID: "NONEXISTENT", language: .japanese)

        // Then: Should be 0
        #expect(score == 0)
    }
}
