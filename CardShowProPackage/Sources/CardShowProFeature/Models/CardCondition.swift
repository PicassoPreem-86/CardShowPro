import Foundation

/// Card condition with corresponding price multipliers
public enum CardCondition: String, CaseIterable, Sendable {
    case mint = "Mint"
    case nearMint = "Near Mint"
    case excellent = "Excellent"
    case good = "Good"
    case played = "Played"
    case poor = "Poor"

    /// Price multiplier based on condition
    var multiplier: Double {
        switch self {
        case .mint: return 1.2        // 20% premium for mint
        case .nearMint: return 1.0    // Baseline (market price)
        case .excellent: return 0.9   // 10% discount
        case .good: return 0.75       // 25% discount
        case .played: return 0.6      // 40% discount
        case .poor: return 0.4        // 60% discount
        }
    }

    /// User-friendly display name
    var displayName: String {
        rawValue
    }

    /// SF Symbol icon for each condition
    var icon: String {
        switch self {
        case .mint: return "star.circle.fill"
        case .nearMint: return "star.circle"
        case .excellent: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .played: return "circle.dotted"
        case .poor: return "xmark.circle"
        }
    }
}
