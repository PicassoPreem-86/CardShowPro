import Foundation

/// Complete ROI calculation with all scenarios and recommendation
struct ROICalculation: Sendable {
    let costs: GradingCosts
    let scenarios: [GradeScenario]
    let recommendation: GradingRecommendation

    /// Calculate complete ROI analysis
    static func calculate(
        rawValue: Double,
        serviceLevel: ServiceLevel
    ) -> ROICalculation {
        let costs = GradingCosts.calculate(rawValue: rawValue, serviceLevel: serviceLevel)

        // Calculate all grade scenarios
        let scenarios = GradeLevel.allCases.map { gradeLevel in
            GradeScenario.calculate(
                gradeLevel: gradeLevel,
                rawValue: rawValue,
                totalCost: costs.totalCost
            )
        }

        // Generate recommendation based on conservative algorithm
        let recommendation = generateRecommendation(scenarios: scenarios)

        return ROICalculation(
            costs: costs,
            scenarios: scenarios,
            recommendation: recommendation
        )
    }

    private static func generateRecommendation(scenarios: [GradeScenario]) -> GradingRecommendation {
        // Conservative algorithm:
        // - PSA 10 ROI must be ≥ 100%
        // - PSA 9 profit must be ≥ $20
        // - PSA 8 profit must be ≥ -$5

        guard let psa10 = scenarios.first(where: { $0.gradeLevel == .ten }),
              let psa9 = scenarios.first(where: { $0.gradeLevel == .nine }),
              let psa8 = scenarios.first(where: { $0.gradeLevel == .eight }) else {
            return .sellRaw
        }

        let psa10ROIMeetsThreshold = psa10.roiPercentage >= 100
        let psa9ProfitMeetsThreshold = psa9.profit >= 20
        let psa8ProfitMeetsThreshold = psa8.profit >= -5

        if psa10ROIMeetsThreshold && psa9ProfitMeetsThreshold && psa8ProfitMeetsThreshold {
            return .gradeIt(reason: "Strong ROI across multiple grades")
        } else {
            var reasons: [String] = []
            if !psa10ROIMeetsThreshold {
                reasons.append("PSA 10 ROI below 100%")
            }
            if !psa9ProfitMeetsThreshold {
                reasons.append("PSA 9 profit below $20")
            }
            if !psa8ProfitMeetsThreshold {
                reasons.append("PSA 8 likely unprofitable")
            }
            return .sellRaw
        }
    }
}

/// Recommendation for whether to grade or sell raw
enum GradingRecommendation: Sendable {
    case gradeIt(reason: String)
    case sellRaw

    var title: String {
        switch self {
        case .gradeIt:
            return "Grade It"
        case .sellRaw:
            return "Sell Raw"
        }
    }

    var description: String {
        switch self {
        case .gradeIt(let reason):
            return reason
        case .sellRaw:
            return "Grading costs may not justify the investment"
        }
    }

    var isPositive: Bool {
        switch self {
        case .gradeIt:
            return true
        case .sellRaw:
            return false
        }
    }
}
