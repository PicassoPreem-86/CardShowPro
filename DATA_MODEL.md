# CardShow Pro - Data Model Documentation

**Version:** 1.0
**Last Updated:** January 13, 2026
**Document Owner:** Engineering Team
**Status:** Active Development

---

## Table of Contents

1. [Overview](#overview)
2. [Database Technology](#database-technology)
3. [Entity Relationship Diagram](#entity-relationship-diagram)
4. [Core Entities](#core-entities)
5. [Relationships](#relationships)
6. [Data Validation Rules](#data-validation-rules)
7. [Migration Strategy](#migration-strategy)
8. [Query Patterns](#query-patterns)
9. [Data Export/Import](#data-exportimport)
10. [Backup & Recovery](#backup--recovery)
11. [Performance Optimization](#performance-optimization)

---

## Overview

CardShow Pro uses **SwiftData** for local persistence. All data is stored on-device with optional cloud sync in future versions.

### Design Principles

1. **Offline-First** - App works fully without internet connection
2. **Fast Queries** - Indexed fields for common searches
3. **Data Integrity** - Validation rules prevent corrupt data
4. **Easy Migration** - Schema changes managed with versioning
5. **Privacy-First** - All data stays on user's device

### Data Architecture

```
User's iPhone
├── SwiftData Container (on-device storage)
│   ├── InventoryCard (main entity)
│   ├── TradeHistory (transactions)
│   ├── Contact (CRM)
│   ├── Event (vendor mode)
│   └── CachedPrice (API cache)
└── UserDefaults (settings)
```

---

## Database Technology

### SwiftData vs CoreData

**Why SwiftData:**
- ✅ Modern Swift-first API
- ✅ Type-safe queries with macros
- ✅ Automatic CloudKit sync (future)
- ✅ Easier migrations
- ✅ Better SwiftUI integration

**Not CoreData because:**
- ❌ Objective-C legacy
- ❌ Complex migration process
- ❌ Verbose syntax

### SwiftData Basics

```swift
import SwiftData

// Define model with @Model macro
@Model
final class InventoryCard {
    var name: String
    var setName: String
    var marketValue: Double

    init(name: String, setName: String, marketValue: Double) {
        self.name = name
        self.setName = setName
        self.marketValue = marketValue
    }
}

// Add to app
@main
struct CardShowProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: InventoryCard.self)
        }
    }
}

// Query in views
struct InventoryView: View {
    @Query private var cards: [InventoryCard]
    @Environment(\.modelContext) private var context

    var body: some View {
        List(cards) { card in
            Text(card.name)
        }
    }
}
```

---

## Entity Relationship Diagram

```
┌─────────────────┐
│  InventoryCard  │ (Core entity)
├─────────────────┤
│ id: UUID        │
│ name: String    │
│ setName: String │
│ cardNumber: String
│ variant: String │
│ condition: String
│ purchaseCost: Double?
│ marketValue: Double
│ acquiredDate: Date
│ acquiredFrom: String?
│ imageURL: String?
│ notes: String?  │
│ tags: [String]  │
└─────────────────┘
         │
         │ One-to-Many
         ▼
┌─────────────────┐
│  TradeHistory   │
├─────────────────┤
│ id: UUID        │
│ date: Date      │
│ tradePercentage: Double
│ myCardsTotal: Double
│ theirCardsTotal: Double
│ notes: String?  │
│ → cards: [InventoryCard]
└─────────────────┘

┌─────────────────┐
│  SalesHistory   │
├─────────────────┤
│ id: UUID        │
│ date: Date      │
│ salePrice: Double
│ platformFees: Double
│ netProfit: Double
│ platform: String
│ → card: InventoryCard
└─────────────────┘

┌─────────────────┐
│     Event       │ (Vendor Mode)
├─────────────────┤
│ id: UUID        │
│ name: String    │
│ date: Date      │
│ location: String│
│ totalRevenue: Double
│ totalProfit: Double
│ → sales: [Sale] │
│ → trades: [Trade]
└─────────────────┘

┌─────────────────┐
│    Contact      │ (CRM)
├─────────────────┤
│ id: UUID        │
│ name: String    │
│ phone: String?  │
│ email: String?  │
│ role: ContactRole
│ metAt: String?  │
│ notes: String?  │
│ → wantList: [WantListItem]
│ → purchases: [Sale]
└─────────────────┘

┌─────────────────┐
│  WantListItem   │
├─────────────────┤
│ id: UUID        │
│ cardName: String│
│ maxPrice: Double?
│ priority: Priority
│ → contact: Contact
└─────────────────┘

┌─────────────────┐
│  CachedPrice    │ (API Cache)
├─────────────────┤
│ id: UUID        │
│ cardId: String  │
│ marketPrice: Double
│ lowPrice: Double
│ midPrice: Double
│ highPrice: Double
│ timestamp: Date │
│ source: String  │
└─────────────────┘

┌─────────────────┐
│ GradingSubmission│
├─────────────────┤
│ id: UUID        │
│ company: GradingCompany
│ submissionDate: Date
│ expectedReturn: Date?
│ cost: Double    │
│ status: Status  │
│ → cards: [InventoryCard]
└─────────────────┘
```

---

## Core Entities

### 1. InventoryCard

**Purpose:** Primary entity representing a trading card in business inventory

```swift
import SwiftData
import Foundation

@Model
final class InventoryCard {
    // Identification
    @Attribute(.unique) var id: UUID
    var name: String
    var setName: String
    var cardNumber: String
    var variant: String // "Normal", "Holo", "Reverse Holo", etc.
    var condition: CardCondition // Enum: NM, LP, MP, HP

    // Pricing & Profit
    var purchaseCost: Double?
    var marketValue: Double
    var lastPriceUpdate: Date

    // Acquisition
    var acquiredDate: Date
    var acquiredFrom: String? // "Trade", "Target", "Card Show", etc.

    // Media
    var imageURL: String?
    var localImagePath: String? // Path to cached image

    // Metadata
    var notes: String?
    var tags: [String] // ["Featured", "High Value", etc.]

    // Grading
    var isGraded: Bool
    var gradingCompany: String? // "PSA", "BGS", "CGC"
    var grade: Int? // 1-10
    var certNumber: String?

    // Relationships
    @Relationship(deleteRule: .nullify) var sales: [SalesHistory]?
    @Relationship(deleteRule: .nullify) var trades: [TradeHistory]?

    // Computed Properties
    var profit: Double {
        guard let cost = purchaseCost else { return 0 }
        return marketValue - cost
    }

    var profitMargin: Double {
        guard let cost = purchaseCost, cost > 0 else { return 0 }
        return (marketValue - cost) / cost
    }

    var roi: Double {
        profitMargin * 100
    }

    var displayName: String {
        "\(name) #\(cardNumber)"
    }

    init(
        name: String,
        setName: String,
        cardNumber: String,
        variant: String = "Normal",
        condition: CardCondition = .nearMint,
        marketValue: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.setName = setName
        self.cardNumber = cardNumber
        self.variant = variant
        self.condition = condition
        self.marketValue = marketValue
        self.acquiredDate = Date()
        self.lastPriceUpdate = Date()
        self.isGraded = false
    }
}

// Enums
enum CardCondition: String, Codable {
    case nearMint = "Near Mint"
    case lightlyPlayed = "Lightly Played"
    case moderatelyPlayed = "Moderately Played"
    case heavilyPlayed = "Heavily Played"
    case damaged = "Damaged"

    var abbreviation: String {
        switch self {
        case .nearMint: return "NM"
        case .lightlyPlayed: return "LP"
        case .moderatelyPlayed: return "MP"
        case .heavilyPlayed: return "HP"
        case .damaged: return "DMG"
        }
    }
}
```

**Indexes:**
- `id` (unique, primary)
- `name` (text search)
- `acquiredDate` (sorting)
- `marketValue` (filtering by value)

---

### 2. SalesHistory

**Purpose:** Track when cards are sold, platform, pricing, and profit

```swift
@Model
final class SalesHistory {
    @Attribute(.unique) var id: UUID
    var date: Date
    var salePrice: Double
    var platformFees: Double
    var shippingCost: Double
    var netProfit: Double
    var platform: String // "eBay", "TCGPlayer", "In-Person", etc.
    var buyerName: String?
    var notes: String?

    // Relationships
    @Relationship(inverse: \InventoryCard.sales) var card: InventoryCard?
    @Relationship(inverse: \Event.sales) var event: Event? // If sold at event

    // Computed
    var totalCosts: Double {
        platformFees + shippingCost
    }

    init(
        salePrice: Double,
        platformFees: Double = 0,
        shippingCost: Double = 0,
        platform: String,
        card: InventoryCard? = nil
    ) {
        self.id = UUID()
        self.date = Date()
        self.salePrice = salePrice
        self.platformFees = platformFees
        self.shippingCost = shippingCost
        self.netProfit = salePrice - platformFees - shippingCost
        self.platform = platform
        self.card = card
    }
}
```

---

### 3. TradeHistory

**Purpose:** Record trades with trade percentage and values

```swift
@Model
final class TradeHistory {
    @Attribute(.unique) var id: UUID
    var date: Date
    var tradePercentage: Double // 0.80 = 80%
    var myCardsTotal: Double // At market value
    var theirCardsTotal: Double // At market value
    var theirCardsTradeValue: Double // After percentage discount
    var notes: String?

    // Relationships
    @Relationship(deleteRule: .nullify) var cardsTraded: [InventoryCard]? // Cards I gave away
    @Relationship(deleteRule: .nullify) var cardsReceived: [InventoryCard]? // Cards I got

    // Computed
    var isBalanced: Bool {
        abs(myCardsTotal - theirCardsTradeValue) < 1.0 // Within $1
    }

    var differential: Double {
        myCardsTotal - theirCardsTradeValue
    }

    init(
        tradePercentage: Double = 0.80,
        myCardsTotal: Double,
        theirCardsTotal: Double
    ) {
        self.id = UUID()
        self.date = Date()
        self.tradePercentage = tradePercentage
        self.myCardsTotal = myCardsTotal
        self.theirCardsTotal = theirCardsTotal
        self.theirCardsTradeValue = theirCardsTotal * tradePercentage
    }
}
```

---

### 4. Event (Vendor Mode)

**Purpose:** Track card show events, sales, and performance

```swift
@Model
final class Event {
    @Attribute(.unique) var id: UUID
    var name: String
    var date: Date
    var location: String
    var tableNumber: String?
    var notes: String?

    // Event status
    var isActive: Bool // Currently running
    var startTime: Date?
    var endTime: Date?

    // Financial summary
    var totalRevenue: Double
    var totalProfit: Double
    var cardsCount: Int // Cards brought to show
    var cardsSold: Int

    // Relationships
    @Relationship(deleteRule: .cascade) var sales: [SalesHistory]?
    @Relationship(deleteRule: .cascade) var trades: [TradeHistory]?
    @Relationship(deleteRule: .nullify) var inventory: [InventoryCard]? // Cards brought

    // Computed
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }

    var averageSale: Double {
        guard cardsSold > 0 else { return 0 }
        return totalRevenue / Double(cardsSold)
    }

    var sellThroughRate: Double {
        guard cardsCount > 0 else { return 0 }
        return Double(cardsSold) / Double(cardsCount)
    }

    init(name: String, date: Date, location: String) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.location = location
        self.isActive = false
        self.totalRevenue = 0
        self.totalProfit = 0
        self.cardsCount = 0
        self.cardsSold = 0
    }
}
```

---

### 5. Contact (CRM)

**Purpose:** Track customers, vendors, distributors with purchase history and want lists

```swift
@Model
final class Contact {
    @Attribute(.unique) var id: UUID
    var name: String
    var phone: String?
    var email: String?
    var role: ContactRole // Customer, Vendor, Distributor
    var priority: ContactPriority // High, Medium, Low

    // Metadata
    var metAt: String? // "Phoenix Card Show", "Facebook"
    var metDate: Date?
    var notes: String?

    // Relationships
    @Relationship(deleteRule: .cascade) var wantList: [WantListItem]?
    @Relationship(deleteRule: .nullify) var purchases: [SalesHistory]?

    // Computed
    var totalPurchases: Double {
        purchases?.reduce(0) { $0 + $1.salePrice } ?? 0
    }

    var purchaseCount: Int {
        purchases?.count ?? 0
    }

    init(name: String, role: ContactRole, priority: ContactPriority = .medium) {
        self.id = UUID()
        self.name = name
        self.role = role
        self.priority = priority
        self.metDate = Date()
    }
}

enum ContactRole: String, Codable {
    case customer = "Customer"
    case vendor = "Vendor"
    case distributor = "Distributor"
}

enum ContactPriority: String, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}
```

---

### 6. WantListItem

**Purpose:** Track what cards customers are looking for (alert system)

```swift
@Model
final class WantListItem {
    @Attribute(.unique) var id: UUID
    var cardName: String
    var setName: String?
    var variant: String?
    var maxPrice: Double?
    var priority: ContactPriority
    var notes: String?
    var createdDate: Date

    // Relationships
    @Relationship(inverse: \Contact.wantList) var contact: Contact?

    // Computed
    var isMatch: Bool {
        // Will be set to true when matching card added to inventory
        false // Placeholder
    }

    init(cardName: String, priority: ContactPriority = .medium) {
        self.id = UUID()
        self.cardName = cardName
        self.priority = priority
        self.createdDate = Date()
    }
}
```

---

### 7. CachedPrice

**Purpose:** Cache API pricing data to reduce API calls

```swift
@Model
final class CachedPrice {
    @Attribute(.unique) var cardId: String // API card ID
    var marketPrice: Double
    var lowPrice: Double
    var midPrice: Double
    var highPrice: Double
    var timestamp: Date
    var source: String // "PokemonTCG.io", "TCGDex"

    // Computed
    var isExpired: Bool {
        let hoursSinceUpdate = Date().timeIntervalSince(timestamp) / 3600
        return hoursSinceUpdate > 24 // Expire after 24 hours
    }

    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }

    init(
        cardId: String,
        marketPrice: Double,
        lowPrice: Double,
        midPrice: Double,
        highPrice: Double,
        source: String
    ) {
        self.cardId = cardId
        self.marketPrice = marketPrice
        self.lowPrice = lowPrice
        self.midPrice = midPrice
        self.highPrice = highPrice
        self.timestamp = Date()
        self.source = source
    }
}
```

---

### 8. GradingSubmission

**Purpose:** Track cards sent to PSA/BGS/CGC for grading

```swift
@Model
final class GradingSubmission {
    @Attribute(.unique) var id: UUID
    var company: GradingCompany
    var submissionDate: Date
    var expectedReturnDate: Date?
    var actualReturnDate: Date?
    var totalCost: Double
    var status: GradingStatus
    var trackingNumber: String?
    var notes: String?

    // Relationships
    @Relationship(deleteRule: .nullify) var cards: [InventoryCard]?

    // Computed
    var isOverdue: Bool {
        guard let expected = expectedReturnDate, actualReturnDate == nil else {
            return false
        }
        return Date() > expected
    }

    var daysOut: Int {
        let days = Date().timeIntervalSince(submissionDate) / 86400
        return Int(days)
    }

    var cardCount: Int {
        cards?.count ?? 0
    }

    var costPerCard: Double {
        guard cardCount > 0 else { return 0 }
        return totalCost / Double(cardCount)
    }

    init(
        company: GradingCompany,
        totalCost: Double,
        expectedReturnDate: Date? = nil
    ) {
        self.id = UUID()
        self.company = company
        self.submissionDate = Date()
        self.expectedReturnDate = expectedReturnDate
        self.totalCost = totalCost
        self.status = .submitted
    }
}

enum GradingCompany: String, Codable {
    case psa = "PSA"
    case bgs = "BGS"
    case cgc = "CGC"
    case sgc = "SGC"
}

enum GradingStatus: String, Codable {
    case preparing = "Preparing"
    case submitted = "Submitted"
    case received = "Received by Grader"
    case grading = "In Grading"
    case shipped = "Shipped Back"
    case returned = "Returned"
}
```

---

## Relationships

### Relationship Rules

| Entity | Related To | Relationship Type | Delete Rule |
|--------|-----------|------------------|-------------|
| **InventoryCard** → **SalesHistory** | One-to-Many | `.nullify` | Sales remain for history |
| **InventoryCard** → **TradeHistory** | Many-to-Many | `.nullify` | Trades remain for history |
| **Contact** → **WantListItem** | One-to-Many | `.cascade` | Delete want list with contact |
| **Contact** → **SalesHistory** | One-to-Many | `.nullify` | Sales remain |
| **Event** → **SalesHistory** | One-to-Many | `.cascade` | Delete sales with event |
| **Event** → **InventoryCard** | Many-to-Many | `.nullify` | Cards stay in inventory |
| **GradingSubmission** → **InventoryCard** | Many-to-Many | `.nullify` | Cards stay |

### Delete Rules Explained

**`.cascade`** - Delete related objects
```swift
// Deleting a Contact also deletes all WantListItems
contact.delete()
→ All WantListItem records for that contact are deleted
```

**`.nullify`** - Keep related objects, null the relationship
```swift
// Deleting a Card keeps the SalesHistory
card.delete()
→ SalesHistory.card = nil (but SalesHistory record remains)
```

---

## Data Validation Rules

### Field Constraints

```swift
extension InventoryCard {
    func validate() throws {
        // Name required
        guard !name.isEmpty else {
            throw ValidationError.emptyName
        }

        // Set name required
        guard !setName.isEmpty else {
            throw ValidationError.emptySetName
        }

        // Card number required
        guard !cardNumber.isEmpty else {
            throw ValidationError.emptyCardNumber
        }

        // Market value must be non-negative
        guard marketValue >= 0 else {
            throw ValidationError.negativeMarketValue
        }

        // Purchase cost (if set) must be non-negative
        if let cost = purchaseCost {
            guard cost >= 0 else {
                throw ValidationError.negativePurchaseCost
            }
        }

        // Grade must be 1-10 if graded
        if isGraded, let grade = grade {
            guard (1...10).contains(grade) else {
                throw ValidationError.invalidGrade
            }
        }
    }
}

enum ValidationError: Error {
    case emptyName
    case emptySetName
    case emptyCardNumber
    case negativeMarketValue
    case negativePurchaseCost
    case invalidGrade
}
```

### Automatic Validation

```swift
@Model
final class InventoryCard {
    @Attribute(.validate { value in
        !value.isEmpty
    })
    var name: String

    @Attribute(.validate { value in
        value >= 0
    })
    var marketValue: Double
}
```

---

## Migration Strategy

### Schema Versioning

**V1 (Initial):**
- InventoryCard
- SalesHistory
- CachedPrice

**V2 (Vendor Mode):**
- Event
- TradeHistory

**V3 (CRM):**
- Contact
- WantListItem

**V4 (Grading):**
- GradingSubmission

### Migration Example

```swift
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [InventoryCard.self, SalesHistory.self, CachedPrice.self]
    }

    @Model
    final class InventoryCard {
        var name: String
        var marketValue: Double
        // V1 fields only
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [InventoryCard.self, SalesHistory.self, CachedPrice.self,
         Event.self, TradeHistory.self]
    }

    @Model
    final class InventoryCard {
        var name: String
        var marketValue: Double
        var tags: [String] = [] // NEW in V2
    }
}

// Migration plan
let migrationPlan = SchemaMigrationPlan(
    schemas: [SchemaV1.self, SchemaV2.self],
    stages: [
        // V1 → V2
        MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
    ]
)

// Apply in app
.modelContainer(for: InventoryCard.self, migrationPlan: migrationPlan)
```

### Lightweight vs Custom Migrations

**Lightweight (Preferred):**
- Adding new fields with default values
- Making fields optional
- Renaming fields (with renaming hint)

**Custom (When Required):**
- Complex data transformations
- Splitting one field into multiple
- Combining multiple fields into one

---

## Query Patterns

### Common Queries

#### 1. Get All Inventory Cards

```swift
@Query private var cards: [InventoryCard]
```

#### 2. Filter by Value Range

```swift
@Query(
    filter: #Predicate<InventoryCard> { card in
        card.marketValue >= 100 && card.marketValue <= 500
    },
    sort: \InventoryCard.marketValue,
    order: .reverse
)
private var highValueCards: [InventoryCard]
```

#### 3. Search by Name

```swift
@Query(
    filter: #Predicate<InventoryCard> { card in
        card.name.localizedStandardContains(searchText)
    }
)
private var searchResults: [InventoryCard]
```

#### 4. Get Cards Acquired This Month

```swift
let calendar = Calendar.current
let startOfMonth = calendar.dateInterval(of: .month, for: Date())!.start

@Query(
    filter: #Predicate<InventoryCard> { card in
        card.acquiredDate >= startOfMonth
    },
    sort: \InventoryCard.acquiredDate,
    order: .reverse
)
private var thisMonthCards: [InventoryCard]
```

#### 5. Get Top 10 Most Profitable Cards

```swift
let descriptor = FetchDescriptor<InventoryCard>(
    sortBy: [SortDescriptor(\.marketValue, order: .reverse)]
)
descriptor.fetchLimit = 10

let topCards = try context.fetch(descriptor)
```

#### 6. Calculate Total Inventory Value

```swift
let descriptor = FetchDescriptor<InventoryCard>()
let allCards = try context.fetch(descriptor)
let totalValue = allCards.reduce(0) { $0 + $1.marketValue }
```

#### 7. Get Graded Cards Only

```swift
@Query(
    filter: #Predicate<InventoryCard> { $0.isGraded == true }
)
private var gradedCards: [InventoryCard]
```

#### 8. Get Events from Last 3 Months

```swift
let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!

@Query(
    filter: #Predicate<Event> { event in
        event.date >= threeMonthsAgo
    },
    sort: \Event.date,
    order: .reverse
)
private var recentEvents: [Event]
```

---

## Data Export/Import

### Export to JSON

```swift
struct InventoryExport: Codable {
    let exportDate: Date
    let version: String
    let cards: [CardExport]

    struct CardExport: Codable {
        let name: String
        let setName: String
        let cardNumber: String
        let variant: String
        let condition: String
        let purchaseCost: Double?
        let marketValue: Double
        let acquiredDate: Date
    }
}

func exportInventory() throws -> Data {
    let descriptor = FetchDescriptor<InventoryCard>()
    let cards = try context.fetch(descriptor)

    let export = InventoryExport(
        exportDate: Date(),
        version: "1.0",
        cards: cards.map { card in
            InventoryExport.CardExport(
                name: card.name,
                setName: card.setName,
                cardNumber: card.cardNumber,
                variant: card.variant,
                condition: card.condition.rawValue,
                purchaseCost: card.purchaseCost,
                marketValue: card.marketValue,
                acquiredDate: card.acquiredDate
            )
        }
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = .prettyPrinted

    return try encoder.encode(export)
}
```

### Import from JSON

```swift
func importInventory(from data: Data) throws {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let export = try decoder.decode(InventoryExport.self, from: data)

    for cardData in export.cards {
        let card = InventoryCard(
            name: cardData.name,
            setName: cardData.setName,
            cardNumber: cardData.cardNumber,
            variant: cardData.variant,
            condition: CardCondition(rawValue: cardData.condition) ?? .nearMint,
            marketValue: cardData.marketValue
        )
        card.purchaseCost = cardData.purchaseCost
        card.acquiredDate = cardData.acquiredDate

        context.insert(card)
    }

    try context.save()
}
```

### Export to CSV

```swift
func exportToCSV() -> String {
    let descriptor = FetchDescriptor<InventoryCard>()
    let cards = try? context.fetch(descriptor) ?? []

    var csv = "Name,Set,Number,Variant,Condition,Purchase Cost,Market Value,Profit,Acquired Date\n"

    for card in cards {
        let line = [
            card.name,
            card.setName,
            card.cardNumber,
            card.variant,
            card.condition.rawValue,
            card.purchaseCost?.description ?? "",
            card.marketValue.description,
            card.profit.description,
            ISO8601DateFormatter().string(from: card.acquiredDate)
        ].joined(separator: ",")

        csv += line + "\n"
    }

    return csv
}
```

---

## Backup & Recovery

### iCloud Backup (Automatic)

SwiftData containers are automatically backed up to iCloud.

**Enable in entitlements:**
```xml
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

### Manual Backup

```swift
func backupDatabase() throws -> URL {
    let container = try ModelContainer(for: InventoryCard.self)
    let fileURL = container.configurations.first?.url

    guard let sourceURL = fileURL else {
        throw BackupError.noDatabase
    }

    // Copy to Documents directory
    let documentsURL = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!

    let backupURL = documentsURL.appendingPathComponent("backup_\(Date().timeIntervalSince1970).sqlite")

    try FileManager.default.copyItem(at: sourceURL, to: backupURL)

    return backupURL
}
```

### Restore from Backup

```swift
func restoreDatabase(from backupURL: URL) throws {
    let container = try ModelContainer(for: InventoryCard.self)
    let currentURL = container.configurations.first?.url

    guard let destinationURL = currentURL else {
        throw BackupError.noDatabase
    }

    // Delete current database
    try FileManager.default.removeItem(at: destinationURL)

    // Copy backup
    try FileManager.default.copyItem(at: backupURL, to: destinationURL)

    // Restart app required
}
```

---

## Performance Optimization

### Indexes

```swift
@Model
final class InventoryCard {
    @Attribute(.unique) var id: UUID

    // Index for text search
    @Attribute(.index) var name: String

    // Index for sorting
    @Attribute(.index) var marketValue: Double
    @Attribute(.index) var acquiredDate: Date
}
```

### Batch Operations

```swift
// ✅ GOOD: Batch update
let descriptor = FetchDescriptor<InventoryCard>()
let cards = try context.fetch(descriptor)

for card in cards {
    card.lastPriceUpdate = Date()
}

try context.save() // Single save

// ❌ BAD: Save in loop
for card in cards {
    card.lastPriceUpdate = Date()
    try context.save() // Multiple saves = slow
}
```

### Fetch Limits

```swift
// Fetch only what you need
var descriptor = FetchDescriptor<InventoryCard>()
descriptor.fetchLimit = 50
descriptor.includePendingChanges = false // Faster
```

### Lazy Loading Relationships

```swift
// Don't fetch relationships unless needed
@Relationship(deleteRule: .cascade, minimumModelCount: 0)
var sales: [SalesHistory]?

// Access only when required
if let sales = card.sales {
    // Process sales
}
```

---

## Summary

This data model provides:

✅ **Complete Business Logic** - All entities needed for V1-V4
✅ **Type-Safe Queries** - SwiftData predicates prevent runtime errors
✅ **Easy Migrations** - Versioned schemas support schema evolution
✅ **Performance** - Indexed fields and batch operations
✅ **Data Integrity** - Validation rules and relationship constraints
✅ **Export/Import** - JSON and CSV support for data portability
✅ **Backup/Recovery** - iCloud + manual backup options

**Next Steps:**
1. Implement core entities in V1 (InventoryCard, SalesHistory, CachedPrice)
2. Add migrations for V2 (Event, TradeHistory)
3. Expand to V3 (Contact, WantListItem)
4. Test with 10,000+ cards for performance validation

---

*For questions about the data model, contact the Engineering Team.*
