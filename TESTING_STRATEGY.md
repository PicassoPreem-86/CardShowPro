# CardShow Pro - Testing Strategy

**Version:** 1.0
**Last Updated:** January 13, 2026
**Document Owner:** QA & Engineering Team
**Status:** Active Development

---

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Testing Pyramid](#testing-pyramid)
3. [Unit Testing Strategy](#unit-testing-strategy)
4. [Integration Testing](#integration-testing)
5. [UI Testing](#ui-testing)
6. [API Testing](#api-testing)
7. [Performance Testing](#performance-testing)
8. [Manual Testing](#manual-testing)
9. [Device & OS Matrix](#device--os-matrix)
10. [Pre-Release QA Checklist](#pre-release-qa-checklist)
11. [Continuous Integration](#continuous-integration)
12. [Test Coverage Goals](#test-coverage-goals)

---

## Testing Philosophy

### Core Principles

1. **Test Business Logic, Not SwiftUI Views** - Views are disposable, logic is critical
2. **Integration Tests > Unit Tests > UI Tests** - Prioritize tests that catch real bugs
3. **Fast Feedback Loops** - Tests should run in <10 seconds for rapid iteration
4. **Test What Matters** - Focus on user-facing functionality and edge cases
5. **Fail Fast** - One failing test should stop the suite immediately

### What We Test

✅ **High Priority:**
- API integrations (PokemonTCG.io, TCGDex, etc.)
- SwiftData persistence (saving, loading, migrations)
- Business logic (profit calculations, trade percentages, pricing)
- State management (@Observable models)
- Error handling and edge cases

✅ **Medium Priority:**
- Service layer (PricingService, CameraManager)
- Caching logic (memory + disk)
- Navigation flows
- Data transformations

❌ **Low Priority / Skip:**
- SwiftUI view layout (test manually)
- Third-party libraries (trust their tests)
- Trivial getters/setters
- UI animations

---

## Testing Pyramid

Our testing distribution follows the industry-standard pyramid:

```
       /\
      /UI\       10% - Critical user flows only
     /────\
    /  IT  \     30% - API + persistence integration
   /────────\
  /   Unit   \   60% - Business logic, models, services
 /────────────\
```

### Target Distribution

| Test Type | % of Total | Quantity (V1) | Run Time | Frequency |
|-----------|-----------|---------------|----------|-----------|
| **Unit Tests** | 60% | ~150 tests | <5 sec | Every commit |
| **Integration Tests** | 30% | ~75 tests | <30 sec | Every commit |
| **UI Tests** | 10% | ~25 tests | <2 min | Before release |

**Total:** ~250 tests running in <3 minutes

---

## Unit Testing Strategy

### Framework: Swift Testing

We use **Swift Testing** (not XCTest) for all unit tests.

**Why Swift Testing:**
- Modern async/await support
- Better error messages
- Parameterized tests built-in
- Cleaner syntax with `@Test` and `#expect`

### Location

`CardShowProPackage/Tests/CardShowProFeatureTests/`

### Test Structure

```swift
import Testing
@testable import CardShowProFeature

@Suite("Pricing Calculations")
struct PricingTests {

    @Test("Calculate profit margin correctly")
    func profitMarginCalculation() {
        let purchaseCost = 50.0
        let marketValue = 100.0
        let expectedProfit = 50.0

        let profit = marketValue - purchaseCost

        #expect(profit == expectedProfit)
    }

    @Test("Negative profit when market value below cost")
    func negativeProfitScenario() {
        let purchaseCost = 100.0
        let marketValue = 50.0

        let profit = marketValue - purchaseCost

        #expect(profit < 0)
        #expect(profit == -50.0)
    }
}
```

---

### Unit Test Categories

#### 1. Model Tests

**Test:** Data model initialization, validation, computed properties

**Example:**
```swift
@Suite("Card Model")
struct CardModelTests {

    @Test("Card initializes with valid data")
    func cardInitialization() {
        let card = Card(
            id: "base1-4",
            name: "Charizard",
            setName: "Base Set",
            number: "4",
            imageURL: URL(string: "https://example.com/card.png")!
        )

        #expect(card.id == "base1-4")
        #expect(card.name == "Charizard")
        #expect(card.displayName == "Charizard #4")
    }

    @Test("Card with purchase cost calculates profit")
    func profitCalculation() {
        var card = Card(id: "1", name: "Test", setName: "Set", number: "1")
        card.purchaseCost = 50.0
        card.marketValue = 100.0

        #expect(card.profit == 50.0)
        #expect(card.profitMargin == 0.5) // 50%
    }
}
```

---

#### 2. State Management Tests

**Test:** @Observable models, state transitions, computed properties

**Example:**
```swift
@Suite("PriceLookupState")
struct PriceLookupStateTests {

    @Test("Initial state is empty")
    func initialState() {
        let state = PriceLookupState()

        #expect(state.cardName.isEmpty)
        #expect(state.cardNumber.isEmpty)
        #expect(state.selectedMatch == nil)
        #expect(state.canLookupPrice == false)
    }

    @Test("Can lookup price when card name provided")
    func lookupEnabledWithCardName() {
        var state = PriceLookupState()
        state.cardName = "Charizard"

        #expect(state.canLookupPrice == true)
    }

    @Test("Loading state prevents multiple lookups")
    func loadingPreventsLookup() {
        var state = PriceLookupState()
        state.cardName = "Charizard"
        state.isLoading = true

        #expect(state.canLookupPrice == false)
    }
}
```

---

#### 3. Business Logic Tests

**Test:** Calculations, algorithms, trade logic, pricing formulas

**Example:**
```swift
@Suite("Trade Calculator")
struct TradeCalculatorTests {

    @Test("Calculate trade value with 80% discount", arguments: [
        (marketValue: 100.0, percentage: 0.80, expected: 80.0),
        (marketValue: 250.0, percentage: 0.80, expected: 200.0),
        (marketValue: 50.0, percentage: 0.80, expected: 40.0)
    ])
    func tradeValueCalculation(marketValue: Double, percentage: Double, expected: Double) {
        let tradeValue = marketValue * percentage
        #expect(tradeValue == expected)
    }

    @Test("Trade is balanced when values match")
    func balancedTrade() {
        let myCards: [Card] = [
            Card(id: "1", name: "A", marketValue: 50.0),
            Card(id: "2", name: "B", marketValue: 30.0)
        ]

        let theirCards: [Card] = [
            Card(id: "3", name: "C", marketValue: 100.0)
        ]

        let myTotal = myCards.reduce(0) { $0 + $1.marketValue }
        let theirTotal = theirCards.reduce(0) { $0 + $1.marketValue * 0.80 }

        #expect(myTotal == 80.0)
        #expect(theirTotal == 80.0)
        #expect(myTotal == theirTotal) // Balanced!
    }
}
```

---

#### 4. Service Tests (with Mocks)

**Test:** Service layer logic without actual API calls

**Example:**
```swift
// Mock API for testing
actor MockCardAPI: CardDataAPI {
    var searchResult: Result<[Card], Error> = .success([])

    func searchCards(query: String) async throws -> [Card] {
        try searchResult.get()
    }
}

@Suite("PricingService")
struct PricingServiceTests {

    @Test("Returns cards from API")
    func successfulSearch() async throws {
        let mockAPI = MockCardAPI()
        let expectedCards = [
            Card(id: "1", name: "Charizard", setName: "Base Set", number: "4")
        ]
        mockAPI.searchResult = .success(expectedCards)

        let service = PricingService(api: mockAPI)
        let results = try await service.searchCards(query: "Charizard")

        #expect(results.count == 1)
        #expect(results.first?.name == "Charizard")
    }

    @Test("Handles API errors gracefully")
    func apiErrorHandling() async throws {
        let mockAPI = MockCardAPI()
        mockAPI.searchResult = .failure(APIError.networkUnavailable)

        let service = PricingService(api: mockAPI)

        await #expect(throws: APIError.self) {
            try await service.searchCards(query: "Charizard")
        }
    }
}
```

---

### Coverage Goals

| Component | Target Coverage | Priority |
|-----------|----------------|----------|
| **Models** | 90%+ | HIGH |
| **Business Logic** | 90%+ | HIGH |
| **State Management** | 85%+ | HIGH |
| **Services** | 80%+ | MEDIUM |
| **Utilities** | 70%+ | MEDIUM |
| **Views** | 0% (manual testing) | N/A |

**Overall Target:** 80%+ code coverage

---

## Integration Testing

### What We Test

Integration tests verify that multiple components work together correctly:

- API → Service → State → View flow
- SwiftData persistence end-to-end
- Caching layers (memory + disk)
- Navigation between screens

### Example: API Integration Test

```swift
@Suite("PokemonTCG.io Integration")
struct PokemonAPIIntegrationTests {

    @Test("Search returns real results", .tags(.integration, .api))
    func realAPISearch() async throws {
        let service = PokemonTCGService.shared

        let results = try await service.searchCards(query: "Charizard")

        #expect(!results.isEmpty)
        #expect(results.first?.name.contains("Charizard") == true)
    }

    @Test("Get pricing for known card", .tags(.integration, .api))
    func getPricing() async throws {
        let service = PokemonTCGService.shared

        // Base Set Charizard (known card)
        let pricing = try await service.getPricing(cardId: "base1-4")

        #expect(pricing.marketPrice > 0)
        #expect(pricing.lowPrice > 0)
        #expect(pricing.highPrice > pricing.lowPrice)
    }
}
```

**Note:** Integration tests hit real APIs, so run them less frequently to avoid rate limits.

---

### SwiftData Persistence Tests

```swift
import SwiftData
import Testing

@Suite("SwiftData Persistence")
struct PersistenceTests {

    @Test("Save and retrieve card from database")
    func saveAndLoadCard() async throws {
        // Create in-memory model container for testing
        let container = try ModelContainer(
            for: InventoryCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let context = ModelContext(container)

        // Create and save card
        let card = InventoryCard(
            name: "Charizard",
            setName: "Base Set",
            number: "4",
            purchaseCost: 50.0,
            marketValue: 100.0
        )
        context.insert(card)
        try context.save()

        // Fetch card back
        let descriptor = FetchDescriptor<InventoryCard>()
        let cards = try context.fetch(descriptor)

        #expect(cards.count == 1)
        #expect(cards.first?.name == "Charizard")
        #expect(cards.first?.purchaseCost == 50.0)
    }

    @Test("Update card market value")
    func updateCard() async throws {
        let container = try ModelContainer(
            for: InventoryCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        // Create card
        let card = InventoryCard(name: "Test", marketValue: 100.0)
        context.insert(card)
        try context.save()

        // Update value
        card.marketValue = 150.0
        try context.save()

        // Verify update persisted
        let descriptor = FetchDescriptor<InventoryCard>()
        let cards = try context.fetch(descriptor)

        #expect(cards.first?.marketValue == 150.0)
    }
}
```

---

### Caching Tests

```swift
@Suite("Price Caching")
struct CachingTests {

    @Test("Cache stores and retrieves prices")
    func cacheStoreAndRetrieve() async {
        let cache = MemoryCache<String, CardPricing>(ttl: 300)

        let pricing = CardPricing(
            cardId: "base1-4",
            marketPrice: 100.0,
            lowPrice: 80.0,
            highPrice: 120.0
        )

        await cache.set("base1-4", value: pricing)
        let retrieved = await cache.get("base1-4")

        #expect(retrieved?.marketPrice == 100.0)
    }

    @Test("Expired cache entries return nil")
    func cacheExpiration() async throws {
        let cache = MemoryCache<String, CardPricing>(ttl: 0.1) // 100ms TTL

        let pricing = CardPricing(cardId: "1", marketPrice: 100.0)
        await cache.set("1", value: pricing)

        // Wait for expiration
        try await Task.sleep(for: .milliseconds(200))

        let retrieved = await cache.get("1")
        #expect(retrieved == nil)
    }
}
```

---

## UI Testing

### Framework: XCUITest

We use XCUITest for critical user flow testing only.

**Location:** `CardShowProUITests/`

### What We Test

✅ **Critical Flows:**
- App launch and tab navigation
- Price lookup end-to-end
- Add card to inventory
- Vendor mode event creation
- Error state recovery

❌ **Skip:**
- Layout edge cases (manual testing)
- Complex interactions (use integration tests)
- Visual design (use SwiftUI previews)

---

### Example: UI Test

```swift
import XCTest

final class CardShowProUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testDashboardToScanFlow() throws {
        // Verify dashboard loads
        XCTAssertTrue(app.navigationBars["CardShow Pro"].exists)

        // Tap Scan tab
        app.tabBars.buttons["Scan"].tap()

        // Verify price lookup view appears
        XCTAssertTrue(app.navigationBars["Card Price Lookup"].exists)

        // Type card name
        let cardNameField = app.textFields["Card Name"]
        XCTAssertTrue(cardNameField.exists)
        cardNameField.tap()
        cardNameField.typeText("Charizard")

        // Verify lookup button enabled
        let lookupButton = app.buttons["Look Up Price"]
        XCTAssertTrue(lookupButton.isEnabled)
    }

    func testPriceLookupFlow() throws {
        // Navigate to price lookup
        app.tabBars.buttons["Scan"].tap()

        // Enter card details
        app.textFields["Card Name"].tap()
        app.textFields["Card Name"].typeText("Pikachu")

        // Tap lookup button
        app.buttons["Look Up Price"].tap()

        // Wait for results (with timeout)
        let resultsExist = app.staticTexts["Search Results"]
            .waitForExistence(timeout: 5)

        XCTAssertTrue(resultsExist, "Search results should appear within 5 seconds")
    }

    func testErrorRecovery() throws {
        // Simulate network error by searching with invalid input
        app.tabBars.buttons["Scan"].tap()
        app.textFields["Card Name"].tap()
        app.textFields["Card Name"].typeText("@@@@@") // Invalid search

        app.buttons["Look Up Price"].tap()

        // Verify error message appears
        let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Error'")).firstMatch
        let errorExists = errorMessage.waitForExistence(timeout: 5)

        XCTAssertTrue(errorExists, "Error message should appear")

        // Dismiss error
        app.buttons["Dismiss"].tap()

        // Verify can try again
        XCTAssertTrue(app.textFields["Card Name"].exists)
    }
}
```

---

### UI Testing Best Practices

1. **Use Accessibility Identifiers**
```swift
// In SwiftUI view
TextField("Card Name", text: $cardName)
    .accessibilityIdentifier("cardNameField")

// In UI test
app.textFields["cardNameField"].tap()
```

2. **Wait for Elements**
```swift
let element = app.buttons["Submit"]
XCTAssertTrue(element.waitForExistence(timeout: 5))
```

3. **Test One Flow Per Test**
```swift
// ✅ Good - focused test
func testAddCardFlow() { /* ... */ }

// ❌ Bad - testing multiple flows
func testAllFeatures() { /* ... */ }
```

4. **Reset App State**
```swift
override func setUp() {
    app.launchArguments = ["--uitesting"]
    app.launch()
}
```

---

## API Testing

### Mock vs Real API Testing

**Development:** Use mock APIs
**CI/CD:** Use real APIs (with rate limiting)
**Manual QA:** Use real APIs

### Mock API Example

```swift
actor MockPokemonAPI: CardDataAPI {
    var shouldFail = false
    var delay: Duration = .zero

    func searchCards(query: String) async throws -> [Card] {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }

        if shouldFail {
            throw APIError.networkUnavailable
        }

        return [
            Card(id: "1", name: "Charizard", setName: "Base Set", number: "4"),
            Card(id: "2", name: "Pikachu", setName: "Base Set", number: "25")
        ]
    }
}
```

### Real API Testing

```swift
@Suite("Real API Tests", .tags(.integration, .slow))
struct RealAPITests {

    @Test("PokemonTCG.io returns results", .timeLimit(.minutes(1)))
    func pokemonAPISearch() async throws {
        let api = PokemonTCGService.shared
        let results = try await api.searchCards(query: "Charizard")

        #expect(!results.isEmpty)
    }
}
```

**Run sparingly to avoid rate limits:**
```bash
# Skip integration tests by default
swift test --filter "!integration"

# Run all tests (including integration)
swift test
```

---

## Performance Testing

### What We Measure

1. **App Launch Time** - Target: <3 seconds cold start
2. **API Response Time** - Target: <2 seconds for price lookup
3. **UI Responsiveness** - Target: 60 FPS during scrolling
4. **Memory Usage** - Target: <100 MB for typical usage

### Performance Test Example

```swift
@Suite("Performance")
struct PerformanceTests {

    @Test("Price lookup completes within 2 seconds")
    func priceLookupPerformance() async throws {
        let service = PricingService.shared

        let start = Date()
        _ = try await service.searchCards(query: "Charizard")
        let duration = Date().timeIntervalSince(start)

        #expect(duration < 2.0, "Price lookup should complete in <2 seconds, took \(duration)s")
    }

    @Test("Loading 1000 inventory cards is performant")
    func inventoryLoadPerformance() async throws {
        let container = try ModelContainer(for: InventoryCard.self)
        let context = ModelContext(container)

        // Insert 1000 cards
        for i in 1...1000 {
            let card = InventoryCard(name: "Card \(i)", marketValue: Double(i))
            context.insert(card)
        }
        try context.save()

        // Measure fetch time
        let start = Date()
        let descriptor = FetchDescriptor<InventoryCard>()
        let cards = try context.fetch(descriptor)
        let duration = Date().timeIntervalSince(start)

        #expect(cards.count == 1000)
        #expect(duration < 0.5, "Should load 1000 cards in <500ms, took \(duration * 1000)ms")
    }
}
```

### Instruments Profiling

**When to profile:**
- App feels sluggish
- Memory usage growing
- Battery drain complaints
- Before each release

**Tools:**
- Time Profiler (CPU usage)
- Allocations (memory leaks)
- Leaks (retain cycles)
- Network (API usage)

---

## Manual Testing

### Pre-Release Manual Test Checklist

Run this checklist before EVERY release:

#### ✅ Core Functionality

**Price Lookup:**
- [ ] Search for common card (e.g., "Charizard") - returns results
- [ ] Search for obscure card - handles gracefully
- [ ] Search with typo - shows "no results" or suggestions
- [ ] View card with multiple variants - all variants shown
- [ ] Pricing data displays correctly (market, low, mid, high)
- [ ] Card images load and display

**Inventory:**
- [ ] Add card to inventory - saves successfully
- [ ] Edit card details - updates persist
- [ ] Delete card - removes from list
- [ ] Search inventory - filters correctly
- [ ] Sort by name/value/date - works correctly
- [ ] View profit margins - calculates correctly

**Vendor Mode:**
- [ ] Create new event - saves to list
- [ ] Start event session - activates vendor mode
- [ ] Record sale - updates inventory and totals
- [ ] End event - generates report
- [ ] View past events - shows history

#### ✅ Error Handling

- [ ] Airplane mode - shows offline message, uses cache
- [ ] API timeout - shows error, allows retry
- [ ] Invalid card search - clear error message
- [ ] Camera permission denied - shows Settings link
- [ ] Empty states - display helpful messages

#### ✅ UI/UX

- [ ] All tabs navigate correctly
- [ ] Back buttons work
- [ ] Loading indicators show during async operations
- [ ] Pull to refresh works where implemented
- [ ] Alerts/sheets dismiss properly
- [ ] Keyboard dismisses when expected

#### ✅ Edge Cases

- [ ] Very long card name - displays without overflow
- [ ] Card with no pricing data - shows "N/A"
- [ ] Inventory with 1000+ cards - scrolls smoothly
- [ ] Rapid button tapping - doesn't crash or duplicate actions
- [ ] Switch between tabs quickly - no state issues

#### ✅ Device-Specific

- [ ] iPhone SE (small screen) - UI fits
- [ ] iPhone Pro Max (large screen) - no weird spacing
- [ ] iPad - responsive layout
- [ ] Dark mode - all text readable
- [ ] Dynamic Type Large - text scales

---

### Exploratory Testing Sessions

**Schedule:** Weekly 1-hour sessions

**Process:**
1. Pick a feature or flow
2. Use app as real user would
3. Try to break things
4. Document any issues found

**Focus Areas:**
- New features just implemented
- Recently reported bugs
- High-risk areas (payment, data loss)

---

## Device & OS Matrix

### Minimum Supported

- **iOS Version:** 17.0+
- **Devices:** iPhone 8 and newer

### Testing Matrix

| Device | iOS Version | Priority | Notes |
|--------|-------------|----------|-------|
| **iPhone SE (3rd gen)** | 17.0 | HIGH | Smallest screen |
| **iPhone 15** | 18.0 | HIGH | Most common |
| **iPhone 16 Pro Max** | 18.5 | MEDIUM | Largest screen |
| **iPad Pro 13"** | 18.0 | MEDIUM | Tablet layout |
| **iPhone 12** | 17.5 | LOW | Legacy support |

### Simulator Testing

**Daily:** iPhone 16 (latest iOS)
**Weekly:** iPhone SE, iPhone Pro Max, iPad
**Pre-Release:** All supported devices

---

## Pre-Release QA Checklist

Run this 1 week before App Store submission:

### ✅ Functional Testing
- [ ] All manual test checklist items pass
- [ ] All automated tests pass (unit + integration + UI)
- [ ] No known critical bugs
- [ ] No known crash bugs

### ✅ Performance
- [ ] App launches in <3 seconds
- [ ] Price lookup <2 seconds
- [ ] Memory usage <100 MB
- [ ] No memory leaks detected
- [ ] Battery usage acceptable

### ✅ Accessibility
- [ ] VoiceOver tested on critical flows
- [ ] Dynamic Type tested (Small to XXXL)
- [ ] High Contrast mode tested
- [ ] All interactive elements have labels

### ✅ App Store Requirements
- [ ] Privacy policy URL set
- [ ] App Store screenshots updated
- [ ] App description accurate
- [ ] Version number bumped
- [ ] Build number incremented
- [ ] Correct entitlements enabled

### ✅ Legal/Compliance
- [ ] No placeholder content
- [ ] No test data in production
- [ ] API keys secured (not hardcoded)
- [ ] No prohibited content (per App Store guidelines)

---

## Continuous Integration

### GitHub Actions Workflow

```yaml
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode.app

    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -workspace CardShowPro.xcworkspace \
          -scheme CardShowPro \
          -destination 'platform=iOS Simulator,name=iPhone 16' \
          -skip-testing:CardShowProUITests

    - name: Run Integration Tests
      run: swift test --package-path CardShowProPackage

    - name: Upload Coverage
      uses: codecov/codecov-action@v3
```

### Pre-Commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running tests before commit..."

# Run unit tests
swift test --package-path CardShowProPackage --filter "!integration"

if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Commit aborted."
  exit 1
fi

echo "✅ Tests passed."
exit 0
```

---

## Test Coverage Goals

### By Component

| Component | Current | Target | Priority |
|-----------|---------|--------|----------|
| **Models** | 0% | 90% | HIGH |
| **Services** | 0% | 80% | HIGH |
| **State Management** | 0% | 85% | HIGH |
| **Business Logic** | 0% | 90% | HIGH |
| **Views** | 0% | 0% | N/A |
| **Overall** | 0% | 80% | HIGH |

### Milestones

**V1 MVP (Month 3):**
- [ ] 80%+ unit test coverage
- [ ] 50%+ integration test coverage
- [ ] 10+ UI tests for critical flows
- [ ] All tests pass on CI

**V2 Multi-Game (Month 9):**
- [ ] 85%+ unit test coverage
- [ ] 60%+ integration test coverage
- [ ] 20+ UI tests

**V3 AI Features (Month 12):**
- [ ] 90%+ unit test coverage
- [ ] 70%+ integration test coverage
- [ ] 30+ UI tests

---

## Testing Tools & Resources

### Recommended Tools

- **Swift Testing** - Unit testing framework
- **XCUITest** - UI testing
- **Xcode Instruments** - Performance profiling
- **Charles Proxy** - API debugging
- **TestFlight** - Beta distribution

### Useful Commands

```bash
# Run all tests
swift test --package-path CardShowProPackage

# Run specific test suite
swift test --filter "PricingTests"

# Run with coverage
swift test --enable-code-coverage

# Run UI tests only
xcodebuild test -scheme CardShowPro -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CardShowProUITests

# Generate coverage report
xcrun llvm-cov show .build/debug/CardShowProPackageTests.xctest/Contents/MacOS/CardShowProPackageTests
```

---

## Appendix: Example Test Files

### CardModelTests.swift

```swift
import Testing
@testable import CardShowProFeature

@Suite("Card Model Tests")
struct CardModelTests {

    @Test("Card initializes with required fields")
    func initialization() {
        let card = Card(
            id: "base1-4",
            name: "Charizard",
            setName: "Base Set",
            number: "4"
        )

        #expect(card.id == "base1-4")
        #expect(card.name == "Charizard")
        #expect(card.setName == "Base Set")
        #expect(card.number == "4")
    }

    @Test("Profit calculation", arguments: [
        (cost: 50.0, market: 100.0, expectedProfit: 50.0, expectedMargin: 0.5),
        (cost: 100.0, market: 50.0, expectedProfit: -50.0, expectedMargin: -0.5),
        (cost: 0.0, market: 100.0, expectedProfit: 100.0, expectedMargin: 1.0)
    ])
    func profitCalculation(cost: Double, market: Double, expectedProfit: Double, expectedMargin: Double) {
        var card = Card(id: "1", name: "Test", setName: "Set", number: "1")
        card.purchaseCost = cost
        card.marketValue = market

        #expect(card.profit == expectedProfit)
        #expect(card.profitMargin == expectedMargin)
    }
}
```

---

## Summary

This testing strategy provides:

✅ **Comprehensive Coverage** - Unit, integration, UI, performance, manual
✅ **Fast Feedback** - Tests run in <3 minutes
✅ **Automation** - CI/CD integration with GitHub Actions
✅ **Quality Gates** - Pre-release checklist ensures no regressions
✅ **Scalability** - Easy to add tests as features grow

**Next Steps:**
1. Set up testing infrastructure (Week 1)
2. Write first unit tests (Week 2-3)
3. Add integration tests (Week 4-5)
4. Implement CI/CD (Week 6)
5. Maintain 80%+ coverage throughout development

---

*For questions about testing strategy, contact the Engineering Team.*
