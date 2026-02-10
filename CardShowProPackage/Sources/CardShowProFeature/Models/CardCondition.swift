import Foundation

/// Card condition grades based on TCGPlayer grading standards
enum CardCondition: String, CaseIterable, Sendable {
    case mint = "Mint"
    case nearMint = "Near Mint"
    case excellent = "Lightly Played"
    case good = "Moderately Played"
    case played = "Heavily Played"
    case poor = "Damaged"

    /// Price multipliers based on TCGPlayer market research (January 2025)
    /// Near Mint is baseline (1.0x), other conditions are percentage reductions
    var priceMultiplier: Double {
        switch self {
        case .mint: return 1.15           // Premium for pristine cards (15% above NM)
        case .nearMint: return 1.0        // Baseline - TCGPlayer standard
        case .excellent: return 0.80      // Lightly Played - 20% reduction
        case .good: return 0.60           // Moderately Played - 40% reduction
        case .played: return 0.30         // Heavily Played - 70% reduction
        case .poor: return 0.15           // Damaged - 85% reduction
        }
    }
}
