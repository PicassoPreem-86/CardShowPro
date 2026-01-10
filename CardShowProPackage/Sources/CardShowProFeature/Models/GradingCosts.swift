import Foundation

/// Calculates and represents all costs associated with grading
struct GradingCosts: Sendable {
    let gradingFee: Double
    let shippingCost: Double
    let insuranceCost: Double

    var totalCost: Double {
        gradingFee + shippingCost + insuranceCost
    }

    /// Calculate grading costs based on raw value and service level
    static func calculate(rawValue: Double, serviceLevel: ServiceLevel) -> GradingCosts {
        let gradingFee = serviceLevel.fee
        let shippingCost = calculateShipping(for: rawValue)
        let insuranceCost = calculateInsurance(for: rawValue)

        return GradingCosts(
            gradingFee: gradingFee,
            shippingCost: shippingCost,
            insuranceCost: insuranceCost
        )
    }

    private static func calculateShipping(for rawValue: Double) -> Double {
        // Tiered shipping based on card value
        switch rawValue {
        case 0..<100:
            return 10.00
        case 100..<500:
            return 15.00
        case 500..<1000:
            return 20.00
        default:
            return 30.00
        }
    }

    private static func calculateInsurance(for rawValue: Double) -> Double {
        // Insurance is 1% of value with $5 minimum
        return max(5.0, rawValue * 0.01)
    }
}
