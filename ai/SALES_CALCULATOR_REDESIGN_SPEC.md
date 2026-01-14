# Sales Calculator Full Redesign Specification

**Document Version:** 1.0
**Created:** 2026-01-13
**Author:** Planner Agent
**Status:** Ready for Implementation

---

## Executive Summary

### The Problem

The current Sales Calculator has a **P0 UX flaw**: it uses a backwards flow (profit→price) when 80% of users need the forward flow (price→fees). The calculator is mathematically correct but conceptually inverted from how sellers think.

**Current Flow:**
```
User enters: Card Cost + Desired Profit
Calculator shows: List Price Needed
```

**What Users Actually Need:**
```
User enters: Sale Price
Calculator shows: Fee Breakdown + Net Profit
```

### The Solution

A **3-week phased redesign** that adds forward mode (price→fees) as the primary flow, preserves reverse mode (profit→price) as a secondary option, and adds platform comparison features.

### Success Metrics

- **Week 1:** Forward mode works perfectly (passes all tests)
- **Week 2:** Dual-mode toggle functional, mode persists
- **Week 3:** Platform comparison view complete, all edge cases handled

### Architecture Philosophy

- **No Breaking Changes:** Existing code remains functional throughout
- **Additive Design:** New features added alongside old ones
- **Test-Driven:** Each week delivers testable, verifiable features
- **SwiftUI Native:** Pure SwiftUI MV pattern, no ViewModels

---

## Week 1: Forward Mode (Price → Profit)

**Goal:** Add the primary user flow where sellers enter a sale price and see their profit.

### What Gets Built

#### 1. New Data Model: `ForwardCalculationResult`

**File:** `/Users/preem/Desktop/CardshowPro/CardShowProPackage/Sources/CardShowProFeature/Models/SalesCalculatorModel.swift`

```swift
struct ForwardCalculationResult: Sendable {
    let salePrice: Decimal
    let itemCost: Decimal
    let shippingCost: Decimal
    let platformFee: Decimal
    let platformFeePercentage: Double
    let paymentFee: Decimal
    let paymentFeePercentage: Double
    let totalFees: Decimal
    let netProfit: Decimal
    let profitMarginOnCost: Double  // Profit / Item Cost
    let profitMarginOnSale: Double  // Profit / Sale Price
    let isProfit: Bool              // true if netProfit > 0
}
```

**Why Two Margin Percentages?**
- Sellers think in terms of "I paid $50, sold for $75, made 50% profit" (margin on cost)
- But actual margin is "$25 profit on $75 sale = 33%" (margin on sale)
- Show both to avoid confusion

#### 2. New Calculation Method

**File:** `SalesCalculatorModel.swift`

```swift
@Observable
@MainActor
final class SalesCalculatorModel {
    // Existing properties remain unchanged

    // New forward mode property
    var salePrice: Decimal = 0.00

    // New calculation method
    func calculateProfit() -> ForwardCalculationResult {
        let fees = selectedPlatform.feeStructure

        // Step 1: Calculate platform fee (percentage of sale price)
        let platformFee = salePrice * Decimal(fees.platformFeePercentage)

        // Step 2: Calculate payment processing fee
        let paymentFee = (salePrice * Decimal(fees.paymentFeePercentage))
            + Decimal(fees.paymentFeeFixed)

        // Step 3: Total fees (including shipping cost)
        let totalFees = platformFee + paymentFee + shippingCost

        // Step 4: Net profit calculation
        // Formula: netProfit = salePrice - itemCost - shippingCost - platformFee - paymentFee
        let netProfit = salePrice - cardCost - shippingCost - platformFee - paymentFee

        // Step 5: Calculate margin percentages
        let profitMarginOnCost = cardCost > 0
            ? Double(truncating: ((netProfit / cardCost) * 100) as NSNumber)
            : 0.0

        let profitMarginOnSale = salePrice > 0
            ? Double(truncating: ((netProfit / salePrice) * 100) as NSNumber)
            : 0.0

        return ForwardCalculationResult(
            salePrice: salePrice,
            itemCost: cardCost,
            shippingCost: shippingCost,
            platformFee: platformFee,
            platformFeePercentage: fees.platformFeePercentage,
            paymentFee: paymentFee,
            paymentFeePercentage: fees.paymentFeePercentage,
            totalFees: totalFees,
            netProfit: netProfit,
            profitMarginOnCost: profitMarginOnCost,
            profitMarginOnSale: profitMarginOnSale,
            isProfit: netProfit > 0
        )
    }
}
```

#### 3. New View: `ForwardModeView`

**File:** `/Users/preem/Desktop/CardshowPro/CardShowProPackage/Sources/CardShowProFeature/Views/ForwardModeView.swift`

**Layout Structure:**
```
┌─────────────────────────────────────┐
│   [Platform Selector: eBay ▼]       │
├─────────────────────────────────────┤
│   SALE PRICE                         │
│   $ 100.00                           │  ← Large text field
├─────────────────────────────────────┤
│   COSTS                              │
│   Item Cost:      $ 50.00            │
│   Shipping:       $  3.00            │
├─────────────────────────────────────┤
│   FEE BREAKDOWN                      │
│   eBay Fee (12.95%):    $ 12.95      │
│   Payment (2.9%+$0.30): $  3.20      │
│   Shipping:             $  3.00      │
│   ──────────────────────────────     │
│   Total Fees:           $ 19.15      │
├─────────────────────────────────────┤
│   YOUR NET PROFIT                    │
│   $ 30.85                            │  ← Large, highlighted
│   60% margin on cost                 │
│   31% margin on sale                 │
└─────────────────────────────────────┘
```

