import Foundation

/// Represents grade levels and their value multipliers
enum GradeLevel: String, CaseIterable, Identifiable, Sendable {
    case ten = "10"
    case nine = "9"
    case eight = "8"
    case belowEight = "<8"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ten: return "PSA 10"
        case .nine: return "PSA 9"
        case .eight: return "PSA 8"
        case .belowEight: return "PSA <8"
        }
    }

    /// Multiplier applied to raw card value for this grade
    var multiplier: Double {
        switch self {
        case .ten: return 3.5
        case .nine: return 1.8
        case .eight: return 1.2
        case .belowEight: return 0.9
        }
    }

    /// Color for UI representation
    var color: String {
        switch self {
        case .ten: return "thunderYellow"
        case .nine: return "success"
        case .eight: return "warning"
        case .belowEight: return "error"
        }
    }
}
