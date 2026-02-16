import Foundation
import SwiftData
import SwiftUI

// MARK: - Contact Type

/// The type of business relationship for a contact
enum ContactType: String, CaseIterable, Identifiable, Codable, Sendable {
    case customer
    case buyer
    case vendor
    case eventDirector
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .customer: "Customer"
        case .buyer: "Buyer"
        case .vendor: "Vendor"
        case .eventDirector: "Event Director"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .customer: "person.fill"
        case .buyer: "shippingbox.fill"
        case .vendor: "storefront.fill"
        case .eventDirector: "calendar.badge.clock"
        case .other: "person.crop.circle"
        }
    }

    var color: Color {
        switch self {
        case .customer: DesignSystem.Colors.thunderYellow
        case .buyer: DesignSystem.Colors.warning
        case .vendor: DesignSystem.Colors.electricBlue
        case .eventDirector: DesignSystem.Colors.success
        case .other: DesignSystem.Colors.textSecondary
        }
    }
}

// MARK: - Spending Tier

/// How active a customer is in terms of purchasing
enum SpendingTier: String, CaseIterable, Identifiable, Codable, Sendable {
    case casual
    case regular
    case vip

    var id: String { rawValue }

    var label: String {
        switch self {
        case .casual: "Casual"
        case .regular: "Regular"
        case .vip: "VIP"
        }
    }

    var icon: String {
        switch self {
        case .casual: "star"
        case .regular: "star.leadinghalf.filled"
        case .vip: "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .casual: DesignSystem.Colors.textSecondary
        case .regular: DesignSystem.Colors.electricBlue
        case .vip: DesignSystem.Colors.thunderYellow
        }
    }
}

// MARK: - Preferred Contact Method

/// How a contact prefers to be reached
enum PreferredContactMethod: String, CaseIterable, Identifiable, Codable, Sendable {
    case call
    case text
    case email
    case social
    case noPreference

    var id: String { rawValue }

    var label: String {
        switch self {
        case .call: "Call"
        case .text: "Text"
        case .email: "Email"
        case .social: "Social Media"
        case .noPreference: "No Preference"
        }
    }

    var icon: String {
        switch self {
        case .call: "phone.fill"
        case .text: "message.fill"
        case .email: "envelope.fill"
        case .social: "at"
        case .noPreference: "minus.circle"
        }
    }
}

// MARK: - Contact Model

/// Persistent storage model for a business contact in the card trading space
@Model
public final class Contact {
    @Attribute(.unique) public var id: UUID
    public var name: String

    // Stored as String rawValue for SwiftData compatibility
    public var contactType: String
    public var phone: String?
    public var email: String?
    public var socialMedia: String?
    public var notes: String?
    public var createdAt: Date
    public var lastContactedAt: Date?

    // Customer-specific
    public var collectingInterests: String?
    public var spendingTier: String?
    public var preferredContactMethod: String?

    // Buyer-specific
    public var buyingPreferences: String?

    // Vendor-specific
    public var specialties: String?

    // Event Director-specific
    public var organization: String?
    public var eventName: String?
    public var venue: String?

    init(
        id: UUID = UUID(),
        name: String,
        contactType: ContactType = .other,
        phone: String? = nil,
        email: String? = nil,
        socialMedia: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        lastContactedAt: Date? = nil,
        collectingInterests: String? = nil,
        spendingTier: SpendingTier? = nil,
        preferredContactMethod: PreferredContactMethod? = nil,
        buyingPreferences: String? = nil,
        specialties: String? = nil,
        organization: String? = nil,
        eventName: String? = nil,
        venue: String? = nil
    ) {
        self.id = id
        self.name = name
        self.contactType = contactType.rawValue
        self.phone = phone
        self.email = email
        self.socialMedia = socialMedia
        self.notes = notes
        self.createdAt = createdAt
        self.lastContactedAt = lastContactedAt
        self.collectingInterests = collectingInterests
        self.spendingTier = spendingTier?.rawValue
        self.preferredContactMethod = preferredContactMethod?.rawValue
        self.buyingPreferences = buyingPreferences
        self.specialties = specialties
        self.organization = organization
        self.eventName = eventName
        self.venue = venue
    }

    // MARK: - Typed Enum Accessors

    /// Get the ContactType enum from the stored string
    var contactTypeEnum: ContactType {
        get { ContactType(rawValue: contactType) ?? .other }
        set { contactType = newValue.rawValue }
    }

    /// Get the SpendingTier enum from the stored string
    var spendingTierEnum: SpendingTier? {
        get {
            guard let spendingTier else { return nil }
            return SpendingTier(rawValue: spendingTier)
        }
        set { spendingTier = newValue?.rawValue }
    }

