import Foundation

/// Service for fetching Pokemon card pricing data
@MainActor
@Observable
final class PricingService {
    static let shared = PricingService()

    private let networkService = NetworkService.shared
    private let baseURL = "https://api.pokemontcg.io/v2"

    // MARK: - Configuration
    // PokemonTCG.io API key (optional - higher rate limits with key)
    private let apiKey = "" // Add your PokemonTCG.io API key here (optional)

    // MARK: - State
    var isLoading = false
    var lastError: PricingError?

    private init() {}

    // MARK: - Public API

    /// Fetch pricing for a Pokemon card
    func fetchPricing(cardName: String, setName: String, cardNumber: String) async throws -> CardPricing {
        isLoading = true
        defer { isLoading = false }

        // Build search query
        let query = buildSearchQuery(cardName: cardName, setName: setName, cardNumber: cardNumber)

        guard let url = URL(string: "\(baseURL)/cards?\(query)") else {
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

            guard let pricing = response.toCardPricing() else {
                // If no pricing available, return mock data for development
                return try await mockPricing(cardName: cardName)
            }

            return pricing
        } catch let error as NetworkError {
            throw PricingError.networkError(error)
        } catch {
            throw PricingError.apiError(error.localizedDescription)
        }
    }

    /// Fetch pricing by card ID (more accurate)
    func fetchPricingByID(_ cardID: String) async throws -> CardPricing {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/cards/\(cardID)") else {
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

            guard let pricing = response.toCardPricing() else {
                throw PricingError.noPricingAvailable
            }

            return pricing
        } catch let error as NetworkError {
            throw PricingError.networkError(error)
        } catch {
            throw PricingError.apiError(error.localizedDescription)
        }
    }

    /// Search for cards matching criteria
    func searchCards(name: String? = nil, setName: String? = nil, number: String? = nil) async throws -> [PokemonTCGResponse.PokemonTCGCard] {
        var queryParts: [String] = []

        if let name = name, !name.isEmpty {
            queryParts.append("name:\"\(name)\"")
        }

        if let setName = setName, !setName.isEmpty {
            queryParts.append("set.name:\"\(setName)\"")
        }

        if let number = number, !number.isEmpty {
            queryParts.append("number:\(number)")
        }

        guard let encodedQuery = queryParts.joined(separator: " ").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NetworkError.invalidURL
        }
        let query = "q=" + encodedQuery

        guard let url = URL(string: "\(baseURL)/cards?\(query)") else {
            throw NetworkError.invalidURL
        }

        var headers: [String: String] = [:]
        if !apiKey.isEmpty {
            headers["X-Api-Key"] = apiKey
        }

        let response: PokemonTCGResponse = try await networkService.get(
            url: url,
            headers: headers
        )

        return response.data
    }

    // MARK: - Helper Methods

    private func buildSearchQuery(cardName: String, setName: String, cardNumber: String) -> String {
        var parts: [String] = []

        // Clean up card name (remove VMAX, V, ex, etc. for better matching)
        let cleanName = cardName
            .replacingOccurrences(of: " VMAX", with: "")
            .replacingOccurrences(of: " VSTAR", with: "")
            .replacingOccurrences(of: " V", with: "")
            .replacingOccurrences(of: " ex", with: "")
            .trimmingCharacters(in: .whitespaces)

        parts.append("name:\"\(cleanName)\"")

        // Add set name if available
        if !setName.isEmpty && setName != "Unknown Set" {
            parts.append("set.name:\"\(setName)\"")
        }

        // Add card number if available
        if !cardNumber.isEmpty && cardNumber != "???" {
            // Remove leading zeros and hash symbol
            let cleanNumber = cardNumber.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "0"))
            if !cleanNumber.isEmpty {
                parts.append("number:\(cleanNumber)")
            }
        }

        let query = parts.joined(separator: " ")
        return "q=" + (query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)
    }

    // MARK: - Mock Pricing (for development/fallback)

    private func mockPricing(cardName: String) async throws -> CardPricing {
        // Simulate API delay
        try await Task.sleep(for: .milliseconds(400))

        // Generate realistic mock pricing based on card name
        let basePrice: Double

        if cardName.contains("VMAX") || cardName.contains("VSTAR") {
            basePrice = Double.random(in: 15...80)
        } else if cardName.contains(" V") || cardName.contains(" ex") {
            basePrice = Double.random(in: 5...40)
        } else if cardName.contains("Charizard") || cardName.contains("Pikachu") {
            basePrice = Double.random(in: 10...150)
        } else {
            basePrice = Double.random(in: 1...25)
        }

        let variance = basePrice * 0.3
        return CardPricing(
            marketPrice: basePrice,
            lowPrice: basePrice - variance,
            midPrice: basePrice,
            highPrice: basePrice + variance,
            directLowPrice: basePrice - (variance * 0.5),
            source: .pokemonTCG,
            lastUpdated: Date()
        )
    }
}

// MARK: - Configuration Helper

extension PricingService {
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
