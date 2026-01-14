import Foundation

/// Model representing a recent card search
/// Used for quick-select UI showing last 10 searches
struct RecentSearch: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let cardName: String
    let timestamp: Date

    init(cardName: String, timestamp: Date) {
        self.id = UUID()
        self.cardName = cardName
        self.timestamp = timestamp
    }

    /// Equatable based on card name (case-insensitive)
    static func == (lhs: RecentSearch, rhs: RecentSearch) -> Bool {
        lhs.cardName.lowercased() == rhs.cardName.lowercased()
    }
}
