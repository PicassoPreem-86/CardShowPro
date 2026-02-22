import Foundation
import SwiftData
import SwiftUI

// MARK: - Wishlist Priority

public enum WishlistPriority: String, CaseIterable, Codable, Sendable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    public var displayName: String { rawValue }

    public var icon: String {
        switch self {
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }

    public var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Wishlist Item Model

@Model
public final class WishlistItem {
    @Attribute(.unique) public var id: UUID
    public var cardName: String
    public var setName: String?
    public var cardNumber: String?
    public var variant: String?
    public var desiredCondition: String?
    public var maxPrice: Double?
    public var priority: String
    public var notes: String?
    public var dateAdded: Date
    public var isFulfilled: Bool
    public var fulfilledDate: Date?
    public var fulfilledPrice: Double?
    public var fulfilledCardId: UUID?

    public init(
        id: UUID = UUID(),
        cardName: String,
        setName: String? = nil,
        cardNumber: String? = nil,
        variant: String? = nil,
        desiredCondition: String? = nil,
        maxPrice: Double? = nil,
        priority: WishlistPriority = .medium,
        notes: String? = nil,
        dateAdded: Date = Date(),
        isFulfilled: Bool = false,
        fulfilledDate: Date? = nil,
        fulfilledPrice: Double? = nil,
        fulfilledCardId: UUID? = nil
    ) {
        self.id = id
        self.cardName = cardName
        self.setName = setName
        self.cardNumber = cardNumber
        self.variant = variant
        self.desiredCondition = desiredCondition
        self.maxPrice = maxPrice
        self.priority = priority.rawValue
        self.notes = notes
        self.dateAdded = dateAdded
        self.isFulfilled = isFulfilled
        self.fulfilledDate = fulfilledDate
        self.fulfilledPrice = fulfilledPrice
        self.fulfilledCardId = fulfilledCardId
    }

    // MARK: - Computed Properties

    public var wishlistPriority: WishlistPriority {
        WishlistPriority(rawValue: priority) ?? .medium
    }

    public var variantType: InventoryCardVariant? {
        guard let variant else { return nil }
        return InventoryCardVariant(rawValue: variant)
    }
}
