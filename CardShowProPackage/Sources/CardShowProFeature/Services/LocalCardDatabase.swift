import Foundation

/// Local SQLite database with FTS5 for fast card search
@MainActor
@Observable
final class LocalCardDatabase {
    static let shared = LocalCardDatabase()

    private(set) var isReady: Bool = false

    private init() {}

    /// Initialize the database (download/extract if needed)
    func initialize() async throws {
        // Stub: In production this would init SQLite + FTS5
        isReady = true
    }

    /// Search for cards by name and/or number
    func search(name: String?, number: String? = nil, limit: Int = 50) async throws -> [LocalCardMatch] {
        // Stub: Returns empty results — remote API will be used as fallback
        return []
    }
}
