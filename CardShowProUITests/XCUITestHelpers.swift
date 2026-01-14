import XCTest

/// Helper extensions and utilities for XCUITest automation
/// Makes test code more readable and reusable

// MARK: - XCUIApplication Extensions

extension XCUIApplication {
    /// Navigate to Sales Calculator from any screen
    func navigateToSalesCalculator() {
        // Tap Tools tab
        let toolsTab = tabBars.buttons["Tools"]
        if toolsTab.waitForExistence(timeout: 5) {
            toolsTab.tap()
        }

        // Tap Sales Calculator
        let salesCalcButton = buttons.matching(identifier: "sales-calculator-button").firstMatch
        if salesCalcButton.exists {
            salesCalcButton.tap()
        } else {
            // Fallback: find by text
            buttons["Sales Calculator"].tap()
        }

        // Wait for view to load by checking for mode toggle
        _ = buttons["forward-mode-button"].waitForExistence(timeout: 5)
    }

    /// Enter value in sale price field
    func enterSalePrice(_ amount: String) {
        let field = textFields["sale-price-field"]
        field.tap()
        field.typeText(amount)
    }

    /// Enter value in item cost field
    func enterItemCost(_ amount: String) {
        let field = textFields["item-cost-field"]
        field.tap()
        field.typeText(amount)
    }

    /// Enter value in shipping cost field
    func enterShippingCost(_ amount: String) {
        let field = textFields["shipping-cost-field"]
        field.tap()
        field.typeText(amount)
    }

    /// Enter value in supplies cost field
    func enterSuppliesCost(_ amount: String) {
        let field = textFields["supplies-cost-field"]
        field.tap()
        field.typeText(amount)
    }

    /// Get displayed profit amount
    func getDisplayedProfit() -> String? {
        let profitLabel = staticTexts["profit-amount-label"]
        return profitLabel.exists ? profitLabel.label : nil
    }

    /// Switch to Forward Mode
    func switchToForwardMode() {
        buttons["forward-mode-button"].tap()
    }

    /// Switch to Reverse Mode
    func switchToReverseMode() {
        buttons["reverse-mode-button"].tap()
    }

    /// Tap Reset button and confirm
    func resetCalculator() {
        buttons["reset-button"].tap()
        buttons["Reset"].tap()
    }

    /// Tap Done on keyboard
    func dismissKeyboard() {
        toolbars.buttons["Done"].tap()
    }

    /// Take screenshot with custom name
    func takeScreenshot(named name: String, in testCase: XCTestCase) {
        let screenshot = self.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Wait for element to exist and be hittable
    func waitForHittable(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Tap element only if it exists
    func tapIfExists() -> Bool {
        guard exists else { return false }
        tap()
        return true
    }

    /// Clear text field and enter new text
    func clearAndEnterText(_ text: String) {
        guard exists else { return }
        tap()

        // Select all existing text
        press(forDuration: 1.0)
        if app.menuItems["Select All"].exists {
            app.menuItems["Select All"].tap()
        }

        // Type new text
        typeText(text)
    }

    /// Get text value from label or field
    var textValue: String {
        return value as? String ?? label
    }

    private var app: XCUIApplication {
        return XCUIApplication()
    }
}

// MARK: - Test Assertions

extension XCTestCase {
    /// Assert currency value is approximately equal (within $0.10)
    func XCTAssertCurrencyApproximate(_ actual: String, _ expected: Decimal, accuracy: Decimal = 0.10, file: StaticString = #file, line: UInt = #line) {
        // Extract decimal value from currency string
        let cleanedString = actual.replacingOccurrences(of: "$", with: "")
                                 .replacingOccurrences(of: ",", with: "")
                                 .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let actualValue = Decimal(string: cleanedString) else {
            XCTFail("Could not parse currency value from: \(actual)", file: file, line: line)
            return
        }

        let difference = abs(actualValue - expected)
        XCTAssertLessThanOrEqual(difference, accuracy,
                                "Currency value \(actual) is not within \(accuracy) of expected \(expected)",
                                file: file, line: line)
    }

    /// Assert profit matches expected value
    func XCTAssertProfit(in app: XCUIApplication, equals expected: Decimal, accuracy: Decimal = 0.10, file: StaticString = #file, line: UInt = #line) {
        let profitLabel = app.staticTexts["profit-amount-label"]
        XCTAssertTrue(profitLabel.exists, "Profit label should exist", file: file, line: line)

        let profitText = profitLabel.label
        XCTAssertCurrencyApproximate(profitText, expected, accuracy: accuracy, file: file, line: line)
    }
}

// MARK: - Wait Helpers

extension XCTestCase {
    /// Wait for condition to be true
    func waitFor(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 5, description: String = "Condition") {
        let startTime = Date()
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("\(description) timed out after \(timeout) seconds")
                return
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }

    /// Wait for element and return it
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> XCUIElement? {
        guard element.waitForExistence(timeout: timeout) else {
            return nil
        }
        return element
    }
}

// MARK: - Decimal Helpers

extension Decimal {
    /// Convert Decimal to currency string for comparison
    var asCurrencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: self as NSNumber) ?? "$0.00"
    }
}
