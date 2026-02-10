import Foundation
import SwiftUI

// MARK: - PricePoint (Price History)

/// A single price point in a price history chart
struct PricePoint: Identifiable, Sendable {
    let p: Double   // price
    let t: Int       // unix timestamp

    var id: Int { t }

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(t))
    }

    var price: Double { p }
}

// MARK: - PriceCondition

/// Card condition levels for pricing
enum PriceCondition: String, CaseIterable, Identifiable, Sendable {
    case nearMint = "Near Mint"
    case lightlyPlayed = "Lightly Played"
    case moderatelyPlayed = "Moderately Played"
    case heavilyPlayed = "Heavily Played"
    case damaged = "Damaged"

    var id: String { rawValue }

    var abbreviation: String {
        switch self {
        case .nearMint: return "NM"
        case .lightlyPlayed: return "LP"
        case .moderatelyPlayed: return "MP"
        case .heavilyPlayed: return "HP"
        case .damaged: return "DMG"
        }
    }

    /// Typical price multiplier relative to Near Mint
    var typicalMultiplier: Double {
        switch self {
        case .nearMint: return 1.0
        case .lightlyPlayed: return 0.80
        case .moderatelyPlayed: return 0.60
        case .heavilyPlayed: return 0.40
        case .damaged: return 0.25
        }
    }
}

// MARK: - PriceTrend

/// Visual trend indicator for price changes
enum PriceTrend {
    case rising
    case falling
    case stable

    var icon: String {
        switch self {
        case .rising: return "arrow.up.right"
        case .falling: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .rising: return .green
        case .falling: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - ConditionPrices

/// Pricing breakdown by card condition (from JustTCG)
struct ConditionPrices: Sendable {
    let nearMint: Double?
    let lightlyPlayed: Double?
    let moderatelyPlayed: Double?
    let heavilyPlayed: Double?
    let damaged: Double?

    init(
        nearMint: Double? = nil,
        lightlyPlayed: Double? = nil,
        moderatelyPlayed: Double? = nil,
        heavilyPlayed: Double? = nil,
        damaged: Double? = nil
    ) {
        self.nearMint = nearMint
        self.lightlyPlayed = lightlyPlayed
        self.moderatelyPlayed = moderatelyPlayed
        self.heavilyPlayed = heavilyPlayed
        self.damaged = damaged
    }

    /// Initialize from JustTCG condition price array
    init(from conditionPrices: [(condition: String, price: Double)]) {
        var nm: Double?
        var lp: Double?
        var mp: Double?
        var hp: Double?
        var dmg: Double?

        for (condition, price) in conditionPrices {
            let normalized = condition.lowercased()
            if normalized.contains("near mint") { nm = price }
            else if normalized.contains("lightly") { lp = price }
            else if normalized.contains("moderately") { mp = price }
            else if normalized.contains("heavily") { hp = price }
            else if normalized.contains("damaged") { dmg = price }
        }

        self.nearMint = nm
        self.lightlyPlayed = lp
        self.moderatelyPlayed = mp
        self.heavilyPlayed = hp
        self.damaged = dmg
    }

    func price(for condition: PriceCondition) -> Double? {
        switch condition {
        case .nearMint: return nearMint
        case .lightlyPlayed: return lightlyPlayed
        case .moderatelyPlayed: return moderatelyPlayed
        case .heavilyPlayed: return heavilyPlayed
        case .damaged: return damaged
        }
    }

    var availableConditions: [PriceCondition] {
        PriceCondition.allCases.filter { price(for: $0) != nil }
    }
}

// MARK: - RecentSearch

/// A recent card name search for quick re-lookup
struct RecentSearch: Identifiable, Sendable, Equatable {
    static func == (lhs: RecentSearch, rhs: RecentSearch) -> Bool {
        lhs.id == rhs.id
    }

    let id: UUID
    let cardName: String
    let timestamp: Date

    init(cardName: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.cardName = cardName
        self.timestamp = timestamp
    }
}

// MARK: - VariantPricing / VariantPrice

/// Codable variant pricing for cache storage
struct VariantPricing: Codable, Sendable {
    let normal: VariantPrice?
    let holofoil: VariantPrice?
    let reverseHolofoil: VariantPrice?
    let firstEdition: VariantPrice?
    let unlimited: VariantPrice?
}

struct VariantPrice: Codable, Sendable {
    let low: Double?
    let mid: Double?
    let high: Double?
    let market: Double?
}

// MARK: - DatabaseError

/// Errors from the local card database
enum DatabaseError: LocalizedError {
    case notInitialized
    case queryFailed(String)
    case importFailed(String)
    case corruptedData

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database not initialized"
        case .queryFailed(let message):
            return "Database query failed: \(message)"
        case .importFailed(let message):
            return "Database import failed: \(message)"
        case .corruptedData:
            return "Database data is corrupted"
        }
    }
}