**View Code:**
```swift
struct ForwardModeView: View {
    @Bindable var model: SalesCalculatorModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case salePrice
        case itemCost
        case shippingCost
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Platform Selector
                PlatformSelectorCard(model: model)

                // Sale Price Input (PRIMARY)
                salePriceSection

                // Costs Section
                costsSection

                // Fee Breakdown
                feeBreakdownCard

                // Net Profit Display
                netProfitCard
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
    }

    private var salePriceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("SALE PRICE")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("$")
                    .font(DesignSystem.Typography.displaySmall)
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)

                TextField("0.00", value: $model.salePrice, format: .number)
                    .font(DesignSystem.Typography.displaySmall.monospacedDigit())
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .salePrice)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .stroke(
                        focusedField == .salePrice
                            ? DesignSystem.Colors.electricBlue
                            : DesignSystem.Colors.thunderYellow.opacity(0.3),
                        lineWidth: 2
                    )
            )
        }
    }

    private var costsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            SectionHeader(title: "Costs")

            CurrencyTextField(
                title: "Item Cost",
                value: $model.cardCost,
                focusedField: $focusedField,
                field: .itemCost
            )

            CurrencyTextField(
                title: "Shipping Cost",
                value: $model.shippingCost,
                focusedField: $focusedField,
                field: .shippingCost
            )
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    private var feeBreakdownCard: some View {
        let result = model.calculateProfit()

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("FEE BREAKDOWN")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            FeeRow(
                label: "\(model.selectedPlatform.rawValue) Fee",
                percentage: result.platformFeePercentage,
                amount: result.platformFee
            )

            FeeRow(
                label: "Payment Processing",
                percentage: result.paymentFeePercentage,
                amount: result.paymentFee
            )

            FeeRow(
                label: "Shipping",
                percentage: nil,
                amount: result.shippingCost
            )

            Divider()
                .background(DesignSystem.Colors.textSecondary)

            HStack {
                Text("Total Fees")
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(result.totalFees.asCurrency)
                    .font(DesignSystem.Typography.heading3.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    private var netProfitCard: some View {
        let result = model.calculateProfit()

        return VStack(spacing: DesignSystem.Spacing.md) {
            Text("YOUR NET PROFIT")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(result.netProfit.asCurrency)
                .font(DesignSystem.Typography.displayMedium.monospacedDigit())
                .foregroundStyle(result.isProfit
                    ? DesignSystem.Colors.success
                    : DesignSystem.Colors.error)

            // Warning for negative profit
            if !result.isProfit && result.netProfit < 0 {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("YOU WILL LOSE MONEY")
                }
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.error)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }

            // Margin display
            VStack(spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text("Margin on Cost:")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(result.profitMarginOnCost.asPercentage)
                        .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }

                HStack {
                    Text("Margin on Sale:")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(result.profitMarginOnSale.asPercentage)
                        .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            result.isProfit
                ? DesignSystem.Colors.success.opacity(0.1)
                : DesignSystem.Colors.error.opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .stroke(
                    result.isProfit
                        ? DesignSystem.Colors.success
                        : DesignSystem.Colors.error,
                    lineWidth: 2
                )
        )
    }
}

struct FeeRow: View {
    let label: String
    let percentage: Double?
    let amount: Decimal

    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            if let percentage = percentage {
                Text("(\(percentage * 100, specifier: "%.2f")%)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            Text(amount.asCurrency)
                .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }
}
```

#### 4. Testing Strategy

**File:** `/Users/preem/Desktop/CardshowPro/CardShowProPackage/Tests/CardShowProFeatureTests/ForwardCalculationTests.swift`

