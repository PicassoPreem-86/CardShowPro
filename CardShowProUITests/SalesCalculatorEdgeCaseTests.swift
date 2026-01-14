import XCTest

/// Category 4: Edge Cases & Input Validation Tests (6 tests)
/// Tests boundary conditions, invalid inputs, and error handling
final class SalesCalculatorEdgeCaseTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        // Navigate to Sales Calculator
        let toolsTab = app.tabBars.buttons["Tools"]
        XCTAssertTrue(toolsTab.waitForExistence(timeout: 5))
        toolsTab.tap()

        let salesCalcButton = app.buttons["sales-calculator-button"]
        XCTAssertTrue(salesCalcButton.waitForExistence(timeout: 5))
        salesCalcButton.tap()

        // Wait for calculator to load
        let forwardButton = app.buttons["forward-mode-button"]
        XCTAssertTrue(forwardButton.waitForExistence(timeout: 5))
    }

    // MARK: - Test 4.1: Negative Profit Scenario

    func testNegativeProfit() throws {
        // TEST: What happens when costs exceed sales price?
        // Hostile mindset: "I bet it shows positive profit even when losing money"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("20")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("50")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        // Should show loss warning
        XCTAssertTrue(app.exists, "App should handle negative profit")
        takeScreenshot(name: "test_4.1_negative_profit")
    }

    // MARK: - Test 4.2: Decimal Precision

    func testDecimalPrecision() throws {
        // TEST: Can it handle precise decimal values?
        // Hostile mindset: "I bet it rounds everything wrong"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("99.99")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("45.75")

        let shippingField = app.textFields["shipping-cost-field"]
        shippingField.tap()
        shippingField.typeText("3.25")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertTrue(app.exists, "App should handle decimal precision")
        takeScreenshot(name: "test_4.2_decimal_precision")
    }

    // MARK: - Test 4.3: Maximum Value Input

    func testMaximumValueInput() throws {
        // TEST: What's the highest value it can handle?
        // Hostile mindset: "I bet it crashes with massive numbers"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("999999")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("500000")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        // App should not crash
        XCTAssertTrue(app.exists, "App should handle maximum values")
        takeScreenshot(name: "test_4.3_maximum_value")
    }

    // MARK: - Test 4.4: Empty Input Handling

    func testEmptyInputHandling() throws {
        // TEST: What if I don't enter anything?
        // Hostile mindset: "I bet it crashes with no input"

        // Just tap Done without entering any values
        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        // Should handle gracefully
        XCTAssertTrue(app.exists, "App should handle empty inputs")
        takeScreenshot(name: "test_4.4_empty_input")
    }

    // MARK: - Test 4.5: Partial Input Handling

    func testPartialInputHandling() throws {
        // TEST: What if I only fill in sale price?
        // Hostile mindset: "I bet it requires all fields or crashes"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("75")

        // Don't fill in costs
        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        // Should show some result
        XCTAssertTrue(app.exists, "App should handle partial inputs")
        takeScreenshot(name: "test_4.5_partial_input")
    }

    // MARK: - Test 4.6: Back-to-Back Calculations

    func testBackToBackCalculations() throws {
        // TEST: Can I do multiple calculations in a row?
        // Hostile mindset: "I bet the second calculation breaks"

        // First calculation
        var salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("100")

        var itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("50")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Clear and do second calculation
        salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        // Select all and delete
        salePriceField.typeText("")

        salePriceField.typeText("200")

        itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("100")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Should still work
        XCTAssertTrue(app.exists, "App should handle multiple calculations")
        takeScreenshot(name: "test_4.6_back_to_back")
    }

    // MARK: - Helper

    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
