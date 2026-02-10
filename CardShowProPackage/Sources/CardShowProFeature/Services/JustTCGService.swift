import Foundation

/// Response model for JustTCG API card data
struct JustTCGCard: Sendable {
    let tcgplayerId: String
    let conditionPrices: [(condition: String, price: Double)]
    let priceChange7d: Double?
    let priceChange30d: Double?
    let nearMintPriceHistory: [PricePoint]?
    let availablePrintings: [String]
    let primaryPrinting: String

    /// Get the best available condition prices (Normal first, then Foil)
    func bestAvailableConditionPrices() -> [(condition: String, price: Double)] {
        conditionPrices
    }
}

/// Service for fetching detailed condition pricing from JustTCG API
@MainActor
@Observable
final class JustTCGService {
    static let shared = JustTCGService()

    /// Whether the JustTCG API key is configured
    var isConfigured: Bool = false

    private init() {}

    /// Fetch card pricing from JustTCG
    func getCardPricing(tcgplayerId: String, includePriceHistory: Bool = false) async throws -> JustTCGCard {
        // Stub: JustTCG integration not yet configured
        throw PricingError.apiError("JustTCG API not configured")
    }
}