```swift
import Testing
import Foundation
@testable import CardShowProFeature

@Suite("Forward Calculation Tests")
struct ForwardCalculationTests {

    @Test("Basic forward calculation - eBay")
    func basicForwardCalculationEbay() async throws {
        let model = await SalesCalculatorModel()
        await MainActor.run {
            model.salePrice = 100.00
            model.cardCost = 50.00
            model.shippingCost = 3.00
            model.selectedPlatform = .ebay
        }

        let result = await MainActor.run { model.calculateProfit() }

        // eBay: 12.95% platform + 2.9% + $0.30 payment
        // Platform fee: $100 * 12.95% = $12.95
        // Payment fee: ($100 * 2.9%) + $0.30 = $3.20
        // Total fees: $12.95 + $3.20 + $3.00 = $19.15
        // Net profit: $100 - $50 - $3 - $12.95 - $3.20 = $30.85

        #expect(result.salePrice == 100.00)
        #expect(result.platformFee == 12.95)
        #expect(abs(result.paymentFee - 3.20) < 0.01)
        #expect(abs(result.totalFees - 19.15) < 0.01)
        #expect(abs(result.netProfit - 30.85) < 0.01)
        #expect(result.isProfit == true)
    }

    @Test("Forward calculation with negative profit")
    func forwardCalculationNegativeProfit() async throws {
        let model = await SalesCalculatorModel()
        await MainActor.run {
            model.salePrice = 50.00
            model.cardCost = 100.00
            model.shippingCost = 5.00
            model.selectedPlatform = .ebay
        }

        let result = await MainActor.run { model.calculateProfit() }

        // Should show negative profit
        #expect(result.netProfit < 0)
        #expect(result.isProfit == false)
    }

    @Test("Forward calculation - TCGPlayer comparison")
    func forwardCalculationTCGPlayer() async throws {
        let model = await SalesCalculatorModel()
        await MainActor.run {
            model.salePrice = 200.00
            model.cardCost = 100.00
            model.shippingCost = 0.00
            model.selectedPlatform = .tcgplayer
        }

        let result = await MainActor.run { model.calculateProfit() }

        // TCGPlayer: 12.85% platform + 2.9% + $0.30 payment
        // Platform fee: $200 * 12.85% = $25.70
        // Payment fee: ($200 * 2.9%) + $0.30 = $6.10
        // Net profit: $200 - $100 - $25.70 - $6.10 = $68.20

        #expect(abs(result.platformFee - 25.70) < 0.01)
        #expect(abs(result.paymentFee - 6.10) < 0.01)
        #expect(abs(result.netProfit - 68.20) < 0.01)
    }

    @Test("Forward calculation - In-Person (no fees)")
    func forwardCalculationInPerson() async throws {
        let model = await SalesCalculatorModel()
        await MainActor.run {
            model.salePrice = 100.00
            model.cardCost = 50.00
            model.shippingCost = 0.00
            model.selectedPlatform = .inPerson
        }

        let result = await MainActor.run { model.calculateProfit() }

        // No fees for in-person
        #expect(result.platformFee == 0.00)
        #expect(result.paymentFee == 0.00)
        #expect(result.totalFees == 0.00)
        #expect(result.netProfit == 50.00)
    }

    @Test("Margin calculations")
    func marginCalculations() async throws {
        let model = await SalesCalculatorModel()
        await MainActor.run {
            model.salePrice = 150.00
            model.cardCost = 100.00
            model.shippingCost = 0.00
            model.selectedPlatform = .inPerson
        }

        let result = await MainActor.run { model.calculateProfit() }

        // Net profit: $50
        // Margin on cost: $50/$100 = 50%
        // Margin on sale: $50/$150 = 33.33%

        #expect(abs(result.profitMarginOnCost - 50.0) < 0.1)
        #expect(abs(result.profitMarginOnSale - 33.33) < 0.1)
    }
}
```

### Week 1 Deliverables

- [ ] `ForwardCalculationResult` struct added to `SalesCalculatorModel.swift`
- [ ] `calculateProfit()` method implemented and tested
- [ ] `ForwardModeView.swift` created with full UI
- [ ] `ForwardCalculationTests.swift` passing 100%
- [ ] Manual testing shows correct calculations for all platforms
- [ ] Negative profit warnings display correctly

### Week 1 Risks

| Risk | Mitigation |
|------|-----------|
| Breaking existing reverse mode | Keep all existing code intact, only add new functionality |
| Decimal precision errors | Use Decimal throughout, test with sub-penny values |
| UI layout issues on small screens | Test on iPhone SE simulator |
| Confusion about two margin types | Add help text explaining difference |

### Week 1 Validation

**Pass Criteria:**
1. User can enter $100 sale price
2. User sees correct eBay fees ($12.95 + $3.20)
3. User sees correct net profit
4. Negative profit shows red warning
5. All 5 unit tests pass
6. No crashes or computation errors

---

## Week 2: Dual-Mode Toggle & Reverse Mode Refactor

**Goal:** Give users the ability to toggle between forward mode (price→fees) and reverse mode (profit→price).

### What Gets Built

#### 1. Calculation Mode Enum

**File:** `SalesCalculatorModel.swift`

```swift
enum CalculationMode: String, Codable, Sendable, CaseIterable {
    case forward = "What are my fees?"  // Price → Profit (NEW DEFAULT)
    case reverse = "What price do I need?"  // Profit → Price (OLD BEHAVIOR)

    var icon: String {
        switch self {
        case .forward: return "arrow.right.circle.fill"
        case .reverse: return "arrow.left.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .forward:
            return "I have a sale price, show me my profit"
        case .reverse:
            return "I want a specific profit, show me what to charge"
        }
    }
}
```

#### 2. Mode Persistence with AppStorage

**File:** `SalesCalculatorModel.swift`

```swift
@Observable
@MainActor
final class SalesCalculatorModel {
    // Existing properties...

    // NEW: Mode selection with persistence
    var calculationMode: CalculationMode {
        get {
            access(keyPath: \.calculationMode)
            if let stored = UserDefaults.standard.string(forKey: "calculationMode"),
               let mode = CalculationMode(rawValue: stored) {
                return mode
            }
            return .forward  // Default to forward mode
        }
        set {
            withMutation(keyPath: \.calculationMode) {
                UserDefaults.standard.set(newValue.rawValue, forKey: "calculationMode")
            }
        }
    }

    private var _calculationMode: CalculationMode = .forward
}
```

#### 3. Mode Selector Component

**File:** `/Users/preem/Desktop/CardshowPro/CardShowProPackage/Sources/CardShowProFeature/Views/CalculationModeSelector.swift`

