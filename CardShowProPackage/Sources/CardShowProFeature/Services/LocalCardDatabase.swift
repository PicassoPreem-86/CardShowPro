import Foundation
import SQLite3
import OSLog

/// High-performance local card database using SQLite with FTS5 for blazing fast search
/// Provides offline search capability and eliminates slow remote API calls
///
/// Performance Targets:
/// - Exact search: <10ms
/// - FTS5 prefix search: <20ms
actor LocalCardDatabase {
    static let shared = LocalCardDatabase()

    private let logger = Logger(subsystem: "com.cardshowpro.app", category: "LocalCardDatabase")

    // SQLite database handle
    private var db: OpaquePointer?

    // Database state
    private(set) var isReady = false
    private(set) var cardCount = 0
    private(set) var lastSyncDate: Date?

    // Schema compatibility flags (cached during init)
    private var hasLanguageColumn = false
    private var hasSourceColumn = false
    private var hasV2Schema = false  // V2 species-normalized schema

    // Database file location - uses Application Support for persistence
    private var databaseURL: URL {
        DatabasePaths.activeDatabase
    }

    // Bundled database (if included in app)
    private var bundledDatabaseURL: URL? {
        DatabasePaths.bundledDatabase
    }

    private init() {}

    // MARK: - Database Lifecycle

    /// Initialize the database
    /// Uses BundledDatabaseInstaller to ensure database exists, then opens it
    func initialize() async throws {
        logger.info("Initializing local card database...")

        // Ensure database is installed (copies from bundle if needed)
        let dbURL = try await BundledDatabaseInstaller.shared.ensureDatabaseInstalled()
        logger.info("Database path: \(dbURL.path)")

        // Open database
        var dbPointer: OpaquePointer?
        let result = sqlite3_open(dbURL.path, &dbPointer)

        guard result == SQLITE_OK, let database = dbPointer else {
            let errorMessage = String(cString: sqlite3_errmsg(dbPointer))
            sqlite3_close(dbPointer)
            logger.error("Failed to open database: \(errorMessage)")
            throw DatabaseError.openFailed(errorMessage)
        }

        db = database
        logger.info("Database opened successfully")

        // Create schema if needed (for empty databases or legacy compatibility)
        try await createSchema()

        // Cache column existence for performance
        hasLanguageColumn = await checkColumnExists(tableName: "cards", columnName: "language")
        hasSourceColumn = await checkColumnExists(tableName: "cards", columnName: "source")
        hasV2Schema = await checkTableExists(tableName: "v2_species")
        logger.info("Schema compatibility - language: \(self.hasLanguageColumn), source: \(self.hasSourceColumn), v2: \(self.hasV2Schema)")

        // Get card count
        cardCount = try await getCardCountInternal()
        logger.info("Database ready with \(self.cardCount) cards")

        isReady = true
    }

    /// Close the database
    func close() {
        if let db = db {
            sqlite3_close(db)
            self.db = nil
            isReady = false
            logger.info("Database closed")
        }
    }

    // MARK: - Schema

    private func createSchema() async throws {
        guard let db = db else { throw DatabaseError.notInitialized }

        // Check if table exists and which columns it has
        let checkLanguage = await checkColumnExists(tableName: "cards", columnName: "language")
        let checkSource = await checkColumnExists(tableName: "cards", columnName: "source")

        logger.info("Schema check - language column: \(checkLanguage), source column: \(checkSource)")

        // Base schema (works with or without language/source columns)
        let baseSchema = """
        -- Main cards table (supports multi-language)
        CREATE TABLE IF NOT EXISTS cards (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            name_normalized TEXT NOT NULL,
            set_name TEXT NOT NULL,
            set_id TEXT NOT NULL,
            card_number TEXT NOT NULL,
            image_url_small TEXT,
            rarity TEXT,
            updated_at INTEGER DEFAULT (strftime('%s', 'now'))
        );

        -- Index for fast lookups
        CREATE INDEX IF NOT EXISTS idx_cards_name_normalized ON cards(name_normalized);
        CREATE INDEX IF NOT EXISTS idx_cards_set_id ON cards(set_id);
        CREATE INDEX IF NOT EXISTS idx_cards_number ON cards(card_number);

        -- FTS5 virtual table for full-text search (supports Japanese with unicode61)
        CREATE VIRTUAL TABLE IF NOT EXISTS cards_fts USING fts5(
            name,
            set_name,
            card_number,
            content='cards',
            content_rowid='rowid',
            tokenize='unicode61 remove_diacritics 2'
        );

        -- Triggers to keep FTS in sync
        CREATE TRIGGER IF NOT EXISTS cards_ai AFTER INSERT ON cards BEGIN
            INSERT INTO cards_fts(rowid, name, set_name, card_number)
            VALUES (NEW.rowid, NEW.name, NEW.set_name, NEW.card_number);
        END;

        CREATE TRIGGER IF NOT EXISTS cards_ad AFTER DELETE ON cards BEGIN
            INSERT INTO cards_fts(cards_fts, rowid, name, set_name, card_number)
            VALUES ('delete', OLD.rowid, OLD.name, OLD.set_name, OLD.card_number);
        END;

        CREATE TRIGGER IF NOT EXISTS cards_au AFTER UPDATE ON cards BEGIN
            INSERT INTO cards_fts(cards_fts, rowid, name, set_name, card_number)
            VALUES ('delete', OLD.rowid, OLD.name, OLD.set_name, OLD.card_number);
            INSERT INTO cards_fts(rowid, name, set_name, card_number)
            VALUES (NEW.rowid, NEW.name, NEW.set_name, NEW.card_number);
        END;

        -- Metadata table for sync tracking (legacy)
        CREATE TABLE IF NOT EXISTS metadata (
            key TEXT PRIMARY KEY,
            value TEXT
        );

        -- Meta table for versioning (used by Python builder)
        CREATE TABLE IF NOT EXISTS meta (
            key TEXT PRIMARY KEY,
            value TEXT
        );
        """

        // Execute base schema
        var errorMessage: UnsafeMutablePointer<CChar>?
        var result = sqlite3_exec(db, baseSchema, nil, nil, &errorMessage)

        if result != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            logger.error("Failed to create base schema: \(error)")
            throw DatabaseError.queryFailed(error)
        }

        // Add language column if it doesn't exist (for legacy databases)
        if !checkLanguage {
            logger.info("Adding language column to legacy database...")
            let addLanguage = "ALTER TABLE cards ADD COLUMN language TEXT NOT NULL DEFAULT 'en';"
            result = sqlite3_exec(db, addLanguage, nil, nil, &errorMessage)
            if result != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
                sqlite3_free(errorMessage)
                logger.warning("Failed to add language column (may already exist): \(error)")
                // Don't throw - column might already exist
            }
        }

        // Add source column if it doesn't exist (for legacy databases)
        if !checkSource {
            logger.info("Adding source column to legacy database...")
            let addSource = "ALTER TABLE cards ADD COLUMN source TEXT NOT NULL DEFAULT 'pokemontcg';"
            result = sqlite3_exec(db, addSource, nil, nil, &errorMessage)
            if result != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
                sqlite3_free(errorMessage)
                logger.warning("Failed to add source column (may already exist): \(error)")
                // Don't throw - column might already exist
            }
        }

        // Create index on language column if it exists now
        let languageIndex = "CREATE INDEX IF NOT EXISTS idx_cards_language ON cards(language);"
        result = sqlite3_exec(db, languageIndex, nil, nil, &errorMessage)
        if result != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            logger.warning("Failed to create language index: \(error)")
            // Don't throw - index creation can fail if column doesn't exist
        }

        logger.info("Database schema created/verified")
    }

    /// Check if a column exists in a table
    private func checkColumnExists(tableName: String, columnName: String) async -> Bool {
        guard let db = db else { return false }

        let sql = "PRAGMA table_info(\(tableName));"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return false
        }

        defer { sqlite3_finalize(statement) }

        while sqlite3_step(statement) == SQLITE_ROW {
            if let namePtr = sqlite3_column_text(statement, 1) {
                let name = String(cString: namePtr)
                if name == columnName {
                    return true
                }
            }
        }

        return false
    }

    /// Check if a table exists
    private func checkTableExists(tableName: String) async -> Bool {
        guard let db = db else { return false }

        let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=?"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return false
        }

        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, tableName, -1, SQLITE_TRANSIENT)

        return sqlite3_step(statement) == SQLITE_ROW
    }

    // MARK: - Search Methods

    /// Check if text contains CJK (Chinese, Japanese, Korean) characters
    private func hasCJKCharacters(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if (0x3040...0x309F).contains(scalar.value) || // Hiragana
               (0x30A0...0x30FF).contains(scalar.value) || // Katakana
               (0x4E00...0x9FFF).contains(scalar.value) {  // CJK Unified Ideographs
                return true
            }
        }
        return false
    }

    /// Search for cards by name and optional number
    /// Uses 2-tier search strategy: exact → FTS5 prefix
    /// Automatically detects Japanese input and searches the appropriate language
    /// For CJK queries, skips exact match (broken normalization in bundled DB) and goes straight to FTS5
    /// Routes to V2 cross-language search if V2 schema is available
    func search(name: String, number: String? = nil, language: CardLanguage? = nil, limit: Int = 20) async throws -> [LocalCardMatch] {
        guard isReady else { throw DatabaseError.notInitialized }
        guard !name.isEmpty else { return [] }

        // Route to v2 search if available
        if hasV2Schema {
            return try await searchV2MultiLanguage(name: name, number: number, limit: limit)
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Auto-detect language from input if not specified (only if DB supports it)
        let searchLanguage: CardLanguage?
        if hasLanguageColumn {
            searchLanguage = language ?? CardLanguage.detect(from: name)
        } else {
            searchLanguage = nil  // Legacy DB - search all cards
        }

        let isJapaneseSearch = searchLanguage == .japanese
        let isCJKQuery = hasCJKCharacters(name)

        // Normalize based on language
        let nameNormalized: String
        if isJapaneseSearch {
            // Japanese: just lowercase (no diacritic folding)
            nameNormalized = name.lowercased()
        } else {
            // Latin scripts: normalize with diacritic removal
            nameNormalized = name.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
        }

        if let lang = searchLanguage {
            logger.info("Searching for '\(name)' (language: \(lang.rawValue), isCJK: \(isCJKQuery))")
        } else {
            logger.info("Searching for '\(name)' (legacy DB - no language filtering, isCJK: \(isCJKQuery))")
        }

        // 1. Try exact match first (fastest, ~5ms) - but skip for CJK queries
        // CJK cards have broken normalization in bundled DB (empty name_normalized), so exact match won't work
        if !isCJKQuery {
            let exactResults = try await searchExact(name: nameNormalized, number: number, language: searchLanguage, limit: limit)
            if !exactResults.isEmpty {
                let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                logger.info("Exact search found \(exactResults.count) results in \(String(format: "%.1f", elapsed))ms")
                return exactResults
            }
        } else {
            logger.info("Skipping exact match for CJK query (using FTS5 only)")
        }

        // 2. FTS5 prefix search (~20ms) - works with original names, not normalized
        let ftsResults = try await searchFTS(name: name, number: number, language: searchLanguage, limit: limit)
        if !ftsResults.isEmpty {
            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            logger.info("FTS search found \(ftsResults.count) results in \(String(format: "%.1f", elapsed))ms")
            return ftsResults
        }

        // NOTE: Levenshtein fuzzy search removed for performance (was 500ms+ for O(m×n×100) comparisons)
        // If exact + FTS5 fail, return empty results - user can retry or use manual entry

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        logger.info("No results found in \(String(format: "%.1f", elapsed))ms")
        return []
    }

    /// Exact lookup by language, set ID, and card number
    /// This is the primary resolution method for cards with known set codes
    func lookupBy(language: CardLanguage?, setID: String, number: String) async throws -> [LocalCardMatch] {
        guard isReady else { throw DatabaseError.notInitialized }

        let normalizedSetID = setID.uppercased().trimmingCharacters(in: .whitespaces)
        let normalizedNumber = normalizeCardNumber(number)

        var query = """
        SELECT id, name, set_name, set_id, card_number, image_url_small, rarity, language, source
        FROM cards
        WHERE set_id = ? AND card_number = ?
        """

        var params: [String] = [normalizedSetID, normalizedNumber]

        if let lang = language {
            query += " AND language = ?"
            params.append(lang.rawValue)
        }

        query += " LIMIT 2"

        let results = try executeQuery(query, params: params)

        // If no results, try zero-padding variations
        if results.isEmpty && !normalizedNumber.starts(with: "0") {
            if let numValue = Int(normalizedNumber) {
                let paddedNumber = String(format: "%03d", numValue)
                return try await lookupBy(language: language, setID: setID, number: paddedNumber)
            }
        }

        return results
    }

    /// Lookup all cards with a given number (for ambiguity resolution)
    /// Returns up to limit cards, sorted by most recently updated
    func lookupByNumber(_ number: String, limit: Int = 50) async throws -> [LocalCardMatch] {
        guard isReady else { throw DatabaseError.notInitialized }
        guard !number.isEmpty else { return [] }

        let normalizedNumber = normalizeCardNumber(number)

        let query = """
        SELECT id, name, set_name, set_id, card_number, image_url_small, rarity, language, source
        FROM cards
        WHERE card_number = ?
        ORDER BY updated_at DESC
        LIMIT ?
        """

        return try executeQuery(query, params: [normalizedNumber, String(limit)])
    }

    /// Search by name and number (used by CardResolver for FTS fallback)
    func searchByNameAndNumber(name: String, number: String, language: CardLanguage?) async throws -> [LocalCardMatch] {
        guard isReady else { throw DatabaseError.notInitialized }

        return try await searchFTS(name: name, number: number, language: language, limit: 20)
    }

    /// Search by card number only (useful when OCR fails to read card name)
    func searchByNumber(_ number: String, language: CardLanguage? = nil, limit: Int = 20) async throws -> [LocalCardMatch] {
        guard isReady else { throw DatabaseError.notInitialized }
        guard !number.isEmpty else { return [] }

        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Searching by number only: '\(number)' (language: \(language?.rawValue ?? "any"))")

        // Normalize the card number (remove # and extra spaces)
        let normalizedNumber = number.trimmingCharacters(in: CharacterSet(charactersIn: "#0 "))

        var query = """
        SELECT id, name, set_name, set_id, card_number, image_url_small, rarity, language, source
        FROM cards
        WHERE card_number = ?
        """

        var params: [String] = [normalizedNumber]

        // Optionally filter by language
        if hasLanguageColumn, let lang = language {
            query += " AND language = ?"
            params.append(lang.rawValue)
        }

        query += " ORDER BY updated_at DESC LIMIT ?"
        params.append(String(limit))

        let results = try executeQuery(query, params: params)

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        logger.info("Number-only search found \(results.count) results in \(String(format: "%.1f", elapsed))ms")

        return results
    }

    /// Normalize card number for consistent lookups
    private func normalizeCardNumber(_ number: String) -> String {
        number.trimmingCharacters(in: CharacterSet(charactersIn: "#0 "))
    }

    /// Search all languages (useful for cross-language lookups)
    func searchAllLanguages(name: String, number: String? = nil, limit: Int = 20) async throws -> [LocalCardMatch] {
        guard isReady else { throw DatabaseError.notInitialized }
        guard !name.isEmpty else { return [] }

        let startTime = CFAbsoluteTimeGetCurrent()
        let nameNormalized = name.lowercased()

        // FTS5 search without language filter
        let results = try await searchFTS(name: name, number: number, language: nil, limit: limit)

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        logger.info("Multi-language search found \(results.count) results in \(String(format: "%.1f", elapsed))ms")

        return results
    }

    // MARK: - V2 Cross-Language Search

    /// Search using V2 species-normalized schema for cross-language results
    /// Example: "Charizard" finds English, Japanese (リザードン), and Chinese (噴火龍) cards
    /// Example: "Rizaadon" (romaji) finds Japanese リザードン cards
    func searchV2MultiLanguage(name: String, number: String? = nil, limit: Int = 20) async throws -> [LocalCardMatch] {
        guard isReady else { throw DatabaseError.notInitialized }
        guard hasV2Schema else {
            // Fall back to v1 search if v2 schema doesn't exist
            logger.info("V2 schema not found, falling back to v1 search")
            return try await search(name: name, number: number, language: nil, limit: limit)
        }
        guard !name.isEmpty else { return [] }

        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("V2 cross-language search for '\(name)'")

        // Build FTS query with prefix matching
        let words = name.split(separator: " ").map { "\"\($0)\"*" }
        let ftsQuery = words.joined(separator: " ")

        // V2 Cross-language query:
        // 1. Search species_aliases_fts for matching species
        // 2. Join to printings via printing_species_map
        // 3. Get canonical name for each language
        var query = """
        WITH fts_matches AS (
            SELECT sa.species_id, fts.rank
            FROM v2_species_aliases sa
            JOIN v2_species_aliases_fts fts ON sa.alias_id = fts.rowid
            WHERE v2_species_aliases_fts MATCH ?
            LIMIT 100
        )
        SELECT
            p.printing_id as id,
            sa.alias as name,
            p.set_name,
            p.set_id,
            p.card_number,
            p.image_url_small,
            p.rarity,
            p.language,
            p.source
        FROM fts_matches fm
        JOIN v2_printing_species_map psm ON fm.species_id = psm.species_id
        JOIN v2_printings p ON psm.printing_id = p.printing_id
        JOIN v2_species_aliases sa ON fm.species_id = sa.species_id
            AND sa.language = p.language
            AND sa.is_canonical = 1
        """

        var params: [String] = [ftsQuery]

        // Optional card number filter
        if let num = number?.trimmingCharacters(in: CharacterSet(charactersIn: "#0 ")), !num.isEmpty {
            query += " WHERE p.card_number = ?"
            params.append(num)
        }

        query += " ORDER BY fm.rank LIMIT ?"
        params.append(String(limit))

        let results = try executeQuery(query, params: params)

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        logger.info("V2 search found \(results.count) results in \(String(format: "%.1f", elapsed))ms")

        return results
    }

    /// Exact name match search
    private func searchExact(name: String, number: String?, language: CardLanguage?, limit: Int) async throws -> [LocalCardMatch] {
        guard let db = db else { throw DatabaseError.notInitialized }

        var query = """
        SELECT id, name, set_name, set_id, card_number, image_url_small, rarity, language, source
        FROM cards
        WHERE name_normalized = ?
        """

        var params: [String] = [name]

        // Filter by language if specified
        if let lang = language {
            query += " AND language = ?"
            params.append(lang.rawValue)
        }

        if let num = number?.trimmingCharacters(in: CharacterSet(charactersIn: "#0 ")), !num.isEmpty {
            query += " AND card_number = ?"
            params.append(num)
        }

        query += " ORDER BY updated_at DESC LIMIT ?"
        params.append(String(limit))

        return try executeQuery(query, params: params)
    }

    /// FTS5 full-text search with prefix matching
    private func searchFTS(name: String, number: String?, language: CardLanguage?, limit: Int) async throws -> [LocalCardMatch] {
        guard let db = db else { throw DatabaseError.notInitialized }

        // Build FTS query with prefix matching
        // Split name into words and add * for prefix matching
        let words = name.split(separator: " ").map { "\"\($0)\"*" }
        let ftsQuery = words.joined(separator: " ")

        var query = """
        SELECT c.id, c.name, c.set_name, c.set_id, c.card_number, c.image_url_small, c.rarity, c.language, c.source
        FROM cards c
        JOIN cards_fts fts ON c.rowid = fts.rowid
        WHERE cards_fts MATCH ?
        """

        var params: [String] = [ftsQuery]

        // Filter by language if specified
        if let lang = language {
            query += " AND c.language = ?"
            params.append(lang.rawValue)
        }

        if let num = number?.trimmingCharacters(in: CharacterSet(charactersIn: "#0 ")), !num.isEmpty {
            query += " AND c.card_number = ?"
            params.append(num)
        }

        query += " ORDER BY rank LIMIT ?"
        params.append(String(limit))

        return try executeQuery(query, params: params)
    }

    /// Fuzzy search using Levenshtein distance
    /// Gets candidates from FTS prefix, then filters by string similarity
    /// NOTE: Currently unused due to performance issues (500ms+ for 100 candidates)
    /// Kept for potential future optimization
    @available(*, deprecated, message: "Removed from search flow - too slow for production use")
    private func searchFuzzy(name: String, number: String?, language: CardLanguage?, limit: Int) async throws -> [LocalCardMatch] {
        guard name.count >= 3 else { return [] }

        // Get candidates with first few characters
        let prefix = String(name.prefix(min(4, name.count)))
        let prefixQuery = "\"\(prefix)\"*"

        var query = """
        SELECT c.id, c.name, c.set_name, c.set_id, c.card_number, c.image_url_small, c.rarity, c.language, c.source
        FROM cards c
        JOIN cards_fts fts ON c.rowid = fts.rowid
        WHERE cards_fts MATCH ?
        """

        var params: [String] = [prefixQuery]

        // Filter by language if specified
        if let lang = language {
            query += " AND c.language = ?"
            params.append(lang.rawValue)
        }

        query += " LIMIT 100"

        let candidates = try executeQuery(query, params: params)

        // Filter by Levenshtein similarity
        let threshold = 0.65
        var matches = candidates.filter { card in
            StringDistance.similarity(name, card.cardName.lowercased()) >= threshold
        }

        // If number provided, prioritize matching numbers
        if let num = number?.trimmingCharacters(in: CharacterSet(charactersIn: "#0 ")), !num.isEmpty {
            matches.sort { m1, m2 in
                let m1Matches = m1.cardNumber == num
                let m2Matches = m2.cardNumber == num
                if m1Matches && !m2Matches { return true }
                if m2Matches && !m1Matches { return false }
                return StringDistance.similarity(name, m1.cardName.lowercased()) >
                       StringDistance.similarity(name, m2.cardName.lowercased())
            }
        }

        return Array(matches.prefix(limit))
    }

    /// Execute a SELECT query and return results
    /// Expected columns: id, name, set_name, set_id, card_number, image_url_small, rarity, language, source
    private func executeQuery(_ sql: String, params: [String]) throws -> [LocalCardMatch] {
        guard let db = db else { throw DatabaseError.notInitialized }

        var statement: OpaquePointer?
        var results: [LocalCardMatch] = []

        let prepareResult = sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        guard prepareResult == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(error)
        }

        defer { sqlite3_finalize(statement) }

        // Bind parameters
        for (index, param) in params.enumerated() {
            sqlite3_bind_text(statement, Int32(index + 1), param, -1, SQLITE_TRANSIENT)
        }

        // Check column count to determine if language/source are present
        let columnCount = sqlite3_column_count(statement)
        let hasLanguageColumns = columnCount >= 9

        // Execute and collect results
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(statement, 0))
            let name = String(cString: sqlite3_column_text(statement, 1))
            let setName = String(cString: sqlite3_column_text(statement, 2))
            let setID = String(cString: sqlite3_column_text(statement, 3))
            let cardNumber = String(cString: sqlite3_column_text(statement, 4))

            let imageURL: String?
            if let ptr = sqlite3_column_text(statement, 5) {
                imageURL = String(cString: ptr)
            } else {
                imageURL = nil
            }

            let rarity: String?
            if let ptr = sqlite3_column_text(statement, 6) {
                rarity = String(cString: ptr)
            } else {
                rarity = nil
            }

            // Parse language (default to English for legacy databases)
            let language: CardLanguage
            if hasLanguageColumns, let ptr = sqlite3_column_text(statement, 7) {
                language = CardLanguage(rawValue: String(cString: ptr)) ?? .english
            } else {
                language = .english
            }

            // Parse source (default to pokemontcg for legacy databases)
            let source: CardDataSource
            if hasLanguageColumns, let ptr = sqlite3_column_text(statement, 8) {
                source = CardDataSource(rawValue: String(cString: ptr)) ?? .pokemontcg
            } else {
                source = .pokemontcg
            }

            results.append(LocalCardMatch(
                id: id,
                cardName: name,
                setName: setName,
                setID: setID,
                cardNumber: cardNumber,
                imageURLSmall: imageURL,
                rarity: rarity,
                language: language,
                source: source
            ))
        }

        return results
    }

    // MARK: - Data Import

    /// Insert or update cards in the database
    func upsertCards(_ cards: [LocalCardMatch]) async throws -> Int {
        guard let db = db else { throw DatabaseError.notInitialized }

        let startTime = CFAbsoluteTimeGetCurrent()
        var insertedCount = 0

        // Begin transaction
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)

        let sql = """
        INSERT OR REPLACE INTO cards (id, name, name_normalized, set_name, set_id, card_number, image_url_small, rarity, language, source, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, strftime('%s', 'now'))
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(db))
            sqlite3_exec(db, "ROLLBACK", nil, nil, nil)
            throw DatabaseError.queryFailed(error)
        }

        defer { sqlite3_finalize(statement) }

        for card in cards {
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)

            sqlite3_bind_text(statement, 1, card.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, card.cardName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, card.nameNormalized, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, card.setName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 5, card.setID, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 6, card.cardNumber, -1, SQLITE_TRANSIENT)

            if let imageURL = card.imageURLSmall {
                sqlite3_bind_text(statement, 7, imageURL, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 7)
            }

            if let rarity = card.rarity {
                sqlite3_bind_text(statement, 8, rarity, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 8)
            }

            sqlite3_bind_text(statement, 9, card.language.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 10, card.source.rawValue, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                insertedCount += 1
            }
        }

        // Commit transaction
        sqlite3_exec(db, "COMMIT", nil, nil, nil)

        // Update card count
        cardCount = try await getCardCountInternal()

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("Upserted \(insertedCount) cards in \(String(format: "%.2f", elapsed))s")

        return insertedCount
    }

    /// Get total card count
    private func getCardCountInternal() async throws -> Int {
        guard let db = db else { throw DatabaseError.notInitialized }

        var statement: OpaquePointer?
        let sql = "SELECT COUNT(*) FROM cards"

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }

        defer { sqlite3_finalize(statement) }

        if sqlite3_step(statement) == SQLITE_ROW {
            return Int(sqlite3_column_int(statement, 0))
        }

        return 0
    }

    /// Update sync metadata
    func updateSyncDate() async {
        lastSyncDate = Date()

        guard let db = db else { return }

        let sql = "INSERT OR REPLACE INTO metadata (key, value) VALUES ('last_sync', ?)"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            let dateString = ISO8601DateFormatter().string(from: Date())
            sqlite3_bind_text(statement, 1, dateString, -1, SQLITE_TRANSIENT)
            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
    }

    /// Get a metadata value by key
    /// Used for version checking during database updates
    /// - Parameter key: The metadata key to retrieve
    /// - Returns: The value if found, nil otherwise
    func getMetaValue(key: String) -> String? {
        guard let database = db else { return nil }

        // Try 'meta' table first (used by Python builder)
        var sql = "SELECT value FROM meta WHERE key = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, key, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_ROW {
                if let ptr = sqlite3_column_text(statement, 0) {
                    let value = String(cString: ptr)
                    sqlite3_finalize(statement)
                    return value
                }
            }
            sqlite3_finalize(statement)
        }

        // Fall back to 'metadata' table (used by legacy code)
        sql = "SELECT value FROM metadata WHERE key = ?"
        if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, key, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_ROW {
                if let ptr = sqlite3_column_text(statement, 0) {
                    let value = String(cString: ptr)
                    sqlite3_finalize(statement)
                    return value
                }
            }
            sqlite3_finalize(statement)
        }

        return nil
    }

    /// Clear all cards from database
    func clearAllCards() async throws {
        guard let db = db else { throw DatabaseError.notInitialized }

        sqlite3_exec(db, "DELETE FROM cards", nil, nil, nil)
        sqlite3_exec(db, "DELETE FROM cards_fts", nil, nil, nil)
        cardCount = 0

        logger.info("Cleared all cards from database")
    }
}

// MARK: - SQLite Transient Constant

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - Database Errors

enum DatabaseError: LocalizedError {
    case notInitialized
    case openFailed(String)
    case queryFailed(String)
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database not initialized"
        case .openFailed(let message):
            return "Failed to open database: \(message)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .importFailed(let message):
            return "Import failed: \(message)"
        }
    }
}
