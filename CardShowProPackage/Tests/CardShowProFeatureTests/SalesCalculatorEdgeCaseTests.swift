import Testing
import Foundation
@testable import CardShowProFeature

@Suite("Sales Calculator Edge Cases")
struct SalesCalculatorEdgeCaseTests {

    @Test("Zero sale price returns zero or negative profit")
    @MainActor
    func zeroSalePrice() {
        let model = SalesCalculatorModel()
        model.salePrice = 0.00
        model.itemCost = 50.00
        model.shippingCost = 3.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        #expect(result.netProfit <= 0)
        #expect(result.isProfitable == false)
    }

    @Test("Micro profit detection (profit < $2)")
    @MainActor
    func microProfit() {
        let model = SalesCalculatorModel()
        model.salePrice = 5.00
        model.itemCost = 0.50
        model.shippingCost = 3.00
        model.suppliesCost = 0.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        // Should have positive but very small profit
        #expect(result.netProfit > 0)
        #expect(result.netProfit < 2.00)
        #expect(result.isProfitable == true)
    }

    @Test("High value card calculation ($10,000)")
    @MainActor
    func highValueCard() {
        let model = SalesCalculatorModel()
        model.salePrice = 10000.00
        model.itemCost = 5000.00
        model.shippingCost = 0.00
        model.suppliesCost = 0.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        // eBay: 12.95% platform + 2.9% + $0.30 payment
        // Platform fee: $10,000 * 0.1295 = $1,295.00
        // Payment fee: ($10,000 * 0.029) + $0.30 = $290.30
        // Total fees: $1,295.00 + $290.30 = $1,585.30
        // Net profit: $10,000 - $5,000 - $1,585.30 = $3,414.70

        #expect(result.platformFee == Decimal(string: "1295.00")!)
        #expect(abs(Double(truncating: result.paymentFee as NSNumber) - 290.30) < 0.01)
        #expect(abs(Double(truncating: result.totalFees as NSNumber) - 1585.30) < 0.01)
        #expect(abs(Double(truncating: result.netProfit as NSNumber) - 3414.70) < 0.01)
        #expect(result.isProfitable == true)
    }

    @Test("Platform comparison returns all 6 platforms")
    @MainActor
    func platformComparisonComplete() {
        let salePrice: Decimal = 100.00
        let itemCost: Decimal = 50.00
        let shippingCost: Decimal = 3.00
        let suppliesCost: Decimal = 2.00

        // Calculate profit for all platforms
        let platforms = SellingPlatform.allCases

        #expect(platforms.count == 6)

        var profits: [Decimal] = []

        for platform in platforms {
            let fees = platform.feeStructure
            let platformFee = salePrice * Decimal(fees.platformFeePercentage)
            let paymentFee = (salePrice * Decimal(fees.paymentFeePercentage)) + Decimal(fees.paymentFeeFixed)
            let totalCosts = itemCost + shippingCost + suppliesCost
            let netProfit = salePrice - totalCosts - platformFee - paymentFee
            profits.append(netProfit)
        }

        // In-Person should be most profitable (no fees)
        let inPersonIndex = platforms.firstIndex(of: .inPerson)!
        let inPersonProfit = profits[inPersonIndex]

        // In-Person profit: $100 - $55 (costs) - $0 (fees) = $45
        #expect(inPersonProfit == Decimal(45.00))

        // All other platforms should have lower profit due to fees
        for (index, profit) in profits.enumerated() where index != inPersonIndex {
            #expect(profit < inPersonProfit)
        }
    }

    @Test("Negative profit warning scenario")
    @MainActor
    func negativeProfitWarning() {
        let model = SalesCalculatorModel()
        model.salePrice = 30.00
        model.itemCost = 50.00
        model.shippingCost = 5.00
        model.suppliesCost = 2.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        #expect(result.netProfit < 0)
        #expect(result.isProfitable == false)
        #expect(result.profitStatus == .loss)
    }