```swift
import SwiftUI

struct CalculationModeSelector: View {
    @Bindable var model: SalesCalculatorModel

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("WHAT DO YOU WANT TO CALCULATE?")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                ModeCard(
                    mode: .forward,
                    isSelected: model.calculationMode == .forward,
                    action: { model.calculationMode = .forward }
                )

                ModeCard(
                    mode: .reverse,
                    isSelected: model.calculationMode == .reverse,
                    action: { model.calculationMode = .reverse }
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }
}

struct ModeCard: View {
    let mode: CalculationMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: mode.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(
                        isSelected
                            ? DesignSystem.Colors.thunderYellow
                            : DesignSystem.Colors.textSecondary
                    )

                Text(mode.rawValue)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(mode.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(
                isSelected
                    ? DesignSystem.Colors.backgroundSecondary
                    : DesignSystem.Colors.backgroundTertiary
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        isSelected
                            ? DesignSystem.Colors.thunderYellow
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
```

#### 4. Refactored Main View

**File:** `SalesCalculatorView.swift`

```swift
struct SalesCalculatorView: View {
    @State private var model = SalesCalculatorModel()
    @FocusState private var focusedField: Field?
    @State private var showResetAlert = false
    @State private var showCopyToast = false

    enum Field: Hashable {
        case cardCost
        case shippingCost
        case profitAmount
        case salePrice
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Mode Selector at the top
                CalculationModeSelector(model: model)

                // Show appropriate view based on mode
                switch model.calculationMode {
                case .forward:
                    ForwardModeView(model: model, focusedField: $focusedField)

                case .reverse:
                    ReverseModeView(model: model, focusedField: $focusedField)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle("Sales Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    showResetAlert = true
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .foregroundStyle(DesignSystem.Colors.thunderYellow)
            }
        }
        .alert("Reset Calculator?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                model.reset()
                focusedField = nil
            }
        } message: {
            Text("This will clear all inputs and reset to default values.")
        }
    }
}
```

#### 5. Reverse Mode View (Refactored from Existing)

**File:** `/Users/preem/Desktop/CardshowPro/CardShowProPackage/Sources/CardShowProFeature/Views/ReverseModeView.swift`

This is essentially the current `SalesCalculatorView` content moved into its own component:

```swift
import SwiftUI

/// Reverse calculation mode: Input desired profit, calculate required sale price
struct ReverseModeView: View {
    @Bindable var model: SalesCalculatorModel
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?
    @State private var showCopyToast = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Platform Selector
            PlatformSelectorCard(model: model)

            // Input Section (Costs)
            costsSection

            // Profit Mode Section
            ProfitModeSection(model: model, focusedField: $focusedField)

            // Results Card (List Price)
            ResultsCard(model: model, showCopyToast: $showCopyToast)

            // Fee Breakdown
            FeeBreakdownSection(result: model.calculationResult)
        }
        .overlay(alignment: .top) {
            if showCopyToast {
                ToastView(message: "List price copied!")
                    .padding(.top, DesignSystem.Spacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showCopyToast = false
                            }
                        }
                    }
            }
        }
    }

    private var costsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            SectionHeader(title: "Costs")

            CurrencyTextField(
                title: "Card Cost",
                value: $model.cardCost,
                focusedField: $focusedField,
                field: .cardCost
            )

            CurrencyTextField(
                title: "Shipping Cost",
                value: $model.shippingCost,
                focusedField: $focusedField,
                field: .shippingCost
            )
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }
}
```

#### 6. Testing Strategy

**File:** `Tests/CardShowProFeatureTests/CalculationModeTests.swift`

```swift
import Testing
import Foundation
@testable import CardShowProFeature

@Suite("Calculation Mode Tests")
struct CalculationModeTests {

    @Test("Mode defaults to forward")
    func modeDefaultsToForward() async throws {
        // Clear any stored preference
        await MainActor.run {
            UserDefaults.standard.removeObject(forKey: "calculationMode")
        }

        let model = await SalesCalculatorModel()
        let mode = await MainActor.run { model.calculationMode }

        #expect(mode == .forward)
    }

    @Test("Mode persists across instances")
    func modePersistsAcrossInstances() async throws {
        // Set to reverse mode
        let model1 = await SalesCalculatorModel()
        await MainActor.run {
            model1.calculationMode = .reverse
        }

        // Create new instance
        let model2 = await SalesCalculatorModel()
        let mode = await MainActor.run { model2.calculationMode }

        #expect(mode == .reverse)

        // Cleanup
        await MainActor.run {
            UserDefaults.standard.removeObject(forKey: "calculationMode")
        }
    }

    @Test("Switching modes doesn't clear inputs")
    func switchingModesPreservesInputs() async throws {
        let model = await SalesCalculatorModel()

        // Enter data in forward mode
        await MainActor.run {
            model.calculationMode = .forward
            model.salePrice = 100.00
            model.cardCost = 50.00
            model.shippingCost = 3.00
        }

        // Switch to reverse mode
        await MainActor.run {
            model.calculationMode = .reverse
        }

        // Check data is preserved
        let (cost, shipping) = await MainActor.run {
            (model.cardCost, model.shippingCost)
        }

        #expect(cost == 50.00)
        #expect(shipping == 3.00)
    }
}
```

### Week 2 Deliverables

- [ ] `CalculationMode` enum added to `SalesCalculatorModel.swift`
- [ ] Mode persistence with UserDefaults implemented
- [ ] `CalculationModeSelector.swift` component created
- [ ] `ReverseModeView.swift` extracted from existing code
- [ ] `SalesCalculatorView.swift` refactored to switch between modes
- [ ] Mode selection persists across app launches
- [ ] All mode switching tests pass

### Week 2 Risks

| Risk | Mitigation |
|------|-----------|
| UserDefaults sync issues | Test on device, not just simulator |
| Mode switching loses user input | Explicitly test data preservation |
| Confusing mode labels | User testing with 3-5 real sellers |
| Breaking existing UI | Keep all existing components intact |

