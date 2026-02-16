import Foundation

/// Template-based listing generator for multiple selling platforms.
/// Produces ready-to-paste card listing descriptions using InventoryCard data.
@MainActor
enum ListingGeneratorService {

    // MARK: - Public API

    /// Generate a listing description for the given card and platform.
    static func generateListing(
        for card: InventoryCard,
        platform: ListingPlatform,
        includePrice: Bool,
        includeShipping: Bool
    ) -> String {
        switch platform {
        case .ebay:
            return generateEbayListing(card: card, includeShipping: includeShipping)
        case .tcgplayer:
            return generateTCGPlayerListing(card: card)
        case .facebook:
            return generateFacebookListing(card: card, includePrice: includePrice)
        case .mercari:
            return generateMercariListing(card: card, includeShipping: includeShipping)
        case .generic:
            return generateGenericListing(card: card, includePrice: includePrice)
        }
    }

    // MARK: - Condition Description

    /// Returns a human-readable condition description based on the card's stored condition string.
    private static func conditionDescription(for condition: String) -> String {
        switch condition {
        case "Mint":
            return "Card is in pristine, pack-fresh condition with no visible wear."
        case "Near Mint":
            return "Card is in excellent condition with minimal to no wear."
        case "Lightly Played":
            return "Card shows minor wear including light edge whitening."
        case "Moderately Played":
            return "Card shows moderate wear. See photos for condition."
        case "Heavily Played":
            return "Card shows significant wear. Priced accordingly."
        case "Damaged":
            return "Card has notable damage. Please review photos carefully."
        default:
            return "See photos for condition details."
        }
    }

    // MARK: - Grading Line Helpers

    /// Returns a grading line like "PSA 10 - Cert #12345678" if the card is graded, otherwise nil.
    private static func gradingLine(for card: InventoryCard) -> String? {
        guard let service = card.gradingService, let grade = card.grade else { return nil }
        if let cert = card.certNumber, !cert.isEmpty {
            return "\(service) \(grade) - Cert #\(cert)"
        }
        return "\(service) \(grade)"
    }

    /// Returns a short grading label like "PSA 10" if the card is graded.
    private static func gradingShort(for card: InventoryCard) -> String? {
        guard let service = card.gradingService, let grade = card.grade else { return nil }
        return "\(service) \(grade)"
    }

    // MARK: - Platform Templates

    private static func generateEbayListing(card: InventoryCard, includeShipping: Bool) -> String {
        var lines: [String] = []

        // Title line
        lines.append("\(card.cardName) - \(card.setName) #\(card.cardNumber) Pokemon TCG")
        lines.append("")

        // Condition
        lines.append("Condition: \(card.condition)")

        // Grading (if applicable)
        if let grading = gradingLine(for: card) {
            lines.append(grading)
        }

        lines.append("")

        // Card Details block
        lines.append("Card Details:")
        lines.append("- Set: \(card.setName)")
        lines.append("- Number: \(card.cardNumber)")
        lines.append("- Condition: \(card.condition)")

        if let grading = gradingShort(for: card) {
            lines.append("- Grading: \(grading)")
        }

        lines.append("")

        // Condition description
        lines.append(conditionDescription(for: card.condition))

        // Shipping
        if includeShipping {
            lines.append("")
            lines.append("Shipping: Ships within 1 business day in penny sleeve + toploader.")
        }

        lines.append("")
        lines.append("Thank you for looking! Check out my other listings.")

        return lines.joined(separator: "\n")
    }

    private static func generateTCGPlayerListing(card: InventoryCard) -> String {
        var parts: [String] = []

        parts.append("\(card.condition).")
        parts.append(conditionDescription(for: card.condition))
        parts.append("Ships in penny sleeve + toploader.")

        if let service = card.gradingService, let grade = card.grade {
            var gradeLine = "Graded \(service) \(grade)."
            if let cert = card.certNumber, !cert.isEmpty {
                gradeLine += " Cert #\(cert)."
            }
            parts.append(gradeLine)
        }

        return parts.joined(separator: " ")
    }

    private static func generateFacebookListing(card: InventoryCard, includePrice: Bool) -> String {
        var lines: [String] = []

        lines.append("\(card.cardName) from \(card.setName)")
        lines.append("Condition: \(card.condition)")

        if let grading = gradingShort(for: card) {
            lines.append(grading)
        }

        if includePrice && card.estimatedValue > 0 {
            lines.append("Price: $\(String(format: "%.2f", card.estimatedValue)) OBO")
        }

        lines.append("Local pickup available / Will ship for additional cost")

        return lines.joined(separator: "\n")
    }

    private static func generateMercariListing(card: InventoryCard, includeShipping: Bool) -> String {
        var lines: [String] = []

        lines.append("\(card.cardName) - \(card.setName) #\(card.cardNumber)")
        lines.append("Condition: \(card.condition)")

        if let service = card.gradingService, let grade = card.grade {
            lines.append("Professionally graded: \(service) \(grade)")
        }

        lines.append(conditionDescription(for: card.condition))

        if includeShipping {
            lines.append("Ships same day in protective packaging.")
        }

        return lines.joined(separator: "\n")
    }

    private static func generateGenericListing(card: InventoryCard, includePrice: Bool) -> String {
        var lines: [String] = []

        lines.append("\(card.cardName) - \(card.setName) #\(card.cardNumber)")
        lines.append("Condition: \(card.condition)")

        if includePrice && card.estimatedValue > 0 {
            lines.append("Price: $\(String(format: "%.2f", card.estimatedValue))")
        }

        return lines.joined(separator: "\n")
    }
}
