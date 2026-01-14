import Testing
import Foundation
@testable import CardShowProFeature

@Suite("Forward Calculation Tests - Price → Profit")
@MainActor
struct ForwardCalculationTests {

    // MARK: - Basic Calculations

    @Test("Basic calculation: $50 sale, $30 cost, eBay")
    func basicCalculation() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 50.00
        model.itemCost = 30.00
        model.shippingCost = 5.00
        model.suppliesCost = 2.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        // Verify inputs
        #expect(result.salePrice == 50.00)
        #expect(result.itemCost == 30.00)
        #expect(result.shippingCost == 5.00)
        #expect(result.suppliesCost == 2.00)

        // Verify costs
        #expect(result.totalCosts == 37.00) // 30 + 5 + 2

        // Verify fees
        // eBay: 12.95% platform + 2.9% payment + $0.30 fixed
        let expectedPlatformFee: Decimal = 50.00 * 0.1295 // 6.475
        let expectedPaymentFee: Decimal = (50.00 * 0.029) + 0.30 // 1.45 + 0.30 = 1.75
        let expectedTotalFees = expectedPlatformFee + expectedPaymentFee // 8.225

        #expect(result.platformFee == expectedPlatformFee)
        #expect(result.paymentFee == expectedPaymentFee)
        #expect(result.totalFees == expectedTotalFees)

        // Verify profit
        let expectedNetProfit: Decimal = 50.00 - 37.00 - 8.225 // 4.775
        #expect(result.netProfit == expectedNetProfit)

        // Verify metrics
        let expectedProfitMargin = (4.775 / 50.00) * 100 // 9.55%
        let expectedROI = (4.775 / 37.00) * 100 // 12.905%

        #expect(abs(result.profitMarginPercent - expectedProfitMargin) < 0.01)
        #expect(abs(result.roiPercent - expectedROI) < 0.01)