### Week 2 Validation

**Pass Criteria:**
1. Mode selector appears at top of screen
2. Tapping "What are my fees?" shows forward mode
3. Tapping "What price do I need?" shows reverse mode
4. Selected mode persists after closing and reopening app
5. Switching modes doesn't clear entered values
6. All unit tests pass

---

## Week 3: Platform Comparison & Polish

**Goal:** Add side-by-side platform comparison, custom fee editing, and comprehensive edge case handling.

### What Gets Built

#### 1. Platform Comparison View

**File:** `/Users/preem/Desktop/CardshowPro/CardShowProPackage/Sources/CardShowProFeature/Views/PlatformComparisonView.swift`

**Layout:**
```
┌─────────────────────────────────────────────┐
│  COMPARE PLATFORMS                          │
│                                             │
│  Sale Price: $100.00                        │
│  Item Cost:  $ 50.00                        │
│  Shipping:   $  3.00                        │
├─────────────────────────────────────────────┤
│  Platform       Fees    Net Profit  Margin  │
│  ───────────────────────────────────────    │
│  ✓ In-Person    $3.00   $47.00 ⭐   94%    │
│    Facebook     $8.40   $41.60      83%    │
│    StockX       $15.50  $34.50      69%    │
│    eBay         $19.15  $30.85      62%    │
│    TCGPlayer    $19.22  $30.78      62%    │
└─────────────────────────────────────────────┘
```

```swift
import SwiftUI

struct PlatformComparisonView: View {
    let salePrice: Decimal
    let itemCost: Decimal
    let shippingCost: Decimal

    @State private var comparisons: [PlatformComparison] = []

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Input Summary
                inputSummaryCard

                // Comparison Table
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("PLATFORM COMPARISON")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Header Row
                    comparisonHeader

                    // Platform Rows (sorted by net profit, descending)
                    ForEach(comparisons.sorted { $0.netProfit > $1.netProfit }) { comparison in
                        PlatformComparisonRow(
                            comparison: comparison,
                            isBestDeal: comparison.netProfit == comparisons.max(by: { $0.netProfit < $1.netProfit })?.netProfit
                        )
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle("Platform Comparison")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            calculateComparisons()
        }
    }

    private var inputSummaryCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("INPUTS")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            summaryRow(label: "Sale Price:", value: salePrice.asCurrency)
            summaryRow(label: "Item Cost:", value: itemCost.asCurrency)
            summaryRow(label: "Shipping:", value: shippingCost.asCurrency)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }

    private var comparisonHeader: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text("Platform")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Fees")
                .frame(width: 70, alignment: .trailing)

            Text("Profit")
                .frame(width: 70, alignment: .trailing)

            Text("Margin")
                .frame(width: 60, alignment: .trailing)
        }
        .font(DesignSystem.Typography.captionBold)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
        .padding(.horizontal, DesignSystem.Spacing.sm)
    }

    private func calculateComparisons() {
        comparisons = SellingPlatform.allCases.map { platform in
            let fees = platform.feeStructure
            let platformFee = salePrice * Decimal(fees.platformFeePercentage)
            let paymentFee = (salePrice * Decimal(fees.paymentFeePercentage)) + Decimal(fees.paymentFeeFixed)
            let totalFees = platformFee + paymentFee + shippingCost
            let netProfit = salePrice - itemCost - shippingCost - platformFee - paymentFee
            let marginPercent = itemCost > 0
                ? Double(truncating: ((netProfit / itemCost) * 100) as NSNumber)
                : 0.0

            return PlatformComparison(
                platform: platform,
                totalFees: totalFees,
                netProfit: netProfit,
                marginPercent: marginPercent
            )
        }
    }
}

struct PlatformComparison: Identifiable {
    let id = UUID()
    let platform: SellingPlatform
    let totalFees: Decimal
    let netProfit: Decimal
    let marginPercent: Double
}

struct PlatformComparisonRow: View {
    let comparison: PlatformComparison
    let isBestDeal: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Platform name with icon
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isBestDeal {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignSystem.Colors.thunderYellow)
                }

                Text(comparison.platform.rawValue)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Fees
            Text(comparison.totalFees.asCurrency)
                .font(DesignSystem.Typography.body.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(width: 70, alignment: .trailing)

            // Net Profit
            Text(comparison.netProfit.asCurrency)
                .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(
                    comparison.netProfit > 0
                        ? DesignSystem.Colors.success
                        : DesignSystem.Colors.error
                )
                .frame(width: 70, alignment: .trailing)

            // Margin
            Text(comparison.marginPercent.asPercentage)
                .font(DesignSystem.Typography.body.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            isBestDeal
                ? DesignSystem.Colors.thunderYellow.opacity(0.1)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
    }
}
```

#### 2. Compare Button in Forward Mode

**File:** `ForwardModeView.swift` (modification)

Add this button below the net profit card:

```swift
Button {
    // Navigate to comparison view
} label: {
    HStack {
        Image(systemName: "chart.bar.fill")
        Text("Compare All Platforms")
    }
    .font(DesignSystem.Typography.labelLarge)
    .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
    .frame(maxWidth: .infinity)
    .padding(DesignSystem.Spacing.md)
    .background(DesignSystem.Colors.electricBlue)
    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
}
.buttonStyle(.plain)
```

#### 3. Custom Fee Editor

