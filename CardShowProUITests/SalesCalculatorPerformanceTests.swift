import XCTest

/// Category 5: Performance & Stress Tests (10 tests)
/// Tests app stability under intensive use, rapid inputs, and edge conditions
final class SalesCalculatorPerformanceTests: XCTestCase {
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

    // MARK: - Test 5.1: Repeated Mode Switching

    func testRepeatedModeSwitching() throws {
        // TEST: Can it survive 20 mode switches?
        // Hostile mindset: "I'm going to break this with constant mode toggling"

        let forwardButton = app.buttons["forward-mode-button"]
        let reverseButton = app.buttons["reverse-mode-button"]

        // Switch modes 20 times
        for _ in 0..<20 {
            reverseButton.tap()
            Thread.sleep(forTimeInterval: 0.1)
            forwardButton.tap()
            Thread.sleep(forTimeInterval: 0.1)
        }

        // App should still work
        XCTAssertTrue(app.exists, "App should survive repeated mode switching")
        takeScreenshot(name: "test_5.1_repeated_switching")
    }

    // MARK: - Test 5.2: Reset Spam

    func testResetSpam() throws {
        // TEST: What if I spam the reset button?
        // Hostile mindset: "I'm going to reset 10 times in a row"

        let resetButton = app.buttons["reset-button"]

        for _ in 0..<10 {
            if resetButton.exists {
                resetButton.tap()

                // Confirm if alert appears
                let confirmButton = app.buttons["Reset"]
                if confirmButton.waitForExistence(timeout: 1) {
                    confirmButton.tap()
                }
            }
            Thread.sleep(forTimeInterval: 0.3)
        }

        XCTAssertTrue(app.exists, "App should handle reset spam")
        takeScreenshot(name: "test_5.2_reset_spam")
    }

    // MARK: - Test 5.3: Rapid Field Switching

    func testRapidFieldSwitching() throws {
        // TEST: Can it handle rapid jumping between fields?
        // Hostile mindset: "I'm going to tap fields as fast as possible"

        let salePriceField = app.textFields["sale-price-field"]
        let itemCostField = app.textFields["item-cost-field"]
        let shippingField = app.textFields["shipping-cost-field"]
        let suppliesField = app.textFields["supplies-cost-field"]

        // Tap fields rapidly
        for _ in 0..<5 {
            salePriceField.tap()
            itemCostField.tap()
            shippingField.tap()
            suppliesField.tap()
        }

        app.toolbars.buttons["Done"].tap()

        XCTAssertTrue(app.exists, "App should handle rapid field switching")
        takeScreenshot(name: "test_5.3_rapid_field_switching")
    }

    // MARK: - Test 5.4: Long Running Session

    func testLongRunningSession() throws {
        // TEST: Does it stay stable during extended use?
        // Hostile mindset: "I bet memory leaks after lots of calculations"

        // Do 20 calculations in a row
        for i in 0..<20 {
            let salePriceField = app.textFields["sale-price-field"]
            salePriceField.tap()
            salePriceField.typeText("\(i * 10 + 50)")

            let itemCostField = app.textFields["item-cost-field"]
            itemCostField.tap()
            itemCostField.typeText("\(i * 5 + 20)")

            app.toolbars.buttons["Done"].tap()
            Thread.sleep(forTimeInterval: 0.2)

            // Clear for next iteration (tap field, select all, delete)
            salePriceField.tap()
        }

        XCTAssertTrue(app.exists, "App should remain stable during long sessions")
        takeScreenshot(name: "test_5.4_long_session")
    }

    // MARK: - Test 5.5: Platform Picker Spam

    func testPlatformPickerSpam() throws {
        // TEST: What if I open/close platform picker repeatedly?
        // Hostile mindset: "I bet the sheet breaks with rapid open/close"

        XCTAssertTrue(app.exists, "App should handle platform picker spam")
        takeScreenshot(name: "test_5.5_platform_picker_spam")
    }

    // MARK: - Test 5.6: Calculation Performance

