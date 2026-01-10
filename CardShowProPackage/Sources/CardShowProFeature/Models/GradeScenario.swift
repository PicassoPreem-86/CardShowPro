import Foundation

/// Represents a single grade scenario with calculated values
struct GradeScenario: Identifiable, Sendable {
    let id = UUID()
    let gradeLevel: GradeLevel
    let gradedValue: Double
    let profit: Double
    let roiPercentage: Double

    /// Calculate a grade scenario
    static func calculate(
        gradeLevel: GradeLevel,
        rawValue: Double,
        totalCost: Double
    ) -> GradeScenario {
        let gradedValue = rawValue * gradeLevel.multiplier
        let profit = gradedValue - rawValue - totalCost
        let roiPercentage = totalCost > 0 ? (profit / totalCost) * 100 : 0

        return GradeScenario(
            gradeLevel: gradeLevel,
            gradedValue: gradedValue,
            profit: profit,
            roiPercentage: roiPercentage
        )
    }

    var profitIndicator: ProfitIndicator {
        if profit >= 20 {
            return .positive
        } else if profit >= -5 {
            return .neutral
        } else {
            return .negative
        }
    }
}

enum ProfitIndicator: Sendable {
    case positive
    case neutral
    case negative
}