**File:** `/Users/preem/Desktop/CardshowPro/CardShowProPackage/Sources/CardShowProFeature/Views/CustomFeeEditorSheet.swift`

```swift
import SwiftUI

struct CustomFeeEditorSheet: View {
    @Bindable var model: SalesCalculatorModel
    @Environment(\.dismiss) private var dismiss

    @State private var platformFeePercent: Double = 10.0
    @State private var paymentFeePercent: Double = 2.9
    @State private var fixedFee: Double = 0.30
    @State private var presetName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Fee Structure") {
                    HStack {
                        Text("Platform Fee")
                        Spacer()
                        TextField("0.0", value: $platformFeePercent, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                    }

                    HStack {
                        Text("Payment Processing")
                        Spacer()
                        TextField("0.0", value: $paymentFeePercent, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                    }

                    HStack {
                        Text("Fixed Fee")
                        Spacer()
                        Text("$")
                        TextField("0.00", value: $fixedFee, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }

                Section("Preview") {
                    HStack {
                        Text("On $100 sale:")
                        Spacer()
                        Text(previewTotalFees.asCurrency)
                            .foregroundStyle(DesignSystem.Colors.thunderYellow)
                    }
                }

                Section("Save as Preset (Optional)") {
                    TextField("Preset name", text: $presetName)
                }
            }
            .navigationTitle("Custom Fees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyCustomFees()
                        dismiss()
                    }
                }
            }
        }
    }

    private var previewTotalFees: Decimal {
        let salePrice = Decimal(100)
        let platformFee = salePrice * Decimal(platformFeePercent / 100)
        let paymentFee = (salePrice * Decimal(paymentFeePercent / 100)) + Decimal(fixedFee)
        return platformFee + paymentFee
    }

    private func applyCustomFees() {
        // TODO: Apply custom fees to model
        // This requires modifying SellingPlatform to support dynamic custom fees
    }
}
```

#### 4. Edge Case Handling

Add validation and warnings throughout:

**File:** `ForwardModeView.swift` (additions)

```swift
// Add warning for micro-profits
if result.netProfit > 0 && result.netProfit < 2.00 {
    HStack(spacing: DesignSystem.Spacing.xs) {
        Image(systemName: "exclamationmark.circle.fill")
        Text("Very low profit - consider if this sale is worth your time")
    }
    .font(DesignSystem.Typography.caption)
    .foregroundStyle(DesignSystem.Colors.warning)
    .padding(DesignSystem.Spacing.sm)
    .background(DesignSystem.Colors.warning.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
}

// Add warning for zero values
if model.salePrice == 0 || model.cardCost == 0 {
    Text("Enter sale price and item cost to see calculations")
        .font(DesignSystem.Typography.body)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
        .multilineTextAlignment(.center)
        .padding(DesignSystem.Spacing.md)
}
```

#### 5. Comprehensive Testing

**File:** `Tests/CardShowProFeatureTests/SalesCalculatorEdgeCaseTests.swift`

```swift
import Testing
import Foundation
@testable import CardShowProFeature

@Suite("Sales Calculator Edge Cases")
struct SalesCalculatorEdgeCaseTests {

    @Test("Zero sale price returns zero profit")
    func zeroSalePrice() async throws {
        let model = await SalesCalculatorModel()
        await MainActor.run {
            model.salePrice = 0.00
            model.cardCost = 50.00
            model.selectedPlatform = .ebay
        }

        let result = await MainActor.run { model.calculateProfit() }

        #expect(result.netProfit <= 0)
    }

    @Test("Micro profit detection")
    func microProfit() async throws {
        let model = await SalesCalculatorModel()
        await MainActor.run {
            model.salePrice = 5.00
            model.cardCost = 0.50
            model.shippingCost = 3.00
            model.selectedPlatform = .ebay
        }

        let result = await MainActor.run { model.calculateProfit() }

        // Profit should be positive but tiny
        #expect(result.netProfit > 0)
        #expect(result.netProfit < 2.00)
    }

    @Test("High value card calculation")
    func highValueCard() async throws {
        let model = await SalesCalculatorModel()
        await MainActor.run {
            model.salePrice = 10000.00
            model.cardCost = 5000.00
            model.shippingCost = 0.00
            model.selectedPlatform = .ebay
        }

        let result = await MainActor.run { model.calculateProfit() }

        // Should handle large numbers without overflow
        #expect(result.platformFee > 1000)
        #expect(result.netProfit > 3000)
    }

    @Test("Platform comparison returns all platforms")
    func platformComparisonComplete() async throws {
        let salePrice: Decimal = 100.00
        let itemCost: Decimal = 50.00
        let shippingCost: Decimal = 3.00

        let comparisons = SellingPlatform.allCases.map { platform in
            let fees = platform.feeStructure
            let platformFee = salePrice * Decimal(fees.platformFeePercentage)
            let paymentFee = (salePrice * Decimal(fees.paymentFeePercentage)) + Decimal(fees.paymentFeeFixed)
            let netProfit = salePrice - itemCost - shippingCost - platformFee - paymentFee
            return netProfit
        }

        // Should have results for all 6 platforms
        #expect(comparisons.count == 6)

        // In-Person should be most profitable (no fees)
        #expect(comparisons[4] == 47.00) // In-Person index
    }
}
```

### Week 3 Deliverables

