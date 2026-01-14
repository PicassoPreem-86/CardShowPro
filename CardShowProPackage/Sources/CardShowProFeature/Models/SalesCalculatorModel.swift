import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Calculator Modes
enum CalculatorMode: Hashable, Sendable {
    case forward  // "What Profit?" - Input sale price, output profit
    case reverse  // "What Price?" - Input desired profit, output sale price
}

// MARK: - Profit Modes (for Reverse Mode)
enum ProfitMode: Hashable, Sendable {
    case fixedAmount(Decimal)
    case percentage(Double)
}

// MARK: - Profit Status
enum ProfitStatus: Sendable {
    case profitable
    case breakeven
    case loss
}

// MARK: - Forward Calculation Result
struct ForwardCalculationResult: Sendable {
    // Revenue
    let salePrice: Decimal

    // Costs
    let itemCost: Decimal
    let shippingCost: Decimal
    let suppliesCost: Decimal
    let totalCosts: Decimal

    // Fees
    let platformFee: Decimal
    let platformFeePercentage: Double
    let paymentFee: Decimal
    let paymentFeePercentage: Double
    let totalFees: Decimal

    // Profit Metrics
    let netProfit: Decimal
    let profitMarginPercent: Double  // Profit / Sale Price
    let roiPercent: Double            // Profit / Total Costs

    // Status
    var isProfitable: Bool {
        netProfit > 0
    }

    var profitStatus: ProfitStatus {
        if netProfit > 0 { return .profitable }
        if netProfit == 0 { return .breakeven }
        return .loss
    }
}

// MARK: - Reverse Calculation Result (Legacy)
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

@Observable
@MainActor
final class SalesCalculatorModel {
    // Mode Selection
    var mode: CalculatorMode = .forward

    // Forward Mode Inputs
    var salePrice: Decimal = 0.00
    var itemCost: Decimal = 0.00
    var shippingCost: Decimal = 0.00
    var suppliesCost: Decimal = 0.00

    // Reverse Mode Inputs (Legacy)
    var cardCost: Decimal = 0.00
    var profitMode: ProfitMode = .percentage(0.20)

    // Shared Settings
    var selectedPlatform: SellingPlatform = .ebay
    var showPlatformPicker = false

    // Legacy property for reverse mode
    var calculationResult: CalculationResult {
        calculateSalesPrice()
    }

    // MARK: - Forward Calculation (Price → Profit)
    func calculateProfit() -> ForwardCalculationResult {
        let fees = selectedPlatform.feeStructure

        // Calculate fees based on sale price
        let platformFee = salePrice * Decimal(fees.platformFeePercentage)
        let paymentFee = (salePrice * Decimal(fees.paymentFeePercentage)) + Decimal(fees.paymentFeeFixed)
        let totalFees = platformFee + paymentFee

        // Calculate costs
        let totalCosts = itemCost + shippingCost + suppliesCost

        // Calculate profit
        let netProfit = salePrice - totalCosts - totalFees

        // Calculate metrics
        let profitMargin = salePrice > 0
            ? Double(truncating: ((netProfit / salePrice) * 100) as NSNumber)
            : 0

        let roi = totalCosts > 0
            ? Double(truncating: ((netProfit / totalCosts) * 100) as NSNumber)
            : 0

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
            profitMarginPercent: profitMargin,
            roiPercent: roi
        )
    }

    // MARK: - Reverse Calculation (Profit → Price) - Legacy
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

        // Reverse-engineer list price from desired profit
        // Formula: ListPrice = (Cost + Profit + FixedFees) / (1 - PlatformFee% - PaymentFee%)
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

    func setMarginPreset(_ percent: Double) {
        profitMode = .percentage(percent)
    }

    func reset() {
        // Reset forward mode inputs
        salePrice = 0.00
        itemCost = 0.00
        shippingCost = 0.00
        suppliesCost = 0.00

        // Reset reverse mode inputs
        cardCost = 0.00
        profitMode = .percentage(0.20)
    }

    func switchMode(to newMode: CalculatorMode) {
        mode = newMode
        reset()
    }

    func copyListPrice() {
        #if os(iOS)
        UIPasteboard.general.string = calculationResult.listPrice.asCurrency
        #endif
    }
}
