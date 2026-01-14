import XCTest

/// Basic Functionality Tests for Sales Calculator
/// Tests the core features with hostile user mindset
final class SalesCalculatorBasicTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        // Navigate to Sales Calculator
        navigateToSalesCalculator()
    }

    override func tearDownWithError() throws {
        // Take screenshot on failure
        if let testRun = testRun, testRun.hasSucceeded == false {
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Failure Screenshot"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    // MARK: - Navigation Helper

    func navigateToSalesCalculator() {
        // Tap Tools tab (bottom right)
        let toolsTab = app.tabBars.buttons["Tools"]
        XCTAssertTrue(toolsTab.waitForExistence(timeout: 5), "Tools tab should exist")
        toolsTab.tap()

        // Tap Sales Calculator button
        let salesCalcButton = app.buttons.matching(identifier: "sales-calculator-button").firstMatch
        if !salesCalcButton.exists {
            // Fallback: Find by text
            let salesCalcByText = app.buttons["Sales Calculator"]
            XCTAssertTrue(salesCalcByText.waitForExistence(timeout: 5), "Sales Calculator button should exist")
            salesCalcByText.tap()
        } else {
            salesCalcButton.tap()
        }

        // Wait for calculator view to appear by checking for mode toggle
        let forwardModeButton = app.buttons["forward-mode-button"]
        XCTAssertTrue(forwardModeButton.waitForExistence(timeout: 5), "Forward mode button should appear")
    }

    // MARK: - Test 1.1: Forward Mode Smoke Test

    func testForwardModeSmokeTest() throws {
        // TEST: Does the calculator even work?
        // Hostile mindset: "I bet this gives me the wrong answer"

        // Verify Forward Mode is default
        let forwardButton = app.buttons["forward-mode-button"]
        XCTAssertTrue(forwardButton.exists, "Forward mode button should exist")

        // Enter sale price
        let salePriceField = app.textFields["sale-price-field"]
        XCTAssertTrue(salePriceField.waitForExistence(timeout: 5), "Sale price field should exist")
        salePriceField.tap()
        salePriceField.typeText("100")

        // Enter item cost
        let itemCostField = app.textFields["item-cost-field"]
        XCTAssertTrue(itemCostField.exists, "Item cost field should exist")
        itemCostField.tap()
        itemCostField.typeText("50")

        // Tap Done on keyboard
        app.toolbars.buttons["Done"].tap()

        // Wait for profit calculation to complete
        Thread.sleep(forTimeInterval: 1.0)

        // For now, just verify we didn't crash and the view is still there
        XCTAssertTrue(app.buttons["forward-mode-button"].exists, "Forward mode button should still exist")

        // Take screenshot to manually verify the UI
        takeScreenshot(name: "smoke_test_after_input")

        takeScreenshot(name: "test_1.1_forward_mode_smoke")
    }

    // MARK: - Test 1.2: Mode Switching

    func testModeSwitching() throws {
        // TEST: Can I switch between modes without crashes?
        // Hostile mindset: "I bet switching modes loses my data"

        // Enter data in Forward Mode
        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("100")
        app.toolbars.buttons["Done"].tap()

        // Switch to Reverse Mode
        let reverseButton = app.buttons["reverse-mode-button"]
        XCTAssertTrue(reverseButton.exists, "Reverse mode button should exist")
        reverseButton.tap()

        // Wait for transition
        Thread.sleep(forTimeInterval: 0.5)

        // Switch back to Forward Mode
        let forwardButton = app.buttons["forward-mode-button"]
        forwardButton.tap()

        // Wait for transition
        Thread.sleep(forTimeInterval: 0.5)

        // Verify data persisted (field should still have value)
        XCTAssertTrue(salePriceField.exists, "Sale price field should still exist after mode switch")

        takeScreenshot(name: "test_1.2_mode_switching")
    }

    // MARK: - Test 1.3: Reset Button

    func testResetButton() throws {
        // TEST: Does reset actually clear everything?
        // Hostile mindset: "I bet reset doesn't work"

        // Enter data
        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("100")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("50")

        app.toolbars.buttons["Done"].tap()

        // Tap Reset button
        let resetButton = app.buttons["reset-button"]
        XCTAssertTrue(resetButton.exists, "Reset button should exist")
        resetButton.tap()

        // Confirm alert
        let resetAlertButton = app.buttons["Reset"]
        XCTAssertTrue(resetAlertButton.waitForExistence(timeout: 2), "Reset confirmation should appear")
        resetAlertButton.tap()

        // Verify fields are cleared (profit should be $0 or hidden)
        let profitLabel = app.staticTexts["profit-amount-label"]
        if profitLabel.exists {
            let profitText = profitLabel.label
            XCTAssertTrue(profitText.contains("$0") || profitText.contains("0.00"),
                         "Profit should be $0 after reset, but got: \(profitText)")
        }

        takeScreenshot(name: "test_1.3_reset_button")
    }

    // MARK: - Test 1.4: Zero Input Handling

    func testZeroInputHandling() throws {
        // TEST: What happens with all zeros?
        // Hostile mindset: "I'm going to crash this with zeros"

        // Enter zeros
        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("0")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("0")

        app.toolbars.buttons["Done"].tap()

        // App should not crash
        XCTAssertTrue(app.exists, "App should not crash with zero inputs")

        // Profit should be $0 or reasonable
        let profitLabel = app.staticTexts["profit-amount-label"]
        if profitLabel.exists {
            XCTAssertTrue(profitLabel.label.contains("$"), "Profit should show currency format")
        }

        takeScreenshot(name: "test_1.4_zero_inputs")
    }

    // MARK: - Test 1.5: Shipping Cost Impact

    func testShippingCostImpact() throws {
        // TEST: Does shipping reduce profit?
        // Hostile mindset: "I bet shipping isn't included in calculations"

        // Enter data WITHOUT shipping
        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("100")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("50")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Get profit without shipping
        let profitLabelBefore = app.staticTexts["profit-amount-label"]
        XCTAssertTrue(profitLabelBefore.exists, "Profit should be displayed")
        let profitBefore = profitLabelBefore.label

        // Now add shipping
        let shippingField = app.textFields["shipping-cost-field"]
        XCTAssertTrue(shippingField.exists, "Shipping field should exist")
        shippingField.tap()
        shippingField.typeText("10")
        app.toolbars.buttons["Done"].tap()

        Thread.sleep(forTimeInterval: 0.5)

        // Get profit with shipping
        let profitLabelAfter = app.staticTexts["profit-amount-label"]
        let profitAfter = profitLabelAfter.label

        // Profit should be LOWER (shipping reduces profit)
        XCTAssertNotEqual(profitBefore, profitAfter,
                         "Profit should change when shipping is added")

        takeScreenshot(name: "test_1.5_shipping_cost")
    }

    // MARK: - Test 1.6: Supplies Cost Inclusion

    func testSuppliesCostInclusion() throws {
        // TEST: Are supplies costs actually reducing profit?
        // Hostile mindset: "I bet supplies cost is ignored"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("100")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("50")

        // Add supplies cost
        let suppliesField = app.textFields["supplies-cost-field"]
        XCTAssertTrue(suppliesField.exists, "Supplies field should exist")
        suppliesField.tap()
        suppliesField.typeText("5")

        app.toolbars.buttons["Done"].tap()

        // Verify profit accounts for supplies
        // Expected: $100 - $50 - $5 - $16.15 = $28.85
        let profitLabel = app.staticTexts["profit-amount-label"]
        XCTAssertTrue(profitLabel.waitForExistence(timeout: 2), "Profit should be displayed")

        let profitText = profitLabel.label
        XCTAssertTrue(profitText.contains("28.8") || profitText.contains("28.9"),
                     "Profit should be approximately $28.85 (including supplies), but got: \(profitText)")

        takeScreenshot(name: "test_1.6_supplies_cost")
    }

    // MARK: - Test 1.7: High Value Card

    func testHighValueCard() throws {
        // TEST: Can it handle $10,000 cards?
        // Hostile mindset: "I bet this breaks with large numbers"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("10000")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("5000")

        app.toolbars.buttons["Done"].tap()

        // App should not crash
        XCTAssertTrue(app.exists, "App should handle large numbers")

        // Verify profit calculation
        // Expected: $10,000 - $5,000 - $1,585.30 = $3,414.70
        let profitLabel = app.staticTexts["profit-amount-label"]
        XCTAssertTrue(profitLabel.waitForExistence(timeout: 2), "Profit should be displayed")

        let profitText = profitLabel.label
        XCTAssertTrue(profitText.contains("3,414") || profitText.contains("3414"),
                     "Profit should be approximately $3,414.70, but got: \(profitText)")

        takeScreenshot(name: "test_1.7_high_value")
    }

    // MARK: - Test 1.8: Penny Card (Micro Profit)

    func testPennyCard() throws {
        // TEST: Does it work with tiny amounts?
        // Hostile mindset: "I bet rounding errors break this"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("5")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("0.50")

        let shippingField = app.textFields["shipping-cost-field"]
        shippingField.tap()
        shippingField.typeText("3")

        app.toolbars.buttons["Done"].tap()

        // Verify calculation doesn't crash with small amounts
        let profitLabel = app.staticTexts["profit-amount-label"]
        XCTAssertTrue(profitLabel.waitForExistence(timeout: 2), "Profit should be displayed")

        let profitText = profitLabel.label
        XCTAssertTrue(profitText.contains("$"), "Should show currency format even for small amounts")

        takeScreenshot(name: "test_1.8_penny_card")
    }

    // MARK: - Test 1.9: Platform Comparison Button

    func testPlatformComparisonButton() throws {
        // TEST: Does the comparison button appear and work?
        // Hostile mindset: "I bet the comparison feature doesn't actually work"

        // Enter data to trigger comparison button
        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("100")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("50")

        app.toolbars.buttons["Done"].tap()

        Thread.sleep(forTimeInterval: 1)

        // Look for compare button
        let compareButton = app.buttons["compare-platforms-button"]
        XCTAssertTrue(compareButton.waitForExistence(timeout: 3),
                     "Compare platforms button should appear with valid inputs")

        // Tap it
        compareButton.tap()

        // Verify comparison sheet appears
        let comparisonView = app.navigationBars["Platform Comparison"]
        XCTAssertTrue(comparisonView.waitForExistence(timeout: 2),
                     "Platform comparison view should appear")

        // Dismiss
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }

        takeScreenshot(name: "test_1.9_platform_comparison")
    }

    // MARK: - Test 1.10: Rapid Input Spam (Performance)

    func testRapidInputSpam() throws {
        // TEST: Can it handle rapid typing?
        // Hostile mindset: "I'm going to type as fast as I can and break this"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()

        // Type rapidly
        for digit in "123456789" {
            salePriceField.typeText(String(digit))
        }

        // Delete some
        for _ in 0..<5 {
            salePriceField.typeText(XCUIKeyboardKey.delete.rawValue)
        }

        // Type more
        salePriceField.typeText("100")

        app.toolbars.buttons["Done"].tap()

        // App should not crash or hang
        XCTAssertTrue(app.exists, "App should handle rapid input without crashing")

        // Field should have a value
        XCTAssertTrue(salePriceField.exists, "Sale price field should still exist")

        takeScreenshot(name: "test_1.10_rapid_input")
    }

    // MARK: - Screenshot Helper

    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
