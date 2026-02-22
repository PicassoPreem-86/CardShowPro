import Foundation
import SwiftData

// MARK: - Transaction Type

public enum TransactionType: String, CaseIterable, Codable, Sendable {
    case purchase = "Purchase"
    case sale = "Sale"
    case trade = "Trade"
    case consignment = "Consignment"
    case refund = "Refund"

    public var icon: String {
        switch self {
        case .purchase: return "cart.fill"
        case .sale: return "dollarsign.circle.fill"
        case .trade: return "arrow.triangle.2.circlepath"
        case .consignment: return "shippingbox.fill"
        case .refund: return "arrow.uturn.backward.circle.fill"
        }
    }

    public var color: String {
        switch self {
        case .purchase: return "blue"
        case .sale: return "green"
        case .trade: return "orange"
        case .consignment: return "purple"
        case .refund: return "red"
        }
    }
}

// MARK: - Payment Method

public enum PaymentMethod: String, CaseIterable, Codable, Sendable {
    case cash = "Cash"
    case venmo = "Venmo"
    case paypal = "PayPal"
    case card = "Card"
    case zelle = "Zelle"
    case bankTransfer = "Bank Transfer"
    case applePay = "Apple Pay"
    case other = "Other"

    public var displayName: String { rawValue }
}

// MARK: - Transaction Category

public enum TransactionCategory: String, CaseIterable, Codable, Sendable {
    case retail = "Retail"
    case wholesale = "Wholesale"
    case event = "Event"
    case online = "Online"
    case trade = "Trade"
    case consignment = "Consignment"
    case other = "Other"

    public var displayName: String { rawValue }
}

// MARK: - Transaction Model

@Model
public final class Transaction {
    @Attribute(.unique) public var id: UUID
    public var type: String
    public var date: Date
    public var amount: Double
    public var platform: String?
    public var platformFees: Double
    public var shippingCost: Double
    public var notes: String

    // Denormalized card info (survives card deletion)
    public var cardId: UUID?
    public var cardName: String
    public var cardSetName: String

    // Contact link
    public var contactId: UUID?
    public var contactName: String?

    // Event tracking
    public var eventName: String?

    // Cost basis (acquisition cost of the card)
    public var costBasis: Double

    // Payment & fulfillment
    public var paymentMethod: String?
    public var taxAmount: Double = 0
    public var refundAmount: Double?
    public var refundDate: Date?
    public var trackingNumber: String?
    public var buyerName: String?
    public var category: String?

    public init(
        id: UUID = UUID(),
        type: TransactionType = .sale,
        date: Date = Date(),
        amount: Double = 0,
        platform: String? = nil,
        platformFees: Double = 0,
        shippingCost: Double = 0,
        notes: String = "",
        cardId: UUID? = nil,
        cardName: String = "",
        cardSetName: String = "",
        contactId: UUID? = nil,
        contactName: String? = nil,
        eventName: String? = nil,
        costBasis: Double = 0
    ) {
        self.id = id
        self.type = type.rawValue
        self.date = date
        self.amount = amount
        self.platform = platform
        self.platformFees = platformFees
        self.shippingCost = shippingCost
        self.notes = notes
        self.cardId = cardId
        self.cardName = cardName
        self.cardSetName = cardSetName
        self.contactId = contactId
        self.contactName = contactName
        self.eventName = eventName
        self.costBasis = costBasis
    }

    // MARK: - Computed Properties

    public var transactionType: TransactionType {
        TransactionType(rawValue: type) ?? .sale
    }

    /// Revenue after fees and shipping
    public var netAmount: Double {
        amount - platformFees - shippingCost
    }

    /// Profit on a sale (net revenue minus what the card cost)
    public var profit: Double {
        netAmount - costBasis
    }

    public var formattedAmount: String {
        amount.formatted(.currency(code: "USD"))
    }

    public var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Convenience Factories

    public static func recordSale(
        card: InventoryCard,
        salePrice: Double,
        platform: String? = nil,
        fees: Double = 0,
        shipping: Double = 0,
        contactName: String? = nil,
        contactId: UUID? = nil,
        eventName: String? = nil
    ) -> Transaction {
        Transaction(
            type: .sale,
            date: Date(),
            amount: salePrice,
            platform: platform,
            platformFees: fees,
            shippingCost: shipping,
            cardId: card.id,
            cardName: card.cardName,
            cardSetName: card.setName,
            contactId: contactId,
            contactName: contactName,
            eventName: eventName,
            costBasis: card.purchaseCost ?? 0
        )
    }

    public static func recordPurchase(
        card: InventoryCard,
        cost: Double,
        source: String? = nil,
        contactName: String? = nil,
        contactId: UUID? = nil
    ) -> Transaction {
        Transaction(
            type: .purchase,
            date: Date(),
            amount: cost,
            platform: source,
            cardId: card.id,
            cardName: card.cardName,
            cardSetName: card.setName,
            contactId: contactId,
            contactName: contactName,
            costBasis: cost
        )
    }

    public static func recordRefund(
        for card: InventoryCard,
        amount: Double,
        reason: String?,
        platform: String?
    ) -> Transaction {
        let transaction = Transaction(
            type: .refund,
            date: Date(),
            amount: amount,
            platform: platform,
            cardId: card.id,
            cardName: card.cardName,
            cardSetName: card.setName,
            costBasis: card.purchaseCost ?? 0
        )
        transaction.refundAmount = amount
        transaction.refundDate = Date()
        if let reason {
            transaction.notes = reason
        }
        return transaction
    }

    /// Whether this transaction has been refunded
    public var isRefunded: Bool {
        refundDate != nil
    }

    /// Get the PaymentMethod enum from the stored string
    public var paymentMethodType: PaymentMethod? {
        guard let paymentMethod else { return nil }
        return PaymentMethod(rawValue: paymentMethod)
    }

    /// Get the TransactionCategory enum from the stored string
    public var transactionCategory: TransactionCategory? {
        guard let category else { return nil }
        return TransactionCategory(rawValue: category)
    }

    /// Net amount after tax, fees, and shipping
    public var netAmountAfterTax: Double {
        amount - platformFees - shippingCost + taxAmount
    }
}
