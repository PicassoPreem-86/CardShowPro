import Foundation

enum SellingPlatform: String, CaseIterable, Identifiable, Sendable {
    case ebay = "eBay"
    case tcgplayer = "TCGPlayer"
    case facebookMarketplace = "Facebook Marketplace"
    case stockx = "StockX"
    case inPerson = "In-Person Sale"
    case custom = "Custom Fees"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .ebay: return "bag.fill"
        case .tcgplayer: return "creditcard.fill"
        case .facebookMarketplace: return "person.2.fill"
        case .stockx: return "chart.line.uptrend.xyaxis"
        case .inPerson: return "hand.raised.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    var feeStructure: PlatformFees {
        switch self {
        case .ebay:
            return PlatformFees(
                platformFeePercentage: 0.1295,
                paymentFeePercentage: 0.029,
                paymentFeeFixed: 0.30,
                description: "eBay Managed Payments"
            )
        case .tcgplayer:
            return PlatformFees(
                platformFeePercentage: 0.1285,
                paymentFeePercentage: 0.029,
                paymentFeeFixed: 0.30,
                description: "TCGPlayer Mid-Tier"
            )
        case .facebookMarketplace:
            return PlatformFees(
                platformFeePercentage: 0.05,
                paymentFeePercentage: 0.00,
                paymentFeeFixed: 0.40,
                description: "Facebook Checkout"
            )
        case .stockx:
            return PlatformFees(
                platformFeePercentage: 0.095,
                paymentFeePercentage: 0.03,
                paymentFeeFixed: 0.00,
                description: "StockX Transaction Fee"
            )
        case .inPerson:
            return PlatformFees(
                platformFeePercentage: 0.00,
                paymentFeePercentage: 0.00,
                paymentFeeFixed: 0.00,
                description: "Cash Sale"
            )
        case .custom:
            return PlatformFees(
                platformFeePercentage: 0.10,
                paymentFeePercentage: 0.029,
                paymentFeeFixed: 0.30,
                description: "Custom Fee Structure"
            )
        }
    }
}

struct PlatformFees: Sendable {
    let platformFeePercentage: Double
    let paymentFeePercentage: Double
    let paymentFeeFixed: Double
    let description: String
}
