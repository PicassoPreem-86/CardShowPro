import Foundation

/// Input parameters for card resolution
struct CardResolveInput: Sendable {
    let language: CardLanguage?
    let setCode: String?         // e.g., "SV9", "base1"
    let number: String?          // e.g., "086", "4"
    let nameHint: String?        // OCR name (may be garbage for JP)
    let ximilarConfidence: Double?
}

/// Result of card resolution
enum CardResolveResult: Sendable {
    case single(LocalCardMatch)
    case ambiguous(candidates: [LocalCardMatch], reason: String, suggestedSets: [String])
    case none(reason: String)
}

/// Timing information for resolution process
struct ResolutionTiming: Sendable {
    let ximilarMs: Double?
    let setCodeOCRMs: Double?
    let numberOCRMs: Double?
    let exactLookupMs: Double?
    let candidateLookupMs: Double?
    let totalMs: Double
}

/// Actor responsible for resolving card matches from input data
actor CardResolver {
    static let shared = CardResolver()

    private let database: LocalCardDatabase
    private let recentSetsStore: RecentSetsStore

    init(database: LocalCardDatabase = .shared, recentSetsStore: RecentSetsStore = .shared) {
        self.database = database
        self.recentSetsStore = recentSetsStore
    }

    /// Resolve a card from the given input parameters
    func resolve(_ input: CardResolveInput) async throws -> CardResolveResult {
        let startTime = Date()
        var exactLookupMs: Double?
        var candidateLookupMs: Double?

        // Step 1: If we have setCode + number, try exact lookup
        if let setCode = input.setCode, let number = input.number {
            let lookupStart = Date()
            let matches = try await database.lookupBy(
                language: input.language,
                setID: setCode,
                number: number
            )
            exactLookupMs = Date().timeIntervalSince(lookupStart) * 1000

            if matches.count == 1 {
                print("🎯 CardResolver: Exact lookup (setCode=\(setCode), number=\(number)) → \(matches[0].id) [\(Int(exactLookupMs!))ms]")

                // Record successful scan for recency tracking
                if let language = input.language {
                    await recentSetsStore.recordScan(setID: setCode, language: language)
                }

                return .single(matches[0])
            } else if matches.count > 1 {
                // Multiple matches with same set+number - shouldn't happen but handle it
                print("⚠️ CardResolver: Multiple matches for setCode=\(setCode), number=\(number)")
                let sets = Array(Set(matches.map { $0.setID }))
                return .ambiguous(
                    candidates: Array(matches.prefix(5)),
                    reason: "Multiple cards found with set \(setCode) #\(number)",
                    suggestedSets: sets
                )
            }
            // If 0 results, fall through to next strategy
            print("⚠️ CardResolver: No exact match for setCode=\(setCode), number=\(number), trying fallback")
        }

        // Step 2: If we have nameHint + number (English path), use FTS search
        if let nameHint = input.nameHint, !nameHint.isEmpty,
           let number = input.number, !number.isEmpty {
            // Use existing FTS search through the database
            let ftsMatches = try await database.searchByNameAndNumber(
                name: nameHint,
                number: number,
                language: input.language
            )

            if !ftsMatches.isEmpty {
                print("🎯 CardResolver: FTS search (name=\(nameHint), number=\(number)) → \(ftsMatches.count) matches")

                // If we have a clear best match, return it
                if ftsMatches.count == 1 {
                    return .single(ftsMatches[0])
                }

                // Multiple matches - return best scored ones
                let scored = await scoreMatches(ftsMatches, input: input)
                let topMatch = scored.first!
                let secondMatch = scored.count > 1 ? scored[1] : nil

                // If top match has significant lead, return it
                if secondMatch == nil || (topMatch.score - secondMatch!.score) > 30 {
                    return .single(topMatch.match)
                }

                // Otherwise show ambiguity
                let sets = Array(Set(scored.prefix(5).map { $0.match.setID }))
                return .ambiguous(
                    candidates: scored.prefix(5).map { $0.match },
                    reason: "Multiple matches for \(nameHint) #\(number)",
                    suggestedSets: sets
                )
            }
        }

        // Step 3: If we only have number, fetch all candidates and score them
        if let number = input.number, !number.isEmpty {
            let lookupStart = Date()
            let candidates = try await database.lookupByNumber(number, limit: 50)
            candidateLookupMs = Date().timeIntervalSince(lookupStart) * 1000

            if candidates.isEmpty {
                return .none(reason: "No cards found with number #\(number)")
            }

            // Score all candidates
            let scored = await scoreMatches(candidates, input: input)

            if scored.isEmpty {
                return .none(reason: "No suitable matches for #\(number)")
            }

            // Check if top match has clear lead
            let topMatch = scored[0]
            let secondMatch = scored.count > 1 ? scored[1] : nil

            if secondMatch == nil || (topMatch.score - secondMatch!.score) > 30 {
                print("🎯 CardResolver: Number-only with clear winner (score=\(topMatch.score)) → \(topMatch.match.id)")
                return .single(topMatch.match)
            }

            // Return ambiguous with top 5 candidates
            let topCandidates = Array(scored.prefix(5))
            let uniqueSets = Array(Set(topCandidates.map { $0.match.setID }))

            print("❓ CardResolver: Ambiguous number #\(number) → \(topCandidates.count) candidates from \(uniqueSets.count) sets")

            let totalMs = Date().timeIntervalSince(startTime) * 1000
            print("⏱️  Resolution timing: exactLookup=\(exactLookupMs.map { "\(Int($0))ms" } ?? "N/A"), candidateLookup=\(candidateLookupMs.map { "\(Int($0))ms" } ?? "N/A"), total=\(Int(totalMs))ms")

            return .ambiguous(
                candidates: topCandidates.map { $0.match },
                reason: "Found \(candidates.count) cards with #\(number)",
                suggestedSets: uniqueSets
            )
        }

        // No usable input
        return .none(reason: "Insufficient information to resolve card")
    }

    /// Score matches based on language, set recency, and set pattern
    private func scoreMatches(_ matches: [LocalCardMatch], input: CardResolveInput) async -> [(match: LocalCardMatch, score: Int)] {
        var scored: [(match: LocalCardMatch, score: Int)] = []

        for match in matches {
            var score = 0

            // +50 points if language matches
            if let inputLanguage = input.language, match.language == inputLanguage {
                score += 50
            }

            // +30 points for modern set patterns (SV%, S%, SM%)
            let setID = match.setID
            if setID.hasPrefix("SV") || setID.hasPrefix("SM") || (setID.hasPrefix("S") && setID.count <= 4) {
                score += 30
            }

            // +20 points if set is in recent scan history
            if let language = input.language {
                let recencyScore = await recentSetsStore.getRecencyScore(setID: setID, language: language)
                score += recencyScore
            }

            // +10 points per approximate year of recency
            // This is a heuristic based on set naming patterns
            // SV* (2023-2024), S* (2021-2022), SM* (2017-2020), base/neo (1999-2000)
            if setID.hasPrefix("SV") {
                score += 30 // 2023-2024
            } else if setID.hasPrefix("S") && !setID.hasPrefix("SM") {
                score += 20 // 2021-2022
            } else if setID.hasPrefix("SM") {
                score += 10 // 2017-2020
            }

            scored.append((match: match, score: score))
        }

        // Sort by score descending
        scored.sort { $0.score > $1.score }

        return scored
    }
}
