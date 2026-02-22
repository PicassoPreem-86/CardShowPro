import Foundation
import SwiftData

// MARK: - Trade Record Model

/// Persistent record of a card trade between users
@Model
public final class TradeRecord {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var contactId: UUID?
    public var contactName: String?
    public var eventName: String?
    public var notes: String?
    public var myCardsJSON: String?
    public var theirCardsJSON: String?
    public var myTotalValue: Double
    public var theirTotalValue: Double
    public var fairnessScore: Double

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        contactId: UUID? = nil,
        contactName: String? = nil,
        eventName: String? = nil,
        notes: String? = nil,
        myCardsJSON: String? = nil,
        theirCardsJSON: String? = nil,
        myTotalValue: Double = 0,
        theirTotalValue: Double = 0,
        fairnessScore: Double = 1.0
    ) {
        self.id = id
        self.date = date
        self.contactId = contactId
        self.contactName = contactName
        self.eventName = eventName
        self.notes = notes
        self.myCardsJSON = myCardsJSON
        self.theirCardsJSON = theirCardsJSON
        self.myTotalValue = myTotalValue
        self.theirTotalValue = theirTotalValue
        self.fairnessScore = fairnessScore
    }

    // MARK: - Computed Properties

    /// Value difference (positive = in your favor)
    public var valueDifference: Double {
        myTotalValue - theirTotalValue
    }

    /// Whether the trade was fair (within 10% value difference)
    public var isFairTrade: Bool {
        let total = myTotalValue + theirTotalValue
        guard total > 0 else { return true }
        return abs(valueDifference) / total < 0.1
    }
}
