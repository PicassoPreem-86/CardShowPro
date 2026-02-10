import Foundation

/// Represents a contact in the Contacts Management system
struct Contact: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var phone: String?
    var email: String?
    var notes: String?
    let createdAt: Date
    var lastContactedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        phone: String? = nil,
        email: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        lastContactedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.notes = notes
        self.createdAt = createdAt
        self.lastContactedAt = lastContactedAt
    }

    /// Returns initials from the contact name (max 2 characters)
    var initials: String {
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
    var hasContactMethod: Bool {
        return phone != nil || email != nil
    }
}

// MARK: - Mock Data

extension Contact {
    static let mockContacts: [Contact] = [
        Contact(
            name: "John Smith",
            phone: "555-0123",
            email: "john.smith@example.com",
            notes: "Regular customer, interested in vintage Pokemon cards",
            createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            lastContactedAt: Date().addingTimeInterval(-86400 * 5) // 5 days ago
        ),
        Contact(
            name: "Sarah Johnson",
            phone: "555-0456",
            email: "sarah.j@example.com",
            notes: "Collector of holographic cards, attends monthly shows",
            createdAt: Date().addingTimeInterval(-86400 * 60), // 60 days ago
            lastContactedAt: Date().addingTimeInterval(-86400 * 2) // 2 days ago
        ),
        Contact(
            name: "Mike Chen",
            phone: "555-0789",
            email: nil,
            notes: "Prefers rare cards, budget $500-1000",
            createdAt: Date().addingTimeInterval(-86400 * 20), // 20 days ago
            lastContactedAt: nil
        ),
        Contact(
            name: "Emily Davis",
            phone: nil,
            email: "emily.davis@example.com",
            notes: "New collector, interested in starter sets",
            createdAt: Date().addingTimeInterval(-86400 * 10), // 10 days ago
            lastContactedAt: Date().addingTimeInterval(-86400 * 1) // 1 day ago
        ),
        Contact(
            name: "Robert Martinez",
            phone: "555-0321",
            email: "r.martinez@example.com",
            notes: "Vendor at regional shows, trades in bulk",
            createdAt: Date().addingTimeInterval(-86400 * 90), // 90 days ago
            lastContactedAt: Date().addingTimeInterval(-86400 * 7) // 7 days ago
        ),
        Contact(
            name: "Lisa Anderson",
            phone: "555-0654",
            email: "lisa.a@example.com",
            notes: "Looking for first edition Charizard, high budget",
            createdAt: Date().addingTimeInterval(-86400 * 45), // 45 days ago
            lastContactedAt: Date().addingTimeInterval(-86400 * 3) // 3 days ago
        )
    ]
}
