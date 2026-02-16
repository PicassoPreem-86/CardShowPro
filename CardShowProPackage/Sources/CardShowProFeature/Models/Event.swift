import Foundation
import SwiftData

// MARK: - Event Model

/// Persistent model for card show / vendor events.
/// Tracks costs, timing, and links to transactions via `eventName`.
@Model
public final class Event {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var date: Date
    public var venue: String
    public var tableCost: Double
    public var travelCost: Double
    public var isActive: Bool
    public var startedAt: Date?
    public var endedAt: Date?
    public var notes: String

    public init(
        id: UUID = UUID(),
        name: String,
        date: Date = Date(),
        venue: String,
        tableCost: Double = 0,
        travelCost: Double = 0,
        isActive: Bool = false,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.venue = venue
        self.tableCost = tableCost
        self.travelCost = travelCost
        self.isActive = isActive
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.notes = notes
    }

    // MARK: - Computed Properties

    /// Whether the event has been completed (has an end time)
    public var isCompleted: Bool {
        endedAt != nil
    }

    /// Total fixed costs (table + travel)
    public var fixedCosts: Double {
        tableCost + travelCost
    }

    /// Duration of the event from start to end (or start to now if still active)
    public var duration: TimeInterval? {
        guard let start = startedAt else { return nil }
        let end = endedAt ?? Date()
        return end.timeIntervalSince(start)
    }

    /// Formatted duration string (e.g. "3h 42m")
    public var formattedDuration: String {
        guard let duration else { return "--" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Formatted date for display
    public var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
