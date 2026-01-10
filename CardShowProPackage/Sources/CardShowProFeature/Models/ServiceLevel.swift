import Foundation

/// Represents a service level tier for a grading company
struct ServiceLevel: Identifiable, Sendable, Hashable {
    let id = UUID()
    let name: String
    let fee: Double
    let turnaroundDays: String
    let maxValue: Double

    var displayName: String {
        "\(name) - \(fee.asCurrency)"
    }
}
