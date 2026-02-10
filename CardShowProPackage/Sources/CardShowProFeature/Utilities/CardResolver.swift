import Foundation

// MARK: - CardResolveInput

/// Input parameters for card resolution
struct CardResolveInput: Sendable {
    let language: CardLanguage?
    let setCode: String?
    let number: String?
    let nameHint: String?
    let ximilarConfidence: Double?
}

// MARK: - CardResolution

/// Result of card resolution - single match, ambiguous, or none
enum CardResolution: Sendable {
    case single(LocalCardMatch)
    case ambiguous([LocalCardMatch], reason: String, suggestedSets: [String])
    case none(reason: String)
}

// MARK: - CardResolver

/// Resolves scanned card data to specific card matches
/// Uses local database for fast lookup with FTS5, handles ambiguity
@MainActor
@Observable
final class CardResolver {
    static let shared = CardResolver()

    private let localDB = LocalCardDatabase.shared

    private init() {}

    /// Resolve card input to a match, handling exact lookups, FTS, and ambiguity
    func resolve(_ input: CardResolveInput) async throws -> CardResolution {
        guard await localDB.isReady else {
            return .none(reason: "Local database not ready")
        }

        // Try exact match by number + set first
        if let number = input.number, let setCode = input.setCode {
            let matches = try await localDB.search(name: nil, number: number, limit: 10)
            let setMatches = matches.filter { $0.setID.lowercased() == setCode.lowercased() }

            if setMatches.count == 1 {
                return .single(setMatches[0])
            }
        }

        // Try name-based search
        if let name = input.nameHint, !name.isEmpty {
            let matches = try await localDB.search(name: name, number: input.number, limit: 50)

            if matches.isEmpty {
                return .none(reason: "No matches found for '\(name)'")
            }

            if matches.count == 1 {
                return .single(matches[0])
            }

            // Multiple matches - check if they're from different sets
            let uniqueSets = Array(Set(matches.map { $0.setID })).sorted()

            if uniqueSets.count > 1 {
                return .ambiguous(
                    matches,
                    reason: "Card found in \(uniqueSets.count) sets",
                    suggestedSets: uniqueSets
                )
            }

            // Same set, multiple cards - return first
            return .single(matches[0])
        }

        // Number-only search
        if let number = input.number {
            let matches = try await localDB.search(name: nil, number: number, limit: 50)

            if matches.isEmpty {
                return .none(reason: "No matches found for card #\(number)")
            }

            if matches.count == 1 {
                return .single(matches[0])
            }

            let uniqueSets = Array(Set(matches.map { $0.setID })).sorted()
            return .ambiguous(
                matches,
                reason: "Multiple cards with #\(number)",
                suggestedSets: uniqueSets
            )
        }

        return .none(reason: "Insufficient input for card resolution")
    }
}