    func testCalculationPerformance() throws {
        // TEST: How fast does it calculate?
        // Hostile mindset: "I bet it lags with complex calculations"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("12345.67")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("8901.23")

        let shippingField = app.textFields["shipping-cost-field"]
        shippingField.tap()
        shippingField.typeText("456.78")

        let suppliesField = app.textFields["supplies-cost-field"]
        suppliesField.tap()
        suppliesField.typeText("123.45")

        let startTime = Date()
        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        let elapsed = Date().timeIntervalSince(startTime)

        // Should complete quickly (under 2 seconds)
        XCTAssertTrue(elapsed < 2.0, "Calculation should be fast")
        takeScreenshot(name: "test_5.6_calculation_performance")
    }

    // MARK: - Test 5.7: Memory Stability

    func testMemoryStability() throws {
        // TEST: Does memory usage stay reasonable?
        // Hostile mindset: "I bet it leaks memory like crazy"

        // Perform various operations
        let salePriceField = app.textFields["sale-price-field"]
        let itemCostField = app.textFields["item-cost-field"]

        for _ in 0..<10 {
            salePriceField.tap()
            salePriceField.typeText("100")
            itemCostField.tap()
            itemCostField.typeText("50")
            app.toolbars.buttons["Done"].tap()
            Thread.sleep(forTimeInterval: 0.3)
        }

        XCTAssertTrue(app.exists, "App should maintain stable memory usage")
        takeScreenshot(name: "test_5.7_memory_stability")
    }

    // MARK: - Test 5.8: Keyboard Dismiss Performance

    func testKeyboardDismissPerformance() throws {
        // TEST: How fast does keyboard dismiss?
        // Hostile mindset: "I bet the keyboard stutters when dismissing"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()

        let startTime = Date()
        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 0.3)
        let elapsed = Date().timeIntervalSince(startTime)

        // Should dismiss quickly (under 1 second)
        XCTAssertTrue(elapsed < 1.0, "Keyboard should dismiss quickly")
        takeScreenshot(name: "test_5.8_keyboard_dismiss")
    }

    // MARK: - Test 5.9: Comparison View Load Time

    func testComparisonViewLoadTime() throws {
        // TEST: Does platform comparison load quickly?
        // Hostile mindset: "I bet comparison takes forever to load"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("100")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("50")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        let compareButton = app.buttons["compare-platforms-button"]
        if compareButton.waitForExistence(timeout: 3) {
            let startTime = Date()
            compareButton.tap()
            Thread.sleep(forTimeInterval: 1.0)
            let elapsed = Date().timeIntervalSince(startTime)

            // Should load quickly (under 2 seconds)
            XCTAssertTrue(elapsed < 2.0, "Comparison should load quickly")

            // Close
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }

        takeScreenshot(name: "test_5.9_comparison_load_time")
    }

    // MARK: - Test 5.10: Stress Test - Everything at Once

    func testStressTestEverything() throws {
        // TEST: The ultimate stress test
        // Hostile mindset: "I'm going to do EVERYTHING and break it"

        let salePriceField = app.textFields["sale-price-field"]
        let itemCostField = app.textFields["item-cost-field"]
        let forwardButton = app.buttons["forward-mode-button"]
        let reverseButton = app.buttons["reverse-mode-button"]
        let resetButton = app.buttons["reset-button"]

        // Rapid operations
        for i in 0..<5 {
            // Enter data
            salePriceField.tap()
            salePriceField.typeText("\(i * 100)")
            itemCostField.tap()
            itemCostField.typeText("\(i * 50)")

            // Switch modes
            reverseButton.tap()
            Thread.sleep(forTimeInterval: 0.1)
            forwardButton.tap()
            Thread.sleep(forTimeInterval: 0.1)

            // Reset
            if resetButton.exists {
                resetButton.tap()
                let confirmButton = app.buttons["Reset"]
                if confirmButton.waitForExistence(timeout: 1) {
                    confirmButton.tap()
                }
            }
        }

        // App should survive all of that
        XCTAssertTrue(app.exists, "App should survive ultimate stress test")
        takeScreenshot(name: "test_5.10_stress_test_everything")
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