    /// Get the PreferredContactMethod enum from the stored string
    var preferredContactMethodEnum: PreferredContactMethod? {
        get {
            guard let preferredContactMethod else { return nil }
            return PreferredContactMethod(rawValue: preferredContactMethod)
        }
        set { preferredContactMethod = newValue?.rawValue }
    }

    // MARK: - Computed Properties

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

    /// Returns true if the contact has any contact method (phone, email, or social)
    public var hasContactMethod: Bool {
        phone != nil || email != nil || socialMedia != nil
    }

    /// A short subtitle based on contact type
    public var subtitle: String? {
        switch contactTypeEnum {
        case .customer:
            if let interests = collectingInterests, !interests.isEmpty {
                return interests
            }
            return spendingTierEnum?.label
        case .buyer:
            return buyingPreferences
        case .vendor:
            return specialties
        case .eventDirector:
            return organization ?? eventName
        case .other:
            return nil
        }
    }
}

// MARK: - Mock Data

extension Contact {
    @MainActor
    static let mockContacts: [Contact] = [
        Contact(
            name: "John Smith",
            contactType: .customer,
            phone: "555-0123",
            email: "john.smith@example.com",
            notes: "Always looking for deals on vintage sets. Prefers to meet at local shows.",
            createdAt: Date().addingTimeInterval(-86400 * 30),
            lastContactedAt: Date().addingTimeInterval(-86400 * 5),
            collectingInterests: "Vintage Pokemon, Base Set holos",
            spendingTier: .regular,
            preferredContactMethod: .text
        ),
        Contact(
            name: "Sarah Johnson",
            contactType: .customer,
            phone: "555-0456",
            email: "sarah.j@example.com",
            notes: "Collector of holographic cards, attends monthly shows",
            createdAt: Date().addingTimeInterval(-86400 * 60),
            lastContactedAt: Date().addingTimeInterval(-86400 * 2),
            collectingInterests: "Holographic cards, Japanese imports",
            spendingTier: .vip,
            preferredContactMethod: .email
        ),
        Contact(
            name: "Mike Chen",
            contactType: .vendor,
            phone: "555-0789",
            socialMedia: "@mikecards_tcg",
            notes: "Solid vendor to trade with. Fair prices on bulk.",
            createdAt: Date().addingTimeInterval(-86400 * 20),
            lastContactedAt: nil,
            specialties: "Modern Pokemon, bulk lots"
        ),
        Contact(
            name: "Emily Davis",
            contactType: .eventDirector,
            email: "emily.davis@example.com",
            notes: "Runs the monthly card show at the community center. Good to stay in touch for booth reservations.",
            createdAt: Date().addingTimeInterval(-86400 * 10),
            lastContactedAt: Date().addingTimeInterval(-86400 * 1),
            organization: "Metro Card Shows",
            eventName: "Monthly Card Meetup",
            venue: "Downtown Community Center"
        ),
        Contact(
            name: "Robert Martinez",
            contactType: .vendor,
            phone: "555-0321",
            email: "r.martinez@example.com",
            socialMedia: "@rmartinez_cards",
            notes: "Vendor at regional shows, trades in bulk. Good source for singles.",
            createdAt: Date().addingTimeInterval(-86400 * 90),
            lastContactedAt: Date().addingTimeInterval(-86400 * 7),
            specialties: "Sports cards, graded slabs"
        ),
        Contact(
            name: "Lisa Anderson",
            contactType: .customer,
            phone: "555-0654",
            email: "lisa.a@example.com",
            notes: "Looking for first edition Charizard. Has a high budget, serious collector.",
            createdAt: Date().addingTimeInterval(-86400 * 45),
            lastContactedAt: Date().addingTimeInterval(-86400 * 3),
            collectingInterests: "1st Edition Charizard, PSA 10 graded",
            spendingTier: .vip,
            preferredContactMethod: .call
        ),
        Contact(
            name: "Tony Reeves",
            contactType: .buyer,
            phone: "555-0888",
            socialMedia: "@tonybulkbuys",
            notes: "Will take bulk lots off your hands. Prefers to meet locally. Cash only.",
            createdAt: Date().addingTimeInterval(-86400 * 15),
            lastContactedAt: Date().addingTimeInterval(-86400 * 4),
            buyingPreferences: "Bulk commons, off-condition rares, unsorted lots"
        ),
        Contact(
            name: "Derek Williams",
            contactType: .other,
            phone: "555-0999",
            notes: "Met at the Dallas show. Interested in getting into the hobby.",
            createdAt: Date().addingTimeInterval(-86400 * 7),
            lastContactedAt: nil
        )
    ]
}
