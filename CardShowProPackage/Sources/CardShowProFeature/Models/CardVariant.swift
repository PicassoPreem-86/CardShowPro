import Foundation

/// Trading card variants (simplified for vendor speed)
enum CardVariant: String, CaseIterable, Sendable {
    case standard = "Standard"
    case holo = "Holo"
    case reverseHolo = "Reverse Holo"
    case promo = "Promo"
    case fullArt = "Full Art"
    case special = "Special"

    var displayName: String { rawValue }

    var priceMultiplier: Double {
        switch self {
        case .standard: return 1.0
        case .holo: return 1.5
        case .reverseHolo: return 1.3
        case .promo: return 2.0
        case .fullArt: return 3.0
        case .special: return 2.5  // Covers: Gold Star, Secret Rare, Alt Art, etc.
        }
    }

    var icon: String {
        switch self {
        case .standard: return "rectangle"
        case .holo: return "sparkles"
        case .reverseHolo: return "arrow.triangle.2.circlepath"
        case .promo: return "star.circle"
        case .fullArt: return "photo"
        case .special: return "star.fill"
        }
    }
}
