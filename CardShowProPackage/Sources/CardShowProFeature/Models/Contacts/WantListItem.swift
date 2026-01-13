import Foundation
import SwiftData

/// SwiftData model representing an item on a contact's want list
@Model
public final class WantListItem {
    @Attribute(.unique) public var id: UUID
    public var cardName: String
    public var setName: String?
    public var condition: String?
    public var maxPrice: Decimal?
    public var notes: String?
    public var priority: String // Store as string for SwiftData compatibility
    public var notifyOnMatch: Bool
    public var dateAdded: Date

    // Relationship to Contact
    public var contact: Contact?

    public init(
        id: UUID = UUID(),
        cardName: String,
        setName: String? = nil,
        condition: String? = nil,
        maxPrice: Decimal? = nil,
        notes: String? = nil,
        priority: ContactPriority = .normal,
        notifyOnMatch: Bool = true,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.cardName = cardName
        self.setName = setName
        self.condition = condition
        self.maxPrice = maxPrice
        self.notes = notes
        self.priority = priority.rawValue
        self.notifyOnMatch = notifyOnMatch
        self.dateAdded = dateAdded
    }

    /// Computed property to convert stored string to enum
    public var priorityEnum: ContactPriority {
        ContactPriority(rawValue: priority) ?? .normal
    }
}