        // Verify status
        #expect(result.isProfitable == true)
        #expect(result.profitStatus == .profitable)
    }

    @Test("Zero profit scenario: sale price equals costs + fees")
    func zeroProfitScenario() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 10.00
        model.itemCost = 8.00
        model.shippingCost = 0.50
        model.suppliesCost = 0.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        // Calculate expected fees
        let platformFee = 10.00 * 0.1295 // 1.295
        let paymentFee = (10.00 * 0.029) + 0.30 // 0.29 + 0.30 = 0.59
        let totalFees = platformFee + paymentFee // 1.885

        // Total cost = 8.00 + 0.50 = 8.50
        // Sale - Costs - Fees = 10.00 - 8.50 - 1.885 = -0.385 (loss)
        let expectedProfit: Decimal = 10.00 - 8.50 - 1.885

        #expect(result.netProfit == expectedProfit)
        #expect(result.netProfit < 0) // This is actually a loss
        #expect(result.isProfitable == false)
        #expect(result.profitStatus == .loss)
    }

    @Test("Negative profit scenario: costs exceed revenue")
    func negativeProfitScenario() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 20.00
        model.itemCost = 15.00
        model.shippingCost = 8.00
        model.suppliesCost = 1.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        // Total costs = 15 + 8 + 1 = 24
        #expect(result.totalCosts == 24.00)

        // Fees
        let platformFee = 20.00 * 0.1295 // 2.59
        let paymentFee = (20.00 * 0.029) + 0.30 // 0.88

        // Profit = 20 - 24 - (2.59 + 0.88) = 20 - 27.47 = -7.47
        #expect(result.netProfit < 0)
        #expect(result.isProfitable == false)
        #expect(result.profitStatus == .loss)
        #expect(result.profitMarginPercent < 0) // Negative margin
        #expect(result.roiPercent < 0) // Negative ROI
    }

    // MARK: - High-Value Cards

    @Test("High-value card: $10,000 sale")
    func highValueCard() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 10_000.00
        model.itemCost = 7_000.00
        model.shippingCost = 50.00
        model.suppliesCost = 20.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        // Verify inputs
        #expect(result.salePrice == 10_000.00)
        #expect(result.totalCosts == 7_070.00)

        // Calculate fees
        let platformFee: Decimal = 10_000.00 * 0.1295 // 1,295.00
        let paymentFee: Decimal = (10_000.00 * 0.029) + 0.30 // 290.30
        let totalFees = platformFee + paymentFee // 1,585.30

        #expect(result.platformFee == platformFee)
        #expect(result.paymentFee == paymentFee)
        #expect(result.totalFees == totalFees)

        // Profit = 10,000 - 7,070 - 1,585.30 = 1,344.70
        let expectedProfit: Decimal = 10_000.00 - 7_070.00 - 1_585.30
        #expect(result.netProfit == expectedProfit)

        // Should be profitable
        #expect(result.isProfitable == true)
        #expect(result.profitStatus == .profitable)

        // Profit margin = 1,344.70 / 10,000 = 13.447%
        let expectedMargin = (1_344.70 / 10_000.00) * 100
        #expect(abs(result.profitMarginPercent - expectedMargin) < 0.01)
    }

    // MARK: - Low-Value Cards

    @Test("Penny card: $0.01 sale")
    func pennyCard() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 0.01
        model.itemCost = 0.00
        model.shippingCost = 0.00
        model.suppliesCost = 0.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        // Fees will be larger than sale price
        let platformFee = Decimal(string: "0.0001295")! // 0.01 * 0.1295
        let paymentFee = Decimal(string: "0.30029")! // (0.01 * 0.029) + 0.30

        // Profit will be negative
        #expect(result.netProfit < 0)
        #expect(result.isProfitable == false)
        #expect(result.profitStatus == .loss)
    }

    @Test("Low-value card: $5 sale with minimal costs")
    func lowValueCard() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 5.00
        model.itemCost = 2.00
        model.shippingCost = 1.00
        model.suppliesCost = 0.50
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        #expect(result.totalCosts == 3.50)

        // Fees
        let platformFee: Decimal = 5.00 * 0.1295 // 0.6475
        let paymentFee: Decimal = (5.00 * 0.029) + 0.30 // 0.445
        let totalFees = platformFee + paymentFee // 1.0925

        // Profit = 5.00 - 3.50 - 1.0925 = 0.4075
        let expectedProfit: Decimal = 5.00 - 3.50 - 1.0925
        #expect(result.netProfit == expectedProfit)

        // Barely profitable
        #expect(result.isProfitable == true)
        #expect(result.profitStatus == .profitable)
    }

    // MARK: - Different Platforms

    @Test("TCGPlayer platform fees")
    func tcgplayerPlatform() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 100.00
        model.itemCost = 50.00
        model.shippingCost = 5.00
        model.suppliesCost = 2.00
        model.selectedPlatform = .tcgplayer

        let result = model.calculateProfit()

        // TCGPlayer: 12.85% platform + 2.9% payment + $0.30 fixed
        let platformFee: Decimal = 100.00 * 0.1285 // 12.85
        let paymentFee: Decimal = (100.00 * 0.029) + 0.30 // 3.20
        let totalFees = platformFee + paymentFee // 16.05

        #expect(result.platformFee == platformFee)
        #expect(result.paymentFee == paymentFee)
        #expect(result.totalFees == totalFees)
        #expect(result.platformFeePercentage == 0.1285)

        // Profit = 100 - 57 - 16.05 = 26.95
        let expectedProfit: Decimal = 100.00 - 57.00 - 16.05
        #expect(result.netProfit == expectedProfit)
    }

    @Test("In-Person sale: no fees")
    func inPersonSale() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 75.00
        model.itemCost = 40.00
        model.shippingCost = 0.00
        model.suppliesCost = 0.00
        model.selectedPlatform = .inPerson

        let result = model.calculateProfit()

        // No fees for in-person
        #expect(result.platformFee == 0.00)
        #expect(result.paymentFee == 0.00)
        #expect(result.totalFees == 0.00)
        #expect(result.platformFeePercentage == 0.00)
        #expect(result.paymentFeePercentage == 0.00)

        // Profit = 75 - 40 - 0 = 35
        #expect(result.netProfit == 35.00)
        #expect(result.isProfitable == true)
        #expect(result.profitStatus == .profitable)

        // Profit margin = 35 / 75 = 46.67%
        let expectedMargin = (35.00 / 75.00) * 100
        #expect(abs(result.profitMarginPercent - expectedMargin) < 0.01)

        // ROI = 35 / 40 = 87.5%
        let expectedROI = (35.00 / 40.00) * 100
        #expect(abs(result.roiPercent - expectedROI) < 0.01)
    }

    @Test("Facebook Marketplace fees")
    func facebookMarketplace() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 60.00
        model.itemCost = 30.00
        model.shippingCost = 5.00
        model.suppliesCost = 1.00
        model.selectedPlatform = .facebookMarketplace

        let result = model.calculateProfit()

        // Facebook: 5% platform + 0% payment + $0.40 fixed
        let platformFee: Decimal = 60.00 * 0.05 // 3.00
        let paymentFee: Decimal = 0.40 // Just fixed fee
        let totalFees = platformFee + paymentFee // 3.40

        #expect(result.platformFee == platformFee)
        #expect(result.paymentFee == paymentFee)
        #expect(result.totalFees == totalFees)

        // Profit = 60 - 36 - 3.40 = 20.60
        let expectedProfit: Decimal = 60.00 - 36.00 - 3.40
        #expect(result.netProfit == expectedProfit)
    }

    @Test("StockX platform fees")
    func stockXPlatform() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 200.00
        model.itemCost = 120.00
        model.shippingCost = 10.00
        model.suppliesCost = 5.00
        model.selectedPlatform = .stockx

        let result = model.calculateProfit()

        // StockX: 9.5% platform + 3% payment + $0 fixed
        let platformFee: Decimal = 200.00 * 0.095 // 19.00
        let paymentFee: Decimal = 200.00 * 0.03 // 6.00
        let totalFees = platformFee + paymentFee // 25.00

        #expect(result.platformFee == platformFee)
        #expect(result.paymentFee == paymentFee)
        #expect(result.totalFees == totalFees)

        // Profit = 200 - 135 - 25 = 40
        let expectedProfit: Decimal = 200.00 - 135.00 - 25.00
        #expect(result.netProfit == expectedProfit)
    }

    // MARK: - Edge Cases

    @Test("Zero costs: all profit after fees")
    func zeroCosts() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 50.00
        model.itemCost = 0.00
        model.shippingCost = 0.00
        model.suppliesCost = 0.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        #expect(result.totalCosts == 0.00)

        // Only fees reduce profit
        let platformFee: Decimal = 50.00 * 0.1295
        let paymentFee: Decimal = (50.00 * 0.029) + 0.30
        let expectedProfit = 50.00 - (platformFee + paymentFee)

        #expect(result.netProfit == expectedProfit)
        #expect(result.isProfitable == true)

        // ROI should be 0 when costs are 0 (avoid division by zero)
        #expect(result.roiPercent == 0.00)
    }

    @Test("Zero sale price: maximum loss")
    func zeroSalePrice() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 0.00
        model.itemCost = 10.00
        model.shippingCost = 5.00
        model.suppliesCost = 2.00
        model.selectedPlatform = .ebay

        let result = model.calculateProfit()

        #expect(result.salePrice == 0.00)
        #expect(result.totalCosts == 17.00)

        // No fees on $0 sale (platform + payment fees = 0.30 fixed only)
        #expect(result.platformFee == 0.00)
        #expect(result.paymentFee == 0.30)

        // Profit = 0 - 17 - 0.30 = -17.30
        let expectedProfit: Decimal = 0.00 - 17.00 - 0.30
        #expect(result.netProfit == expectedProfit)
        #expect(result.isProfitable == false)
        #expect(result.profitStatus == .loss)

        // Profit margin should be 0 when sale price is 0
        #expect(result.profitMarginPercent == 0.00)
    }

    @Test("All values zero: neutral result")
    func allZeros() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 0.00
        model.itemCost = 0.00
        model.shippingCost = 0.00
        model.suppliesCost = 0.00
        model.selectedPlatform = .inPerson // No fees

        let result = model.calculateProfit()

        #expect(result.salePrice == 0.00)
        #expect(result.totalCosts == 0.00)
        #expect(result.totalFees == 0.00)
        #expect(result.netProfit == 0.00)
        #expect(result.isProfitable == false)
        #expect(result.profitStatus == .breakeven)
        #expect(result.profitMarginPercent == 0.00)
        #expect(result.roiPercent == 0.00)
    }

    // MARK: - Profit Margin & ROI Calculations

    @Test("Profit margin calculation accuracy")
    func profitMarginAccuracy() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 100.00
        model.itemCost = 50.00
        model.shippingCost = 5.00
        model.suppliesCost = 0.00
        model.selectedPlatform = .inPerson // No fees for simplicity

        let result = model.calculateProfit()

        // Profit = 100 - 55 = 45
        #expect(result.netProfit == 45.00)

        // Margin = (45 / 100) * 100 = 45%
        let expectedMargin = 45.0
        #expect(result.profitMarginPercent == expectedMargin)
    }

    @Test("ROI calculation accuracy")
    func roiAccuracy() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 150.00
        model.itemCost = 80.00
        model.shippingCost = 10.00
        model.suppliesCost = 10.00
        model.selectedPlatform = .inPerson // No fees

        let result = model.calculateProfit()

        // Total costs = 100
        #expect(result.totalCosts == 100.00)

        // Profit = 150 - 100 = 50
        #expect(result.netProfit == 50.00)

        // ROI = (50 / 100) * 100 = 50%
        let expectedROI = 50.0
        #expect(result.roiPercent == expectedROI)
    }

    // MARK: - Mode & Reset Tests

    @Test("Mode switching resets values")
    func modeSwitchingReset() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 100.00
        model.itemCost = 50.00
        model.shippingCost = 10.00
        model.suppliesCost = 5.00

        #expect(model.salePrice == 100.00)

        model.switchMode(to: .reverse)

        // All values should be reset
        #expect(model.salePrice == 0.00)
        #expect(model.itemCost == 0.00)
        #expect(model.shippingCost == 0.00)
        #expect(model.suppliesCost == 0.00)
        #expect(model.mode == .reverse)
    }

    @Test("Reset clears all forward mode values")
    func resetClearsValues() async throws {
        let model = SalesCalculatorModel()
        model.mode = .forward
        model.salePrice = 75.00
        model.itemCost = 30.00
        model.shippingCost = 8.00
        model.suppliesCost = 3.00

        model.reset()

        #expect(model.salePrice == 0.00)
        #expect(model.itemCost == 0.00)
        #expect(model.shippingCost == 0.00)
        #expect(model.suppliesCost == 0.00)
    }
}
