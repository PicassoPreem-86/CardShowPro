import Foundation
import SwiftUI

/// Enum for contact priority classification
public enum ContactPriority: String, Codable, CaseIterable, Sendable {
    case vip = "VIP"
    case high = "High"
    case normal = "Normal"
    case low = "Low"

    public var color: Color {
        switch self {
        case .vip:
            return Color(hex: "#FFD700") // Thunder Yellow
        case .high:
            return .orange
        case .normal:
            return .gray
        case .low:
            return .secondary
        }
    }
}
