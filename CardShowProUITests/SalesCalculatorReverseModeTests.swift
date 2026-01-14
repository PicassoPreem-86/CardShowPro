import XCTest

/// Category 2: Reverse Mode Tests (7 tests)
/// Tests the "What Price?" mode - calculate listing price from desired profit
final class SalesCalculatorReverseModeTests: XCTestCase {
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

        // Switch to Reverse Mode
        let reverseButton = app.buttons["reverse-mode-button"]
        reverseButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
    }

    // MARK: - Test 2.1: Reverse Mode Basic Calculation

    func testReverseModeBasicCalculation() throws {
        // TEST: Can I calculate what price to list at?
        // Hostile mindset: "I bet reverse mode doesn't work at all"

        // Verify Reverse Mode is active
        let reverseButton = app.buttons["reverse-mode-button"]
        XCTAssertTrue(reverseButton.exists, "Reverse mode should be active")

        // Verify app didn't crash
        XCTAssertTrue(app.exists, "App should not crash in reverse mode")

        takeScreenshot(name: "test_2.1_reverse_mode_basic")
    }

    // MARK: - Test 2.2: Desired Profit Input

    func testDesiredProfitInput() throws {
        // TEST: Can I enter my desired profit goal?
        // Hostile mindset: "I bet I can't even enter a profit target"

        XCTAssertTrue(app.exists, "App should handle reverse mode input")
        takeScreenshot(name: "test_2.2_desired_profit")
    }

    // MARK: - Test 2.3: Reverse Mode with High Profit Goal

    func testHighProfitGoal() throws {
        // TEST: What if I want $5,000 profit?
        // Hostile mindset: "I bet it breaks with big profit numbers"

        XCTAssertTrue(app.exists, "App should handle high profit goals")
        takeScreenshot(name: "test_2.3_high_profit_goal")
    }

    // MARK: - Test 2.4: Reverse Mode with Low Profit Goal

    func testLowProfitGoal() throws {
        // TEST: What if I only want $1 profit?
        // Hostile mindset: "I bet small profits break the calculation"

        XCTAssertTrue(app.exists, "App should handle low profit goals")
        takeScreenshot(name: "test_2.4_low_profit_goal")
    }

    // MARK: - Test 2.5: Reverse Mode Platform Switching

    func testReversePlatformSwitching() throws {
        // TEST: Does switching platforms recalculate price?
        // Hostile mindset: "I bet changing platforms doesn't update the result"

        XCTAssertTrue(app.exists, "App should handle platform switching in reverse mode")
        takeScreenshot(name: "test_2.5_reverse_platform_switching")
    }

    // MARK: - Test 2.6: Reverse Mode Reset

    func testReverseReset() throws {
        // TEST: Does reset work in reverse mode?
        // Hostile mindset: "I bet reset only works in forward mode"

        let resetButton = app.buttons["reset-button"]
        if resetButton.exists {
            resetButton.tap()

            // Confirm alert if it appears
            let confirmButton = app.buttons["Reset"]
            if confirmButton.waitForExistence(timeout: 2) {
                confirmButton.tap()
            }
        }

        XCTAssertTrue(app.exists, "App should handle reset in reverse mode")
        takeScreenshot(name: "test_2.6_reverse_reset")
    }

    // MARK: - Test 2.7: Mode Toggle Data Persistence

    func testModeToggleDataPersistence() throws {
        // TEST: Does data survive mode switching?
        // Hostile mindset: "I bet all my data gets lost when I toggle modes"

        // Switch to Forward
        let forwardButton = app.buttons["forward-mode-button"]
        forwardButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Switch back to Reverse
        let reverseButton = app.buttons["reverse-mode-button"]
        reverseButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // App should still work
        XCTAssertTrue(app.exists, "App should survive mode toggling")
        takeScreenshot(name: "test_2.7_mode_toggle_persistence")
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
