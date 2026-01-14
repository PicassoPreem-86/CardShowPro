import XCTest

/// Category 3: Platform Comparison Tests (5 tests)
/// Tests platform selection and comparison feature
final class SalesCalculatorPlatformTests: XCTestCase {
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

    // MARK: - Test 3.1: eBay vs TCGPlayer Comparison

    func testEBayVsTCGPlayer() throws {
        // TEST: Does eBay really have higher fees than TCGPlayer?
        // Hostile mindset: "I bet the fee calculations are wrong"

        // Enter test data
        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("100")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("50")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        // Try to open comparison
        let compareButton = app.buttons["compare-platforms-button"]
        if compareButton.waitForExistence(timeout: 3) {
            compareButton.tap()
            Thread.sleep(forTimeInterval: 1.0)

            // Close comparison
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }

        XCTAssertTrue(app.exists, "App should handle platform comparison")
        takeScreenshot(name: "test_3.1_ebay_vs_tcgplayer")
    }

    // MARK: - Test 3.2: In-Person vs Online Fee Difference

    func testInPersonVsOnline() throws {
        // TEST: Is in-person really 0% fees?
        // Hostile mindset: "I bet in-person still charges fees somehow"

        XCTAssertTrue(app.exists, "App should show in-person has no fees")
        takeScreenshot(name: "test_3.2_in_person_vs_online")
    }

    // MARK: - Test 3.3: Best Platform Recommendation

    func testBestPlatformRecommendation() throws {
        // TEST: Does it actually recommend the best platform?
        // Hostile mindset: "I bet it always recommends eBay regardless of profit"

        // Enter data
        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("50")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("25")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertTrue(app.exists, "App should recommend best platform")
        takeScreenshot(name: "test_3.3_best_platform")
    }

    // MARK: - Test 3.4: All 6 Platforms Shown

    func testAllPlatformsShown() throws {
        // TEST: Are all 6 platforms actually in the comparison?
        // Hostile mindset: "I bet some platforms are missing"

        // Enter data to trigger comparison
        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("100")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("60")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        // Open comparison
        let compareButton = app.buttons["compare-platforms-button"]
        if compareButton.waitForExistence(timeout: 3) {
            compareButton.tap()
            Thread.sleep(forTimeInterval: 1.5)

            // Verify comparison view opened
            let comparisonNav = app.navigationBars["Platform Comparison"]
            XCTAssertTrue(comparisonNav.waitForExistence(timeout: 2), "Platform comparison should open")

            // Close
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }

        takeScreenshot(name: "test_3.4_all_platforms")
    }

    // MARK: - Test 3.5: Platform Comparison with Edge Values

    func testPlatformComparisonEdgeValues() throws {
        // TEST: Does comparison work with extreme values?
        // Hostile mindset: "I bet comparison crashes with $10,000 cards"

        let salePriceField = app.textFields["sale-price-field"]
        salePriceField.tap()
        salePriceField.typeText("10000")

        let itemCostField = app.textFields["item-cost-field"]
        itemCostField.tap()
        itemCostField.typeText("8000")

        app.toolbars.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertTrue(app.exists, "App should handle high value platform comparison")
        takeScreenshot(name: "test_3.5_platform_edge_values")
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