- [ ] `PlatformComparisonView.swift` created and functional
- [ ] "Compare All Platforms" button added to forward mode
- [ ] `CustomFeeEditorSheet.swift` created (basic version)
- [ ] Edge case warnings added (negative profit, micro profit, zero values)
- [ ] All edge case tests pass
- [ ] Manual testing confirms platform comparison accuracy
- [ ] Performance testing with rapid platform switching

### Week 3 Risks

| Risk | Mitigation |
|------|-----------|
| Platform comparison performance | Cache calculations, limit to visible rows |
| Custom fee editing complexity | Ship basic version, iterate in v1.1 |
| Too many warnings annoy users | Only show critical warnings |
| Navigation complexity | Use sheets instead of navigation stack |

### Week 3 Validation

**Pass Criteria:**
1. "Compare Platforms" button works from forward mode
2. Comparison view shows all 6 platforms ranked by profit
3. Best platform highlighted with star icon
4. Negative profit shows red warning banner
5. Micro-profit (<$2) shows warning message
6. All edge case tests pass
7. No performance issues with rapid calculations

---

## Migration Strategy

### How to Avoid Breaking Existing Code

**Phase 1: Week 1 (Additive Only)**
- Add new files, don't modify existing ones
- `ForwardModeView.swift` is completely new
- `SalesCalculatorModel.swift` gets new methods, old ones unchanged
- Existing `SalesCalculatorView.swift` continues working

**Phase 2: Week 2 (Refactor with Fallback)**
- Extract existing code into `ReverseModeView.swift`
- Modify `SalesCalculatorView.swift` to switch between modes
- If anything breaks, mode switch can default to reverse mode
- All existing tests continue passing

