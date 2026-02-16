import Foundation

/// Generates CSV and plain-text report exports for inventory and transaction data.
@MainActor
public enum DataExportService {

    // MARK: - Inventory CSV

    /// Export inventory cards as a CSV string with header row.
    public static func exportInventoryCSV(cards: [InventoryCard]) -> String {
        var lines: [String] = []

        lines.append(
            csvRow([
                "Card Name", "Set", "Card Number", "Category", "Condition",
                "Status", "Purchase Cost", "Market Value", "Profit", "ROI%",
                "Acquisition Source", "Acquisition Date", "Date Added",
                "Platform", "Grade", "Grading Service", "Notes"
            ])
        )

        for card in cards {
            let row: [String] = [
                card.cardName,
                card.setName,
                card.cardNumber,
                card.category,
                card.condition,
                card.status,
                formatOptionalCurrency(card.purchaseCost),
                formatCurrency(card.estimatedValue),
                formatCurrency(card.profit),
                card.purchaseCost != nil ? String(format: "%.1f", card.roi) : "",
                card.acquisitionSource ?? "",
                formatOptionalDate(card.acquisitionDate),
                formatDate(card.timestamp),
                card.platform ?? "",
                card.grade ?? "",
                card.gradingService ?? "",
                card.notes
            ]
            lines.append(csvRow(row))
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Transactions CSV

    /// Export transactions as a CSV string with header row.
    public static func exportTransactionsCSV(transactions: [Transaction]) -> String {
        var lines: [String] = []

        lines.append(
            csvRow([
                "Date", "Type", "Card Name", "Set", "Amount",
                "Platform Fees", "Shipping", "Net Amount", "Profit",
                "Platform", "Contact", "Event", "Notes"
            ])
        )

        for txn in transactions {
            let row: [String] = [
                formatDate(txn.date),
                txn.type,
                txn.cardName,
                txn.cardSetName,
                formatCurrency(txn.amount),
                formatCurrency(txn.platformFees),
                formatCurrency(txn.shippingCost),
                formatCurrency(txn.netAmount),
                formatCurrency(txn.profit),
                txn.platform ?? "",
                txn.contactName ?? "",
                txn.eventName ?? "",
                txn.notes
            ]
            lines.append(csvRow(row))
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - P&L Report

    /// Generate a plain-text Profit & Loss report from inventory and transaction data.
    public static func exportPLReport(cards: [InventoryCard], transactions: [Transaction]) -> String {
        let sales = transactions.filter { $0.transactionType == .sale }
        let purchases = transactions.filter { $0.transactionType == .purchase }

        let totalSalesRevenue = sales.reduce(0.0) { $0 + $1.amount }
        let averageSale = sales.isEmpty ? 0.0 : totalSalesRevenue / Double(sales.count)
        let totalPurchases = purchases.reduce(0.0) { $0 + $1.amount }

        let totalGradingCosts = cards.compactMap(\.gradingCost).reduce(0.0, +)
        let totalPlatformFees = sales.reduce(0.0) { $0 + $1.platformFees }
        let totalShipping = sales.reduce(0.0) { $0 + $1.shippingCost }

        let totalCOGS = sales.reduce(0.0) { $0 + $1.costBasis }
        let netProfit = totalSalesRevenue - totalCOGS - totalPlatformFees - totalShipping - totalGradingCosts
        let profitMargin = totalSalesRevenue > 0 ? (netProfit / totalSalesRevenue) * 100 : 0

        let inStockCards = cards.filter { $0.cardStatus == .inStock }
        let listedCards = cards.filter { $0.cardStatus == .listed }
        let soldCards = cards.filter { $0.isSold }
        let inStockValue = inStockCards.reduce(0.0) { $0 + $1.estimatedValue }
        let listedValue = listedCards.reduce(0.0) { $0 + ($1.listingPrice ?? $1.estimatedValue) }

        let dateString = Date().formatted(date: .long, time: .shortened)
        let separator = String(repeating: "\u{2550}", count: 35)

        return """
        CardShowPro - Profit & Loss Report
        Generated: \(dateString)

        \(separator)
        REVENUE
          Total Sales: \(usd(totalSalesRevenue)) (\(sales.count) transactions)
          Average Sale: \(usd(averageSale))

        COST OF GOODS
          Total Purchases: \(usd(totalPurchases))
          Grading Costs: \(usd(totalGradingCosts))

        FEES & EXPENSES
          Platform Fees: \(usd(totalPlatformFees))
          Shipping Costs: \(usd(totalShipping))

        \(separator)
        NET PROFIT: \(usd(netProfit))
        Profit Margin: \(String(format: "%.1f", profitMargin))%

        INVENTORY SNAPSHOT
          Cards In Stock: \(inStockCards.count) (Value: \(usd(inStockValue)))
          Cards Listed: \(listedCards.count) (Value: \(usd(listedValue)))
          Cards Sold: \(soldCards.count)
          Total Cards: \(cards.count)
        \(separator)
        """
    }

    // MARK: - Private Helpers

    /// Build a single CSV row, escaping values that contain commas or quotes.
    private static func csvRow(_ values: [String]) -> String {
        values.map { escapeCSV($0) }.joined(separator: ",")
    }

    /// Escape a single CSV field value.
    private static func escapeCSV(_ value: String) -> String {
        let needsQuoting = value.contains(",") || value.contains("\"") || value.contains("\n")
        if needsQuoting {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    private static func formatCurrency(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private static func formatOptionalCurrency(_ value: Double?) -> String {
        guard let value else { return "" }
        return String(format: "%.2f", value)
    }

    private static func formatDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private static func formatOptionalDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    /// Format as USD currency string for the P&L report.
    private static func usd(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }
}
