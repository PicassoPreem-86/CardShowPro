import Foundation
import SwiftUI

// MARK: - Calculator Modes

enum CalculatorMode: String, Sendable {
    case forward  // "What Profit?" - Input sale price, calculate profit
    case reverse  // "What Price?" - Input desired profit, calculate price
}

enum ProfitMode: Hashable, Sendable {
    case fixedAmount(Decimal)
    case percentage(Double)
}

// MARK: - Calculation Results

/// Profit status classification
enum ProfitStatus: Sendable {
    case profitable
    case breakeven
    case loss
}

/// Result for Forward Mode (known sale price → calculate profit)
struct ForwardCalculationResult: Sendable {
    let salePrice: Decimal
    let itemCost: Decimal
    let shippingCost: Decimal
    let suppliesCost: Decimal
    let totalCosts: Decimal
    let platformFee: Decimal
    let platformFeePercentage: Double
    let paymentFee: Decimal
    let paymentFeePercentage: Double
    let totalFees: Decimal
    let netProfit: Decimal
    let profitMarginPercent: Double
    let roiPercent: Double

    var profitStatus: ProfitStatus {
        if netProfit > 0 { return .profitable }
        if netProfit < 0 { return .loss }
        return .breakeven
    }

    var isProfitable: Bool {
        netProfit > 0
    }
}

/// Result for Reverse Mode (desired profit → calculate sale price)
struct CalculationResult: Sendable {
    let listPrice: Decimal
    let platformFee: Decimal
    let platformFeePercentage: Double
    let paymentFee: Decimal
    let paymentFeePercentage: Double
    let shippingCost: Decimal
    let totalFees: Decimal
    let netProfit: Decimal
    let profitMarginPercent: Double
}

// MARK: - Model

@Observable
@MainActor
final class SalesCalculatorModel {
    // Mode
    var mode: CalculatorMode = .forward

    // Forward Mode inputs
    var salePrice: Decimal = 0.00
    var itemCost: Decimal = 0.00
    var suppliesCost: Decimal = 0.00

    // Shared inputs
    var shippingCost: Decimal = 0.00
    var selectedPlatform: SellingPlatform = .ebay
    var showPlatformPicker = false

    // Reverse Mode inputs (legacy)
    var cardCost: Decimal = 0.00
    var profitMode: ProfitMode = .percentage(0.20)

    // MARK: - Forward Mode Calculation

    /// Calculate profit from known sale price (Forward Mode)
    func calculateProfit() -> ForwardCalculationResult {
        let fees = selectedPlatform.feeStructure
        let totalCosts = itemCost + shippingCost + suppliesCost

        let platformFee = salePrice * Decimal(fees.platformFeePercentage)
        let paymentFee = (salePrice * Decimal(fees.paymentFeePercentage)) + Decimal(fees.paymentFeeFixed)
        let totalFees = platformFee + paymentFee
        let netProfit = salePrice - totalCosts - totalFees
        let profitMarginPercent = salePrice > 0 ? Double(truncating: ((netProfit / salePrice) * 100) as NSNumber) : 0
        let roiPercent = totalCosts > 0 ? Double(truncating: ((netProfit / totalCosts) * 100) as NSNumber) : 0

        return ForwardCalculationResult(
            salePrice: salePrice,
            itemCost: itemCost,
            shippingCost: shippingCost,
            suppliesCost: suppliesCost,
            totalCosts: totalCosts,
            platformFee: platformFee,
            platformFeePercentage: fees.platformFeePercentage,
            paymentFee: paymentFee,
            paymentFeePercentage: fees.paymentFeePercentage,
            totalFees: totalFees,
            netProfit: netProfit,
            profitMarginPercent: profitMarginPercent,
            roiPercent: roiPercent
        )
    }

    // MARK: - Reverse Mode Calculation

    /// Calculate recommended sale price from desired profit (Reverse Mode)
    var calculationResult: CalculationResult {
        calculateSalesPrice()
    }

    private func calculateSalesPrice() -> CalculationResult {
        let fees = selectedPlatform.feeStructure
        let totalCost = cardCost + shippingCost

        let desiredProfit: Decimal
        switch profitMode {
        case .fixedAmount(let amount):
            desiredProfit = amount
        case .percentage(let percent):
            desiredProfit = cardCost * Decimal(percent)
        }

        let totalFeePercentage = fees.platformFeePercentage + fees.paymentFeePercentage
        let numerator = totalCost + desiredProfit + Decimal(fees.paymentFeeFixed)
        let denominator = 1.0 - Decimal(totalFeePercentage)

        guard denominator > 0 else {
            return CalculationResult(
                listPrice: 0, platformFee: 0, platformFeePercentage: 0,
                paymentFee: 0, paymentFeePercentage: 0, shippingCost: 0,
                totalFees: 0, netProfit: 0, profitMarginPercent: 0
            )
        }

        let listPrice = numerator / denominator
        let platformFee = listPrice * Decimal(fees.platformFeePercentage)
        let paymentFee = (listPrice * Decimal(fees.paymentFeePercentage)) + Decimal(fees.paymentFeeFixed)
        let totalFees = platformFee + paymentFee + shippingCost
        let netProfit = listPrice - totalCost - platformFee - paymentFee
        let profitMarginPercent = cardCost > 0 ? Double(truncating: ((netProfit / cardCost) * 100) as NSNumber) : 0

        return CalculationResult(
            listPrice: listPrice,
            platformFee: platformFee,
            platformFeePercentage: fees.platformFeePercentage,
            paymentFee: paymentFee,
            paymentFeePercentage: fees.paymentFeePercentage,
            shippingCost: shippingCost,
            totalFees: totalFees,
            netProfit: netProfit,
            profitMarginPercent: profitMarginPercent
        )
    }

    // MARK: - Actions

    func setMarginPreset(_ percent: Double) {
        profitMode = .percentage(percent)
    }

    func reset() {
        salePrice = 0.00
        itemCost = 0.00
        suppliesCost = 0.00
        cardCost = 0.00
        shippingCost = 0.00
        profitMode = .percentage(0.20)
        mode = .forward
    }

    func copyListPrice() {
        UIPasteboard.general.string = calculationResult.listPrice.asCurrency
    }
}
