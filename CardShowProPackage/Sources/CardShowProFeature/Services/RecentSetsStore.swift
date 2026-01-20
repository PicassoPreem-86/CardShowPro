import Foundation

/// Actor that tracks recently scanned sets per language for scoring
actor RecentSetsStore {
    static let shared = RecentSetsStore()

    private let defaults = UserDefaults.standard
    private let maxHistory = 20

    /// Record a successful scan for a given set and language
    func recordScan(setID: String, language: CardLanguage) {
        let key = "recent_sets_\(language.rawValue)"

        // Load existing history
        var history = getRecentSetsArray(for: language)

        // Remove existing entry if present (to move it to front)
        history.removeAll { $0 == setID }

        // Add to front
        history.insert(setID, at: 0)

        // Trim to maxHistory
        if history.count > maxHistory {
            history = Array(history.prefix(maxHistory))
        }

        // Save back to UserDefaults
        defaults.set(history, forKey: key)
    }

    /// Get list of recent sets for a language (most recent first)
    func getRecentSets(language: CardLanguage) -> [String] {
        return getRecentSetsArray(for: language)
    }

    /// Calculate recency score for a set ID (0-20 points based on position in history)
    func getRecencyScore(setID: String, language: CardLanguage) -> Int {
        let history = getRecentSetsArray(for: language)

        guard let index = history.firstIndex(of: setID) else {
            return 0
        }

        // First entry gets 20 points, second gets 19, etc.
        // Points decrease linearly to 1 for the 20th entry
        return max(0, 20 - index)
    }

    /// Clear all recent sets history (useful for testing)
    func clearHistory() {
        for language in CardLanguage.allCases {
            let key = "recent_sets_\(language.rawValue)"
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - Private Helpers

    private func getRecentSetsArray(for language: CardLanguage) -> [String] {
        let key = "recent_sets_\(language.rawValue)"
        return defaults.stringArray(forKey: key) ?? []
    }
}