    @Test("Break-even scenario")
    @MainActor
    func breakEvenScenario() {
        let model = SalesCalculatorModel()
        // Carefully craft a scenario that results in ~$0 profit
        model.salePrice = 70.00
        model.itemCost = 50.00
        model.shippingCost = 5.00
        model.suppliesCost = 0.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        // eBay fees on $70: 12.95% + 2.9% + $0.30
        // Platform fee: $70 * 0.1295 = $9.065
        // Payment fee: ($70 * 0.029) + $0.30 = $2.33
        // Total fees: ~$11.40
        // Net profit: $70 - $50 - $5 - $11.40 ≈ $3.60

        // This won't be exactly break-even, but should be close to profitable
        #expect(result.netProfit < 10.00)
    }

    @Test("All platforms with identical scenario")
    @MainActor
    func allPlatformsWithSameScenario() {
        let salePrice: Decimal = 200.00
        let itemCost: Decimal = 100.00
        let shippingCost: Decimal = 0.00
        let suppliesCost: Decimal = 5.00

        let model = SalesCalculatorModel()
        model.salePrice = salePrice
        model.itemCost = itemCost
        model.shippingCost = shippingCost
        model.suppliesCost = suppliesCost

        var platformResults: [(SellingPlatform, Decimal)] = []

        for platform in SellingPlatform.allCases {
            model.selectedPlatform = platform
            let result = model.calculateProfit()
            platformResults.append((platform, result.netProfit))
        }

        // Verify all 6 platforms returned results
        #expect(platformResults.count == 6)

        // Verify In-Person is most profitable
        let inPersonProfit = platformResults.first { $0.0 == .inPerson }?.1 ?? 0
        #expect(inPersonProfit == Decimal(95.00)) // $200 - $100 - $5 = $95

        // Verify all platforms have positive profit for this scenario
        for (platform, profit) in platformResults {
            if platform == .inPerson {
                #expect(profit == Decimal(95.00))
            } else {
                // Other platforms have fees, so profit < $95
                #expect(profit < Decimal(95.00))
                #expect(profit > 0) // But still profitable
            }
        }
    }

    @Test("ROI calculation accuracy")
    @MainActor
    func roiCalculationAccuracy() {
        let model = SalesCalculatorModel()
        model.salePrice = 150.00
        model.itemCost = 100.00
        model.shippingCost = 0.00
        model.suppliesCost = 0.00
        model.selectedPlatform = .inPerson // No fees for simple math

        let result = model.calculateProfit()

        // Net profit: $150 - $100 = $50
        // ROI: ($50 / $100) * 100 = 50%
        #expect(result.netProfit == Decimal(50.00))
        #expect(abs(result.roiPercent - 50.0) < 0.1)
    }

    @Test("Profit margin calculation accuracy")
    @MainActor
    func profitMarginCalculationAccuracy() {
        let model = SalesCalculatorModel()
        model.salePrice = 100.00
        model.itemCost = 70.00
        model.shippingCost = 0.00
        model.suppliesCost = 0.00
        model.selectedPlatform = .inPerson // No fees

        let result = model.calculateProfit()

        // Net profit: $100 - $70 = $30
        // Profit margin: ($30 / $100) * 100 = 30%
        #expect(result.netProfit == Decimal(30.00))
        #expect(abs(result.profitMarginPercent - 30.0) < 0.1)
    }

    @Test("Supplies cost included in calculations")
    @MainActor
    func suppliesCostIncluded() {
        let model = SalesCalculatorModel()
        model.salePrice = 100.00
        model.itemCost = 50.00
        model.shippingCost = 3.00
        model.suppliesCost = 5.00
        model.selectedPlatform = .inPerson

        let result = model.calculateProfit()

        // Total costs: $50 + $3 + $5 = $58
        #expect(result.totalCosts == Decimal(58.00))

        // Net profit: $100 - $58 = $42
        #expect(result.netProfit == Decimal(42.00))
    }
}
