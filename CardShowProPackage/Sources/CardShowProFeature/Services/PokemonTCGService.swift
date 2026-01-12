import Foundation
import OSLog

/// Service for interacting with PokemonTCG.io API
@Observable
final class PokemonTCGService: @unchecked Sendable {
    static let shared = PokemonTCGService()

    private let networkService = NetworkService.shared
    private let baseURL = "https://api.pokemontcg.io/v2"
    private let logger = Logger(subsystem: "com.cardshowpro.app", category: "PokemonTCGService")

    // MARK: - Configuration
    // PokemonTCG.io API key (optional - higher rate limits with key)
    private let apiKey = "" // Add your PokemonTCG.io API key here (optional)

    // MARK: - State
    var isLoading = false
    var lastError: Error?

    private init() {}

    // MARK: - Public API

    /// Search for Pokemon with autocomplete
    nonisolated func searchPokemon(_ query: String) async throws -> [PokemonSearchResult] {
        guard !query.isEmpty else {
            return []
        }

        logger.info("Searching for Pokemon: \(query)")

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        // Search for cards matching the query - use wildcard for autocomplete
        let searchQuery = "name:\(query)*"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery

        guard let url = URL(string: "\(baseURL)/cards?q=\(encodedQuery)&pageSize=20&orderBy=-set.releaseDate") else {
            throw NetworkError.invalidURL
        }

        var headers: [String: String] = [:]
        if !apiKey.isEmpty {
            headers["X-Api-Key"] = apiKey
        }

        do {
            let response: PokemonTCGResponse = try await networkService.get(
                url: url,
                headers: headers,
                retryCount: 2
            )

            // Extract unique Pokemon names from results
            var seenNames = Set<String>()
            let results = response.data.compactMap { card -> PokemonSearchResult? in
                guard !seenNames.contains(card.name) else { return nil }
                seenNames.insert(card.name)

                return PokemonSearchResult(
                    id: card.id,
                    name: card.name,
                    imageURL: URL(string: card.images.small),
                    availableSets: []
                )
            }

            logger.info("Found \(results.count) Pokemon matching query")
            return Array(results.prefix(10)) // Limit to 10 autocomplete results

        } catch {
            logger.error("Search failed: \(error.localizedDescription)")
            await MainActor.run { lastError = error }
            throw error
        }
    }

    /// Get all sets for a specific Pokemon
    nonisolated func getSetsForPokemon(_ pokemonName: String) async throws -> [CardSet] {
        logger.info("Fetching sets for Pokemon: \(pokemonName)")

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        let searchQuery = "name:\"\(pokemonName)\""
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery

        guard let url = URL(string: "\(baseURL)/cards?q=\(encodedQuery)&orderBy=-set.releaseDate") else {
            throw NetworkError.invalidURL
        }

        var headers: [String: String] = [:]
        if !apiKey.isEmpty {
            headers["X-Api-Key"] = apiKey
        }

        do {
            let response: PokemonTCGResponse = try await networkService.get(
                url: url,
                headers: headers,
                retryCount: 2
            )

            // Extract unique sets
            var seenSetNames = Set<String>()
            let sets = response.data.compactMap { card -> CardSet? in
                let setName = card.set.name
                guard !seenSetNames.contains(setName) else { return nil }
                seenSetNames.insert(setName)

                return CardSet(
                    id: setName, // Using set name as ID for now
                    name: setName,
                    releaseDate: "", // API doesn't provide this in card endpoint
                    logoURL: nil,
                    total: card.set.printedTotal
                )
            }

            logger.info("Found \(sets.count) sets for \(pokemonName)")
            return sets

        } catch {
            logger.error("Failed to fetch sets: \(error.localizedDescription)")
            await MainActor.run { lastError = error }
            throw error
        }
    }

    /// Get specific card with pricing
    nonisolated func getCard(pokemonName: String, setID: String, cardNumber: String) async throws -> (card: PokemonTCGResponse.PokemonTCGCard, pricing: CardPricing) {
        logger.info("Fetching card: \(pokemonName) from set: \(setID), number: \(cardNumber)")

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        // Build search query with all parameters
        var queryParts: [String] = []
        queryParts.append("name:\"\(pokemonName)\"")
        queryParts.append("set.name:\"\(setID)\"")

        // Clean card number (remove # and leading zeros)
        let cleanNumber = cardNumber
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "0"))

        if !cleanNumber.isEmpty {
            queryParts.append("number:\(cleanNumber)")
        }

        let query = queryParts.joined(separator: " ")
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        guard let url = URL(string: "\(baseURL)/cards?q=\(encodedQuery)") else {
            throw NetworkError.invalidURL
        }

        var headers: [String: String] = [:]
        if !apiKey.isEmpty {
            headers["X-Api-Key"] = apiKey
        }

        do {
            let response: PokemonTCGResponse = try await networkService.get(
                url: url,
                headers: headers,
                retryCount: 2
            )

            guard let card = response.data.first else {
                logger.error("Card not found")
                throw PricingError.cardNotFound
            }

            // Extract pricing from the card
            let pricing = extractPricing(from: card)

            logger.info("Successfully fetched card and pricing")
            return (card, pricing)

        } catch {
            logger.error("Failed to fetch card: \(error.localizedDescription)")
            await MainActor.run { lastError = error }
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Extract pricing from a card
    private func extractPricing(from card: PokemonTCGResponse.PokemonTCGCard) -> CardPricing {
        // Try TCGPlayer pricing first
        if let tcgPlayer = card.tcgplayer?.prices,
           let pricing = tcgPlayer.holofoil ?? tcgPlayer.normal ?? tcgPlayer.reverseHolofoil ?? tcgPlayer.unlimitedHolofoil ?? tcgPlayer.firstEditionHolofoil {
            return CardPricing(
                marketPrice: pricing.market,
                lowPrice: pricing.low,
                midPrice: pricing.mid,
                highPrice: pricing.high,
                directLowPrice: pricing.directLow,
                source: .tcgPlayer,
                lastUpdated: Date()
            )
        }

        // Fall back to Cardmarket pricing
        if let cardmarket = card.cardmarket?.prices {
            return CardPricing(
                marketPrice: cardmarket.averageSellPrice,
                lowPrice: cardmarket.lowPrice,
                midPrice: cardmarket.trendPrice,
                highPrice: nil,
                directLowPrice: nil,
                source: .cardmarket,
                lastUpdated: Date()
            )
        }

        // No pricing available - return placeholder
        return CardPricing(
            marketPrice: nil,
            lowPrice: nil,
            midPrice: nil,
            highPrice: nil,
            directLowPrice: nil,
            source: .pokemonTCG,
            lastUpdated: Date()
        )
    }
}

// MARK: - Configuration Helper

extension PokemonTCGService {
    /// Check if API key is configured
    var hasAPIKey: Bool {
        !apiKey.isEmpty
    }

    /// Get rate limit information
    var rateLimitInfo: String {
        if hasAPIKey {
            return "API Key configured - higher rate limits"
        } else {
            return "No API key - 1000 requests/day limit"
        }
    }
}
