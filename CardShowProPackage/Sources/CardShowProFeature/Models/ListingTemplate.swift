import Foundation
import SwiftData

// MARK: - Listing Template Model

/// User-created templates for generating card listings.
/// Template variables: {cardName}, {setName}, {cardNumber}, {condition}, {grade}, {variant}, {price}
@Model
public final class ListingTemplate {
    public var id: UUID
    public var name: String
    public var platform: String?
    public var titleFormat: String
    public var descriptionFormat: String
    public var isDefault: Bool
    public var dateCreated: Date

    public init(
        id: UUID = UUID(),
        name: String,
        platform: String? = nil,
        titleFormat: String = "{cardName} - {setName} - {condition}",
        descriptionFormat: String = "{cardName} from {setName}. Condition: {condition}.",
        isDefault: Bool = false,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.platform = platform
        self.titleFormat = titleFormat
        self.descriptionFormat = descriptionFormat
        self.isDefault = isDefault
        self.dateCreated = dateCreated
    }
}

// MARK: - Template Variable Substitution

extension ListingTemplate {
    /// Apply template variables from an InventoryCard
    public func applyTitle(to card: InventoryCard) -> String {
        Self.substituteVariables(in: titleFormat, card: card)
    }

    /// Apply template variables from an InventoryCard
    public func applyDescription(to card: InventoryCard) -> String {
        Self.substituteVariables(in: descriptionFormat, card: card)
    }

    /// Generate full listing text from template
    public func generateListing(for card: InventoryCard) -> String {
        let title = applyTitle(to: card)
        let desc = applyDescription(to: card)
        return "\(title)\n\n\(desc)"
    }

    /// Substitute {variable} placeholders with card data
    private static func substituteVariables(in template: String, card: InventoryCard) -> String {
        var result = template
        result = result.replacingOccurrences(of: "{cardName}", with: card.cardName)
        result = result.replacingOccurrences(of: "{setName}", with: card.setName)
        result = result.replacingOccurrences(of: "{cardNumber}", with: card.cardNumber)
        result = result.replacingOccurrences(of: "{condition}", with: card.condition)
        result = result.replacingOccurrences(of: "{grade}", with: card.gradeDisplay ?? "Ungraded")
        result = result.replacingOccurrences(of: "{variant}", with: card.variant ?? "Standard")
        result = result.replacingOccurrences(of: "{price}", with: String(format: "%.2f", card.estimatedValue))
        return result
    }
}
