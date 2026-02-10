import Foundation

/// Utility for computing string similarity using Levenshtein distance
/// Used for fuzzy matching OCR results against Pokemon card names
enum StringDistance {

    /// Calculate Levenshtein edit distance between two strings
    /// - Parameters:
    ///   - s1: First string
    ///   - s2: Second string
    /// - Returns: Number of single-character edits needed to transform s1 into s2
    static func levenshtein(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        // Handle edge cases
        if m == 0 { return n }
        if n == 0 { return m }

        // Create distance matrix
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        // Initialize first column
        for i in 0...m {
            matrix[i][0] = i
        }

        // Initialize first row
        for j in 0...n {
            matrix[0][j] = j
        }

        // Fill in the rest of the matrix
        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[m][n]
    }

    /// Calculate similarity ratio between two strings (0.0 = no match, 1.0 = exact match)
    /// - Parameters:
    ///   - s1: First string
    ///   - s2: Second string
    /// - Returns: Similarity ratio between 0.0 and 1.0
    static func similarity(_ s1: String, _ s2: String) -> Double {
        let maxLen = max(s1.count, s2.count)
        guard maxLen > 0 else { return 1.0 }
        let distance = levenshtein(s1, s2)
        return 1.0 - (Double(distance) / Double(maxLen))
    }

    /// Find the best matching string from a list of candidates
    /// - Parameters:
    ///   - query: The string to match
    ///   - candidates: List of potential matches
    ///   - threshold: Minimum similarity score to consider (default: 0.65 - lowered to handle OCR typos)
    /// - Returns: Best matching candidate, or nil if no match meets threshold
    static func bestMatch(for query: String, in candidates: [String], threshold: Double = 0.65) -> String? {
        let normalizedQuery = query.lowercased()

        let matches = candidates
            .map { (candidate: $0, score: similarity(normalizedQuery, $0.lowercased())) }
            .filter { $0.score >= threshold }
            .sorted { $0.score > $1.score }

        return matches.first?.candidate
    }

    /// Find all matches above a threshold, sorted by similarity
    /// - Parameters:
    ///   - query: The string to match
    ///   - candidates: List of potential matches
    ///   - threshold: Minimum similarity score to include (default: 0.6)
    ///   - maxResults: Maximum number of results to return (default: 5)
    /// - Returns: Array of (candidate, score) tuples sorted by similarity
    static func findMatches(
        for query: String,
        in candidates: [String],
        threshold: Double = 0.6,
        maxResults: Int = 5
    ) -> [(candidate: String, score: Double)] {
        let normalizedQuery = query.lowercased()

        return candidates
            .map { (candidate: $0, score: similarity(normalizedQuery, $0.lowercased())) }
            .filter { $0.score >= threshold }
            .sorted { $0.score > $1.score }
            .prefix(maxResults)
            .map { $0 }
    }

    /// Normalize a Pokemon card name for comparison
    /// Removes common suffixes, normalizes unicode, trims whitespace
    static func normalizePokemonName(_ name: String) -> String {
        var normalized = name
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common Pokemon card suffixes
        let suffixes = [" ex", " gx", " v", " vmax", " vstar", " vunion",
                        " lv.x", " prime", " legend", " star", " tera"]
        for suffix in suffixes {
            if normalized.hasSuffix(suffix) {
                normalized = String(normalized.dropLast(suffix.count))
            }
        }

        return normalized
    }

    /// Check if two Pokemon names are likely the same card (accounting for typos)
    /// - Parameters:
    ///   - name1: First card name
    ///   - name2: Second card name
    ///   - strictness: How strict the matching should be (0.0-1.0, default 0.8)
    /// - Returns: True if names are likely the same card
    static func isProbablySamePokemon(_ name1: String, _ name2: String, strictness: Double = 0.8) -> Bool {
        let n1 = normalizePokemonName(name1)
        let n2 = normalizePokemonName(name2)

        // Exact match after normalization
        if n1 == n2 { return true }

        // Check similarity
        return similarity(n1, n2) >= strictness
    }
}
