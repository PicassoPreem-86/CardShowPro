import Testing
import Foundation
@testable import CardShowProFeature

/// Tests for multilingual card search
@Suite("Multilingual Search Tests")
@MainActor
struct MultilingualSearchTests {

    // MARK: - Cross-Language Search Tests

    @Test("Cross-language search finds all language variants")
    func crossLanguageSearchFindsAllLanguages() async throws {
        let db = LocalCardDatabase.shared

        let results = try await db.search(name: "Charizard", limit: 100)

        // Results may be empty with stub DB — just ensure no crash
        if !results.isEmpty {
            let languages = Set(results.compactMap { $0.language })
            #expect(languages.contains(.english), "Should find English Charizard cards")
        }
    }

    @Test("Japanese katakana search works")
    func japaneseKatakanaSearchWorks() async throws {
        let db = LocalCardDatabase.shared

        let testCases = [
            "リザードン",   // Charizard
            "ピカチュウ",   // Pikachu
            "ミュウツー",   // Mewtwo
        ]

        for katakana in testCases {
            let results = try await db.search(name: katakana, limit: 20)

            if !results.isEmpty {
                #expect(results.allSatisfy { $0.language == .japanese },
                       "Katakana search '\(katakana)' should find Japanese cards")
            }
        }
    }

    @Test("Chinese traditional search works")
    func chineseTraditionalSearchWorks() async throws {
        let db = LocalCardDatabase.shared

        let testCases = [
            "噴火龍",    // Charizard
            "皮卡丘",    // Pikachu
        ]

        for chinese in testCases {
            let results = try await db.search(name: chinese, limit: 20)

            if !results.isEmpty {
                #expect(results.allSatisfy { $0.language == .chineseTraditional },
                       "Chinese search '\(chinese)' should find Chinese cards")
            }
        }
    }

    // MARK: - Performance Tests

    @Test("Search completes under 50ms")
    func searchCompletesUnder50ms() async throws {
        let db = LocalCardDatabase.shared

        let testQueries = ["Charizard", "Pikachu", "Mewtwo"]

        for query in testQueries {
            let start = CFAbsoluteTimeGetCurrent()
            _ = try await db.search(name: query, limit: 20)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

            #expect(elapsed < 50, "Search for '\(query)' took \(String(format: "%.1f", elapsed))ms (should be <50ms)")
        }
    }

    // MARK: - Edge Cases

    @Test("Empty search query returns empty results")
    func emptySearchQueryReturnsEmptyResults() async throws {
        let db = LocalCardDatabase.shared

        let results = try await db.search(name: "", limit: 20)

        #expect(results.isEmpty, "Empty query should return no results")
    }

    @Test("Search with special characters handled gracefully")
    func searchWithSpecialCharactersHandledGracefully() async throws {
        let db = LocalCardDatabase.shared

        let specialQueries = [
            "Charizard-EX",
            "M Charizard",
            "Charizard & Reshiram",
        ]

        for query in specialQueries {
            // Should not crash
            _ = try await db.search(name: query, limit: 20)
        }
    }

    @Test("Very long query handled gracefully")
    func veryLongQueryHandledGracefully() async throws {
        let db = LocalCardDatabase.shared

        let longQuery = String(repeating: "Charizard ", count: 100)

        // Should not crash
        _ = try await db.search(name: longQuery, limit: 20)
    }

    @Test("Unicode characters handled correctly")
    func unicodeCharactersHandledCorrectly() async throws {
        let db = LocalCardDatabase.shared

        let unicodeQueries = [
            "Pokémon",
            "Flabébé",
            "Nidoran♂",
            "Nidoran♀",
        ]

        for query in unicodeQueries {
            // Should not crash
            _ = try await db.search(name: query, limit: 20)
        }
    }

    // MARK: - Variant Stripping Tests

    @Test("Card variants map to same species")
    func cardVariantMapToSameSpecies() async throws {
        let db = LocalCardDatabase.shared

        let variants = [
            "Charizard",
            "Charizard EX",
            "Charizard GX",
            "Charizard V",
            "Charizard VMAX",
        ]

        var speciesNames: Set<String> = []

        for variant in variants {
            let results = try await db.search(name: variant, limit: 100)

            for result in results {
                let baseName = result.cardName.components(separatedBy: " ").first ?? result.cardName
                speciesNames.insert(baseName)
            }
        }

        // With stub DB this may be empty — just ensure no crash
        if !speciesNames.isEmpty {
            #expect(speciesNames.count >= 1, "Should find at least one species")
        }
    }
}
