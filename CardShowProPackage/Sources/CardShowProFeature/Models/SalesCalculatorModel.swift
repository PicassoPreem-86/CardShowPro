import Foundation
import SwiftUI

enum ProfitMode: Hashable, Sendable {
    case fixedAmount(Decimal)
    case percentage(Double)
}

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
    var cardCost: Decimal = 0.00
    var shippingCost: Decimal = 0.00
    var profitMode: ProfitMode = .percentage(0.20)
    var selectedPlatform: SellingPlatform = .ebay
    var showPlatformPicker = false

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
        cardCost = 0.00
        shippingCost = 0.00
        profitMode = .percentage(0.20)
    }

    func copyListPrice() {
        UIPasteboard.general.string = calculationResult.listPrice.asCurrency
    }
}