**Phase 3: Week 3 (Polish)**
- Add comparison view (new file, no modifications to core)
- Add warnings (purely additive UI elements)
- Custom fees (optional feature, doesn't affect calculations)

### Rollback Plan

If any week fails testing:
1. **Week 1 Rollback:** Remove `ForwardModeView.swift`, keep existing view
2. **Week 2 Rollback:** Revert `SalesCalculatorView.swift`, remove mode selector
3. **Week 3 Rollback:** Remove comparison view link, keep core functionality

---

## File Change Manifest

### New Files Created

```
Week 1:
- CardShowProPackage/Sources/CardShowProFeature/Views/ForwardModeView.swift
- CardShowProPackage/Tests/CardShowProFeatureTests/ForwardCalculationTests.swift

Week 2:
- CardShowProPackage/Sources/CardShowProFeature/Views/CalculationModeSelector.swift
- CardShowProPackage/Sources/CardShowProFeature/Views/ReverseModeView.swift
- CardShowProPackage/Tests/CardShowProFeatureTests/CalculationModeTests.swift

Week 3:
- CardShowProPackage/Sources/CardShowProFeature/Views/PlatformComparisonView.swift
- CardShowProPackage/Sources/CardShowProFeature/Views/CustomFeeEditorSheet.swift
- CardShowProPackage/Tests/CardShowProFeatureTests/SalesCalculatorEdgeCaseTests.swift
```

### Files Modified

```
Week 1:
- CardShowProPackage/Sources/CardShowProFeature/Models/SalesCalculatorModel.swift
  + Add salePrice property
  + Add ForwardCalculationResult struct
  + Add calculateProfit() method

Week 2:
- CardShowProPackage/Sources/CardShowProFeature/Models/SalesCalculatorModel.swift
  + Add CalculationMode enum
  + Add calculationMode property with persistence

- CardShowProPackage/Sources/CardShowProFeature/Views/SalesCalculatorView.swift
  + Add CalculationModeSelector at top
  + Add switch statement for mode-based view rendering
  + Add focusedField cases for forward mode

Week 3:
- CardShowProPackage/Sources/CardShowProFeature/Views/ForwardModeView.swift
  + Add "Compare All Platforms" button
  + Add edge case warnings
```

---

## Testing Strategy

### Unit Tests (Swift Testing Framework)

**Coverage Goals:**
- 100% coverage of calculation methods
- 100% coverage of mode switching logic
- 100% coverage of edge cases

**Test Files:**
1. `ForwardCalculationTests.swift` - 5 tests for forward mode math
2. `CalculationModeTests.swift` - 3 tests for mode persistence
3. `SalesCalculatorEdgeCaseTests.swift` - 4 tests for edge cases

**Total:** 12 unit tests, all must pass before deployment

### Manual Testing Checklist

**Week 1:**
- [ ] Enter $100 sale price, see correct fees for all 6 platforms
- [ ] Enter $0 sale price, see zero profit message
- [ ] Enter negative cost, see error handling
- [ ] Test on iPhone SE (small screen)
- [ ] Test on iPad (large screen)
- [ ] Test with VoiceOver enabled

**Week 2:**
- [ ] Toggle between modes, verify both work
- [ ] Close app, reopen, verify mode persists
- [ ] Switch modes with data entered, verify no loss
- [ ] Test on device (not just simulator) for UserDefaults

**Week 3:**
- [ ] Tap "Compare Platforms", see sorted list
- [ ] Verify In-Person is always most profitable
- [ ] Test with micro-profit scenario ($0.50)
- [ ] Test with high-value card ($10,000)
- [ ] Verify negative profit warning appears

### Performance Testing

**Targets:**
- Forward calculation: < 5ms
- Mode switch: < 100ms
- Platform comparison: < 50ms

**Test Method:**
```swift
func measureForwardCalculation() {
    measure {
        _ = model.calculateProfit()
    }
}
```

---

## Success Criteria

### Week 1 Success Criteria

**Must Have:**
- [x] Forward mode view displays correctly
- [x] Calculation formula is mathematically correct
- [x] All 5 unit tests pass
- [x] Manual testing shows accurate results for all platforms
- [x] Negative profit warning displays

**Nice to Have:**
- [ ] Zero-value input shows helpful message
- [ ] Copy button works for net profit

### Week 2 Success Criteria

**Must Have:**
- [x] Mode selector displays at top of view
- [x] Both modes functional and accessible
- [x] Mode preference persists across app launches
- [x] All 3 mode switching tests pass
- [x] No loss of user data when switching modes

**Nice to Have:**
- [ ] Smooth animation between mode transitions
- [ ] Mode descriptions are clear and helpful

### Week 3 Success Criteria

**Must Have:**
- [x] Platform comparison view works correctly
- [x] Comparison results are accurate and sorted
- [x] All 4 edge case tests pass
- [x] Negative profit warning implemented
- [x] Micro-profit warning implemented

**Nice to Have:**
- [ ] Custom fee editor functional (basic version)
- [ ] Platform comparison exportable as text
- [ ] "Worth it?" hourly rate indicator

---

## Post-Implementation Checklist

After all 3 weeks are complete:

### Code Quality
- [ ] All unit tests passing (12/12)
- [ ] No Swift compiler warnings
- [ ] No force unwraps (!)
- [ ] All Sendable requirements met
- [ ] Code follows Swift 6.1 strict concurrency

### Documentation
- [ ] All public methods have doc comments
- [ ] README updated with new features
- [ ] FEATURES.json updated with F006 = true
- [ ] PROGRESS.md updated with completion date

### Testing
- [ ] Manual testing complete on simulator
- [ ] Manual testing complete on physical device
- [ ] Accessibility testing with VoiceOver
- [ ] Performance benchmarks met

### User Experience
- [ ] Forward mode is default (80% use case)
- [ ] Mode switching is intuitive
- [ ] Negative profit warnings are clear
- [ ] Platform comparison is useful

---

## Known Limitations & Future Work

### V1.0 Limitations

1. **Custom Fees:** Basic implementation, not fully editable in UI
2. **Bulk Calculations:** No quantity field for multiple cards
3. **Export:** No PDF or CSV export of calculations
4. **Presets:** No saved platform presets
5. **History:** No calculation history tracking

### V1.1 Roadmap

**F006B: Sales Calculator Platform Presets**
- Save custom fee structures with names
- Quick-select favorite platforms
- Import/export presets

**F006C: Sales Calculator Bulk Mode**
- Quantity field for multiple identical cards
- Bulk discount calculator
- Total profit summary

**F006D: Sales Calculator History**
- Save past calculations
- Compare historical results
- Export calculations to CSV

---

## Appendix: Formula Reference

### Forward Mode Formula

```
Given:
- Sale Price (SP)
- Item Cost (IC)
- Shipping Cost (SC)
- Platform Fee % (PF%)
- Payment Fee % (PMT%)
- Payment Fixed Fee (PMTF)

Calculate:
1. Platform Fee = SP × PF%
2. Payment Fee = (SP × PMT%) + PMTF
3. Total Fees = Platform Fee + Payment Fee + SC
4. Net Profit = SP - IC - SC - Platform Fee - Payment Fee
5. Margin on Cost = (Net Profit / IC) × 100
6. Margin on Sale = (Net Profit / SP) × 100
```

### Reverse Mode Formula (Existing)

```
Given:
- Item Cost (IC)
- Shipping Cost (SC)
- Desired Profit (DP)
- Platform Fee % (PF%)
- Payment Fee % (PMT%)
- Payment Fixed Fee (PMTF)

Calculate:
1. Total Fee % = PF% + PMT%
2. Numerator = IC + SC + DP + PMTF
3. Denominator = 1 - Total Fee %
4. Sale Price = Numerator / Denominator
5. [Then calculate actual fees using forward formula]
```

### Example Calculations

**Forward Mode Example:**
```
Sale Price: $100.00
Item Cost: $50.00
Shipping: $3.00
Platform: eBay (12.95% + 2.9% + $0.30)

Platform Fee = $100 × 0.1295 = $12.95
Payment Fee = ($100 × 0.029) + $0.30 = $3.20
Total Fees = $12.95 + $3.20 + $3.00 = $19.15
Net Profit = $100 - $50 - $3 - $12.95 - $3.20 = $30.85
Margin on Cost = ($30.85 / $50) × 100 = 61.7%
Margin on Sale = ($30.85 / $100) × 100 = 30.85%
```

**Reverse Mode Example:**
```
Item Cost: $50.00
Shipping: $3.00
Desired Profit: 20% = $10.00
Platform: eBay (12.95% + 2.9% + $0.30)

Total Fee % = 0.1295 + 0.029 = 0.1585
Numerator = $50 + $3 + $10 + $0.30 = $63.30
Denominator = 1 - 0.1585 = 0.8415
Sale Price = $63.30 / 0.8415 = $75.22

[Verify with forward formula]
Platform Fee = $75.22 × 0.1295 = $9.74
Payment Fee = ($75.22 × 0.029) + $0.30 = $2.48
Net Profit = $75.22 - $50 - $3 - $9.74 - $2.48 = $10.00 ✓
```

---

**End of Specification Document**

*This specification is ready for implementation. Each week is self-contained, testable, and delivers incremental value. The design maintains backward compatibility while fixing the P0 UX issue identified in the verification report.*
