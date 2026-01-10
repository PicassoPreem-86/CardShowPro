import Foundation

// MARK: - Decimal Formatting Extensions

extension Decimal {
    /// Format as currency string (e.g., "$123.45")
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Double Formatting Extensions

extension Double {
    /// Format as currency string (e.g., "$123.45")
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    /// Format as percentage string (e.g., "45.2%")
    var asPercentage: String {
        String(format: "%.1f%%", self)
    }
}
