import Foundation

/// Enum for contact classification
public enum ContactType: String, Codable, CaseIterable, Sendable {
    case customer = "Customer"
    case vendor = "Vendor"
    case supplier = "Supplier"
    case lead = "Lead"

    public var icon: String {
        switch self {
        case .customer:
            return "person.crop.circle.badge.checkmark"
        case .vendor:
            return "briefcase.circle.fill"
        case .supplier:
            return "shippingbox.circle.fill"
        case .lead:
            return "star.circle"
        }
    }
}
