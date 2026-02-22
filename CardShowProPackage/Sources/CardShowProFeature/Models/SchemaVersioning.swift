import Foundation
import SwiftData

// MARK: - Schema V1 (Initial Release)

/// Captures the current data model as the baseline version.
/// When making model changes in the future, create SchemaV2 with the new
/// model definitions and add a migration stage to CardShowProMigrationPlan.
public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    public static var models: [any PersistentModel.Type] {
        [
            InventoryCard.self,
            Transaction.self,
            Contact.self,
            Event.self,
            WishlistItem.self,
            PriceCacheEntry.self,
            ListingTemplate.self,
            TradeRecord.self
        ]
    }
}

// MARK: - Migration Plan

/// Manages data migrations between schema versions.
///
/// Usage for future migrations:
/// 1. Create SchemaV2 enum with updated model definitions
/// 2. Add SchemaV2.self to the `schemas` array
/// 3. Add a MigrationStage to `stages` describing the V1 → V2 changes
///
/// Example:
/// ```
/// enum SchemaV2: VersionedSchema {
///     static var versionIdentifier = Schema.Version(2, 0, 0)
///     static var models: [any PersistentModel.Type] { [...] }
///
///     @Model final class InventoryCard { /* updated fields */ }
/// }
///
/// static var stages: [MigrationStage] {
///     [migrateV1toV2]
/// }
///
/// static let migrateV1toV2 = MigrationStage.lightweight(
///     fromVersion: SchemaV1.self,
///     toVersion: SchemaV2.self
/// )
/// ```
public enum CardShowProMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        // No migrations yet - V1 is the initial release
        []
    }
}
