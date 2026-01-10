import Foundation

/// Service for generating card listings using templates and mock AI
@MainActor
public final class ListingGeneratorService: Sendable {

    public init() {}

    /// Generate a listing for the given parameters
    /// - Returns: Generated listing with title, description, and SEO analysis
    public func generateListing(
        card: InventoryCard,
        platform: ListingPlatform,
        condition: ListingCondition,
        price: Double
    ) async -> GeneratedListing {
        // Simulate AI generation delay (2.5 seconds)
        try? await Task.sleep(for: .seconds(2.5))

        let title = generateTitle(card: card, platform: platform, condition: condition)
        let description = generateDescription(card: card, condition: condition, price: price)
        let keywords = extractKeywords(card: card, platform: platform)
        let score = calculateOptimizationScore(title: title, description: description, keywords: keywords)

        return GeneratedListing(
            title: title,
            description: description,
            suggestedPrice: price,
            seoKeywords: keywords,
            optimizationScore: score,
            platform: platform,
            condition: condition
        )
    }

    // MARK: - Title Generation

    private func generateTitle(
        card: InventoryCard,
        platform: ListingPlatform,
        condition: ListingCondition
    ) -> String {
        let templates = getTitleTemplates(platform: platform)
        let template = templates.randomElement() ?? templates[0]

        return template
            .replacingOccurrences(of: "[CARD_NAME]", with: card.cardName)
            .replacingOccurrences(of: "[SET]", with: card.setName)
            .replacingOccurrences(of: "[CONDITION]", with: condition.rawValue)
            .replacingOccurrences(of: "[NUMBER]", with: card.cardNumber)
    }

    private func getTitleTemplates(platform: ListingPlatform) -> [String] {
        switch platform {
        case .ebay:
            return [
                "[CARD_NAME] - [SET] - [CONDITION] - Pokemon TCG",
                "Pokemon [CARD_NAME] [SET] [CONDITION] Card",
                "[CARD_NAME] [NUMBER]/[SET] Pokemon [CONDITION]"
            ]
        case .tcgplayer:
            return [
                "[CARD_NAME] ([SET] [NUMBER]) [CONDITION]",
                "[CARD_NAME] - [SET] [CONDITION]",
                "[SET] [CARD_NAME] #[NUMBER] [CONDITION]"
            ]
        case .facebook:
            return [
                "[CARD_NAME] - [SET] Pokemon Card - [CONDITION]",
                "Pokemon [CARD_NAME] from [SET] - [CONDITION]",
                "[CONDITION] [CARD_NAME] Pokemon Card ([SET])"
            ]
        case .stockx:
            return [
                "[CARD_NAME] - Pokemon [SET]",
                "Pokemon [CARD_NAME] [SET] #[NUMBER]",
                "[SET] [CARD_NAME] Pokemon Card"
            ]
        case .mercari:
            return [
                "Pokemon [CARD_NAME] [SET] [CONDITION]",
                "[CARD_NAME] [CONDITION] - [SET]",
                "[SET] [CARD_NAME] Pokemon TCG [CONDITION]"
            ]
        }
    }

    // MARK: - Description Generation

    private func generateDescription(
        card: InventoryCard,
        condition: ListingCondition,
        price: Double
    ) -> String {
        var sections: [String] = []

        // Card Details
        sections.append("""
        **Card Details:**
        - Name: \(card.cardName)
        - Set: \(card.setName)
        - Card Number: \(card.cardNumber)
        - Condition: \(condition.rawValue)
        """)

        // Condition Notes
        sections.append("""
        **Condition Notes:**
        \(condition.description)
        """)

        // Pricing
        sections.append("""
        **Pricing:**
        Listed at $\(String(format: "%.2f", price)) based on current market value and condition.
        """)

        // Shipping & Handling
        sections.append(getShippingSection())

        // Authenticity & Guarantee
        sections.append("""
        **Authenticity:**
        All cards are authentic Pokemon TCG products. Cards are stored in a smoke-free, pet-free environment.
        """)

        // Call to Action
        sections.append("""
        **Ready to Ship:**
        This card will be carefully packaged and shipped within 1-2 business days. Questions? Feel free to reach out!
        """)

        return sections.joined(separator: "\n\n")
    }

    private func getShippingSection() -> String {
        let options = [
            """
            **Shipping:**
            - Ships in a protective sleeve and toploader
            - Packaged securely to prevent damage
            - Fast, tracked shipping available
            """,
            """
            **Shipping & Handling:**
            - Protected in a penny sleeve and rigid toploader
            - Shipped in a bubble mailer with cardboard reinforcement
            - Tracking provided on all orders
            """,
            """
            **Secure Shipping:**
            - Card placed in sleeve and toploader for maximum protection
            - Bubble wrapped and shipped in rigid mailer
            - USPS First Class with tracking
            """
        ]

        return options.randomElement() ?? options[0]
    }

    // MARK: - SEO & Keywords

    private func extractKeywords(card: InventoryCard, platform: ListingPlatform) -> [String] {
        var keywords: [String] = []

        // Card name components
        let nameWords = card.cardName.split(separator: " ").map { String($0) }
        keywords.append(contentsOf: nameWords)

        // Set name
        keywords.append(card.setName)

        // Card number
        keywords.append(card.cardNumber)

        // Generic Pokemon keywords
        keywords.append("Pokemon")
        keywords.append("TCG")
        keywords.append("Card")
        keywords.append("Trading Card")

        // Platform-specific
        switch platform {
        case .ebay:
            keywords.append("Collectible")
            keywords.append("Mint")
        case .tcgplayer:
            keywords.append("Single")
            keywords.append("Game")
        case .facebook:
            keywords.append("Local")
            keywords.append("Near Me")
        case .stockx:
            keywords.append("Verified")
            keywords.append("Authentic")
        case .mercari:
            keywords.append("Fast Ship")
            keywords.append("Deal")
        }

        // Remove duplicates and limit to top 10
        return Array(Set(keywords)).prefix(10).map { $0 }
    }

    private func calculateOptimizationScore(
        title: String,
        description: String,
        keywords: [String]
    ) -> Int {
        var score = 50 // Base score

        // Title length optimization (60-70 chars ideal)
        if title.count >= 50 && title.count <= 80 {
            score += 15
        } else if title.count > 30 {
            score += 5
        }

        // Description length (500-1000 chars ideal)
        if description.count >= 400 && description.count <= 1200 {
            score += 15
        } else if description.count > 200 {
            score += 5
        }

        // Keyword usage (7-10 keywords ideal)
        if keywords.count >= 7 && keywords.count <= 10 {
            score += 10
        } else if keywords.count >= 5 {
            score += 5
        }

        // Bonus for structured formatting
        if description.contains("**") {
            score += 5 // Markdown formatting
        }

        // Bonus for shipping info
        if description.lowercased().contains("shipping") {
            score += 5
        }

        return min(score, 100)
    }
}
