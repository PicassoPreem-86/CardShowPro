import Foundation
import SwiftData

/// Represents a subscription purchase or renewal transaction
@Model
final class SubscriptionTransaction {
    // MARK: - Identification

    @Attribute(.unique) var id: UUID

    /// RevenueCat transaction ID
    var transactionId: String?

    /// Associated user
    var userId: String?

    // MARK: - Transaction Details

    /// Product identifier (e.g., "com.cardshowpro.app.subscription.pro.monthly")
    var productId: String

    /// Transaction type
    var type: TransactionType

    /// Purchase date
    var purchaseDate: Date

    /// Expiration date (for subscriptions)
    var expiryDate: Date?

    /// Amount paid
    var price: Double

    /// Currency code (USD, EUR, etc.)
    var currency: String

    /// Is this a trial period?
    var isTrial: Bool

    /// Store environment (sandbox or production)
    var environment: StoreEnvironment

    // MARK: - Status

    /// Current status of this transaction
    var status: TransactionStatus

    /// When this transaction was created in our system
    var createdAt: Date

    /// When this transaction was last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        transactionId: String?,
        productId: String,
        type: TransactionType,
        purchaseDate: Date = Date(),
        expiryDate: Date? = nil,
        price: Double,
        currency: String = "USD",
        isTrial: Bool = false,
        environment: StoreEnvironment = .production,
        status: TransactionStatus = .active
    ) {
        self.id = UUID()
        self.transactionId = transactionId
        self.productId = productId
        self.type = type
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.price = price
        self.currency = currency
        self.isTrial = isTrial
        self.environment = environment
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Transaction Type

enum TransactionType: String, Codable, Sendable {
    case initialPurchase
    case renewal
    case upgrade
    case downgrade
    case refund
    case restoration

    var displayName: String {
        switch self {
        case .initialPurchase: return "Initial Purchase"
        case .renewal: return "Renewal"
        case .upgrade: return "Upgrade"
        case .downgrade: return "Downgrade"
        case .refund: return "Refund"
        case .restoration: return "Restored Purchase"
        }
    }
}

// MARK: - Transaction Status

enum TransactionStatus: String, Codable, Sendable {
    case active
    case expired
    case canceled
    case refunded
    case pending

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .expired: return "Expired"
        case .canceled: return "Canceled"
        case .refunded: return "Refunded"
        case .pending: return "Pending"
        }
    }

    var icon: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .expired: return "exclamationmark.triangle.fill"
        case .canceled: return "xmark.circle.fill"
        case .refunded: return "arrow.uturn.backward.circle.fill"
        case .pending: return "clock.fill"
        }
    }

    var color: String {
        switch self {
        case .active: return "green"
        case .expired: return "orange"
        case .canceled: return "red"
        case .refunded: return "gray"
        case .pending: return "blue"
        }
    }
}

// MARK: - Store Environment

enum StoreEnvironment: String, Codable, Sendable {
    case sandbox
    case production

    var displayName: String {
        switch self {
        case .sandbox: return "Sandbox (Test)"
        case .production: return "Production"
        }
    }
}

// MARK: - Extensions

extension SubscriptionTransaction {
    /// Whether this transaction is currently active
    var isActive: Bool {
        status == .active && !isExpired
    }

    /// Whether this transaction has expired
    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return Date() > expiry
    }

    /// Days until expiration (0 if expired or no expiry date)
    var daysUntilExpiry: Int {
        guard let expiry = expiryDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        return max(0, days)
    }

    /// Formatted price string
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price)) ?? "\(currency) \(price)"
    }
}
