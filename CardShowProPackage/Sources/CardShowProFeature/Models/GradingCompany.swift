import Foundation

/// Represents grading companies with their specific fee structures
enum GradingCompany: String, CaseIterable, Identifiable, Sendable {
    case psa = "PSA"
    case bgs = "BGS"
    case cgc = "CGC"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    var serviceLevels: [ServiceLevel] {
        switch self {
        case .psa:
            return [
                ServiceLevel(name: "Value", fee: 19.99, turnaroundDays: "65 business days", maxValue: 499),
                ServiceLevel(name: "Regular", fee: 24.99, turnaroundDays: "40 business days", maxValue: 1499),
                ServiceLevel(name: "Express", fee: 74.99, turnaroundDays: "10 business days", maxValue: 2499),
                ServiceLevel(name: "Super Express", fee: 199.99, turnaroundDays: "3 business days", maxValue: 9999),
                ServiceLevel(name: "Walk Through", fee: 599.99, turnaroundDays: "1 business day", maxValue: 24999)
            ]
        case .bgs:
            return [
                ServiceLevel(name: "Economy", fee: 20.00, turnaroundDays: "60 business days", maxValue: 499),
                ServiceLevel(name: "Standard", fee: 35.00, turnaroundDays: "30 business days", maxValue: 999),
                ServiceLevel(name: "Express", fee: 75.00, turnaroundDays: "10 business days", maxValue: 2499),
                ServiceLevel(name: "Premium", fee: 150.00, turnaroundDays: "5 business days", maxValue: 9999)
            ]
        case .cgc:
            return [
                ServiceLevel(name: "Economy", fee: 18.00, turnaroundDays: "70 business days", maxValue: 399),
                ServiceLevel(name: "Standard", fee: 25.00, turnaroundDays: "45 business days", maxValue: 999),
                ServiceLevel(name: "Express", fee: 65.00, turnaroundDays: "15 business days", maxValue: 2499),
                ServiceLevel(name: "Walk-Through", fee: 400.00, turnaroundDays: "1 business day", maxValue: 9999)
            ]
        }
    }
}
