import Foundation
import SwiftData

/// Tracks sync state for local data with Supabase backend
@Model
final class SyncState {
    // MARK: - Identification

    @Attribute(.unique) var id: UUID

    /// Entity type being synced (e.g., "InventoryCard", "SalesHistory")
    var entityType: String

    /// ID of the entity in local database
    var entityId: String

    // MARK: - Sync Status

    /// Current sync status
    var status: SyncStatus

    /// Last successful sync timestamp
    var lastSyncedAt: Date?

    /// Last attempt timestamp (regardless of success)
    var lastAttemptAt: Date?

    /// Number of failed sync attempts
    var failureCount: Int

    /// Last error message (if sync failed)
    var lastError: String?

    // MARK: - Change Tracking

    /// Whether local data has changed since last sync
    var isDirty: Bool

    /// Type of change that needs to be synced
    var changeType: ChangeType

    /// When this entity was last modified locally
    var modifiedAt: Date

    // MARK: - Conflict Resolution

    /// Version number for optimistic locking
    var version: Int

    /// Whether this entity has a conflict with remote
    var hasConflict: Bool

    /// Remote version that conflicts (if any)
    var conflictVersion: Int?

    // MARK: - Initialization

    init(
        entityType: String,
        entityId: String,
        changeType: ChangeType = .created,
        isDirty: Bool = true
    ) {
        self.id = UUID()
        self.entityType = entityType
        self.entityId = entityId
        self.status = .pending
        self.failureCount = 0
        self.isDirty = isDirty
        self.changeType = changeType
        self.modifiedAt = Date()
        self.version = 1
        self.hasConflict = false
    }
}

// MARK: - Sync Status

enum SyncStatus: String, Codable, Sendable {
    /// Waiting to be synced
    case pending

    /// Currently syncing
    case syncing

    /// Successfully synced
    case synced

    /// Sync failed (will retry)
    case failed

    /// Conflict detected (needs manual resolution)
    case conflict

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .syncing: return "Syncing..."
        case .synced: return "Synced"
        case .failed: return "Failed"
        case .conflict: return "Conflict"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .conflict: return "arrow.triangle.branch"
        }
    }
}

// MARK: - Change Type

enum ChangeType: String, Codable, Sendable {
    /// Entity was created locally
    case created

    /// Entity was updated locally
    case updated

    /// Entity was deleted locally
    case deleted

    var displayName: String {
        switch self {
        case .created: return "Created"
        case .updated: return "Updated"
        case .deleted: return "Deleted"
        }
    }
}

// MARK: - Extensions

extension SyncState {
    /// Whether sync should be retried
    var shouldRetry: Bool {
        status == .failed && failureCount < 3
    }

    /// Whether this sync has permanently failed
    var hasPermanentlyFailed: Bool {
        status == .failed && failureCount >= 3
    }

    /// Time since last sync attempt
    var timeSinceLastAttempt: TimeInterval? {
        lastAttemptAt?.timeIntervalSinceNow
    }

    /// Mark as successfully synced
    func markSynced() {
        status = .synced
        isDirty = false
        lastSyncedAt = Date()
        lastAttemptAt = Date()
        failureCount = 0
        lastError = nil
        hasConflict = false
        version += 1
    }

    /// Mark as failed with error
    func markFailed(error: String) {
        status = .failed
        lastAttemptAt = Date()
        failureCount += 1
        lastError = error
    }

    /// Mark as having conflict
    func markConflict(remoteVersion: Int) {
        status = .conflict
        hasConflict = true
        conflictVersion = remoteVersion
    }

    /// Reset for retry
    func resetForRetry() {
        status = .pending
        lastError = nil
    }
}

// MARK: - Sync Priority

extension SyncState {
    /// Priority for sync queue (higher = more important)
    var syncPriority: Int {
        // Deletions have highest priority
        if changeType == .deleted {
            return 100
        }

        // Failed items get lower priority with each failure
        if status == .failed {
            return max(0, 50 - (failureCount * 10))
        }

        // Newer changes have higher priority
        let age = Date().timeIntervalSince(modifiedAt)
        if age < 60 { // Less than 1 minute
            return 80
        } else if age < 300 { // Less than 5 minutes
            return 60
        } else if age < 3600 { // Less than 1 hour
            return 40
        } else {
            return 20
        }
    }
}
