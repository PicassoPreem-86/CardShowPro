import Foundation
import SwiftUI

/// Observable state management for Grading ROI Calculator
@Observable
@MainActor
final class GradingROICalculatorState {
    var rawValue: Double = 100.00
    var selectedCompany: GradingCompany = .psa
    var selectedServiceLevel: ServiceLevel

    init() {
        self.selectedServiceLevel = GradingCompany.psa.serviceLevels[0]
    }

    var availableServiceLevels: [ServiceLevel] {
        selectedCompany.serviceLevels.filter { serviceLevel in
            rawValue <= serviceLevel.maxValue
        }
    }

    var calculation: ROICalculation {
        ROICalculation.calculate(rawValue: rawValue, serviceLevel: selectedServiceLevel)
    }

    func updateCompany(_ company: GradingCompany) {
        selectedCompany = company
        // Reset to first available service level for new company
        if let firstLevel = availableServiceLevels.first {
            selectedServiceLevel = firstLevel
        }
    }

    func updateServiceLevel(_ serviceLevel: ServiceLevel) {
        selectedServiceLevel = serviceLevel
    }

    func reset() {
        rawValue = 100.00
        selectedCompany = .psa
        selectedServiceLevel = GradingCompany.psa.serviceLevels[0]
    }
}
