import Foundation
import SwiftData

/// Represents a contact in the Contacts Management system
@Model
public final class Contact {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var phone: String?
    public var email: String?
    public var notes: String?
    public var createdAt: Date
    public var lastContactedAt: Date?

    // New CRM fields
    public var contactType: String // Store as string for SwiftData compatibility
    public var priority: String // Store as string for SwiftData compatibility
    public var tags: [String]
    public var totalRevenue: Decimal

    // Relationship to WantListItems
    @Relationship(deleteRule: .cascade) public var wantListItems: [WantListItem]

    public init(
        id: UUID = UUID(),
        name: String,
        phone: String? = nil,
        email: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        lastContactedAt: Date? = nil,
        contactType: ContactType = .customer,
        priority: ContactPriority = .normal,
        tags: [String] = [],
        totalRevenue: Decimal = 0,
        wantListItems: [WantListItem] = []
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.notes = notes
        self.createdAt = createdAt
        self.lastContactedAt = lastContactedAt
        self.contactType = contactType.rawValue
        self.priority = priority.rawValue
        self.tags = tags
        self.totalRevenue = totalRevenue
        self.wantListItems = wantListItems
    }

    /// Computed property to convert stored string to ContactType enum
    public var contactTypeEnum: ContactType {
        ContactType(rawValue: contactType) ?? .customer
    }

    /// Computed property to convert stored string to ContactPriority enum
    public var priorityEnum: ContactPriority {
        ContactPriority(rawValue: priority) ?? .normal
    }

    /// Returns initials from the contact name (max 2 characters)
    public var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        } else {
            return "?"
        }
    }

    /// Returns true if the contact has any contact method (phone or email)
    public var hasContactMethod: Bool {
        return phone != nil || email != nil
    }
}

// MARK: - Mock Data

extension Contact {
    @MainActor
    public static let mockContacts: [Contact] = [
        Contact(
            name: "John Smith",
            phone: "555-0123",
            email: "john.smith@example.com",
            notes: "Regular customer, interested in vintage Pokemon cards",
            createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            lastContactedAt: Date().addingTimeInterval(-86400 * 5), // 5 days ago
            contactType: .customer,
            priority: .high,
            tags: ["vintage", "pokemon"],
            totalRevenue: 1250.50
        ),
        Contact(
            name: "Sarah Johnson",
            phone: "555-0456",
            email: "sarah.j@example.com",
            notes: "Collector of holographic cards, attends monthly shows",
            createdAt: Date().addingTimeInterval(-86400 * 60), // 60 days ago
            lastContactedAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            contactType: .customer,
            priority: .vip,
            tags: ["holo", "collector"],
            totalRevenue: 3500.75,
            wantListItems: [
                WantListItem(cardName: "Charizard GX", setName: "Hidden Fates", priority: .high),
                WantListItem(cardName: "Pikachu VMAX", setName: "Vivid Voltage", priority: .normal)
            ]
        ),
        Contact(
            name: "Mike Chen",
            phone: "555-0789",
            email: nil,
            notes: "Prefers rare cards, budget $500-1000",
            createdAt: Date().addingTimeInterval(-86400 * 20), // 20 days ago
            lastContactedAt: nil,
            contactType: .lead,
            priority: .normal,
            tags: ["rare"],
            totalRevenue: 0
        ),
        Contact(
            name: "Emily Davis",
            phone: nil,
            email: "emily.davis@example.com",
            notes: "New collector, interested in starter sets",
            createdAt: Date().addingTimeInterval(-86400 * 10), // 10 days ago
            lastContactedAt: Date().addingTimeInterval(-86400 * 1), // 1 day ago
            contactType: .customer,
            priority: .normal,
            tags: ["starter", "new"],
            totalRevenue: 150.00
        ),
        Contact(
            name: "Robert Martinez",
            phone: "555-0321",
            email: "r.martinez@example.com",
            notes: "Vendor at regional shows, trades in bulk",
            createdAt: Date().addingTimeInterval(-86400 * 90), // 90 days ago
            lastContactedAt: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            contactType: .vendor,
            priority: .high,
            tags: ["vendor", "bulk"],
            totalRevenue: 5000.00
        ),
        Contact(
            name: "Lisa Anderson",
            phone: "555-0654",
            email: "lisa.a@example.com",
            notes: "Looking for first edition Charizard, high budget",
            createdAt: Date().addingTimeInterval(-86400 * 45), // 45 days ago
            lastContactedAt: Date().addingTimeInterval(-86400 * 3), // 3 days ago
            contactType: .customer,
            priority: .vip,
            tags: ["charizard", "high-budget"],
            totalRevenue: 8500.00,
            wantListItems: [
                WantListItem(cardName: "Charizard 1st Edition", setName: "Base Set", maxPrice: 5000, priority: .vip),
                WantListItem(cardName: "Blastoise", setName: "Base Set", priority: .high),
                WantListItem(cardName: "Venusaur", setName: "Base Set", priority: .normal)
            ]
        )
    ]
}
