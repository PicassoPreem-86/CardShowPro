# Sales Calculator Redesign - Implementation Summary

**Created:** 2026-01-13
**Status:** Specification Complete, Week 1 Model Changes Already Implemented

---

## What Was Created

### Comprehensive Specification Document

**Location:** `/Users/preem/Desktop/CardshowPro/ai/SALES_CALCULATOR_REDESIGN_SPEC.md`

This 600+ line specification provides:
- Week-by-week implementation breakdown (3 weeks total)
- Detailed code examples for every component
- Complete testing strategy with 12 unit tests
- Migration plan to avoid breaking existing code
- Success criteria for each week
- Formula reference and calculation examples

---

## The Problem (P0 Issue)

**Current UX Flow:** profit → price (backwards)
```
User enters: "I want 20% profit on this $50 card"
Calculator shows: "Charge $71.65"
```

**What 80% of Users Need:** price → profit (forward)
```
User enters: "I'm selling this for $100"
Calculator shows: "You'll make $30.85 profit after fees"
```

---

## The Solution (3-Week Plan)

### Week 1: Forward Mode (Price → Profit)
**Status:** MODEL CHANGES COMPLETE ✅

**What's Done:**
- ✅ `ForwardCalculationResult` struct implemented
- ✅ `calculateProfit()` method implemented
- ✅ `CalculatorMode` enum added
- ✅ Forward mode inputs added to model (salePrice, itemCost, etc.)

**What's Next:**
- Create `ForwardModeView.swift` with UI
- Write unit tests in `ForwardCalculationTests.swift`
- Test all 6 platforms manually

**Deliverable:** Users can enter a sale price and see their net profit.

---

### Week 2: Dual-Mode Toggle (Both Flows Available)
**Status:** CORE STRUCTURE IMPLEMENTED ✅ (Needs Components)

**What's Done:**
- ✅ `SalesCalculatorView.swift` refactored with mode switching
- ✅ `ModeToggle` component reference added
- ✅ Mode-based view rendering (switch statement)
- ✅ Field enum expanded for both modes

**What's Next:**
- Create `ModeToggle.swift` component
- Create `ForwardModeView.swift` component
- Create `ReverseModeView.swift` component
- Add mode persistence with UserDefaults
- Write unit tests

**Deliverable:** Users can toggle between "What are my fees?" and "What price do I need?"

---

### Week 3: Platform Comparison & Polish
**Status:** NOT STARTED

**What to Build:**
- `PlatformComparisonView.swift` - Side-by-side platform comparison
- "Compare All Platforms" button in forward mode
- Edge case warnings (negative profit, micro-profit)
- `CustomFeeEditorSheet.swift` (optional, basic version)

**Deliverable:** Users can compare all platforms at once and see which is most profitable.

---

## Key Design Decisions

### 1. Forward Mode is Default
**Why:** 80% of users want to calculate fees for a known sale price, not optimize pricing for desired profit.

### 2. No Breaking Changes
**How:** All existing code stays functional. New features are additive. Each week builds on the previous.

### 3. Two Margin Percentages
**Why:** Avoid confusion between:
- "Margin on Cost" = Profit / Item Cost (how sellers think)
- "Margin on Sale" = Profit / Sale Price (actual margin)

### 4. Pure SwiftUI MV Pattern
**No ViewModels:** Use `@Observable` model with `@State` in views
**Concurrency:** All UI on `@MainActor`, proper Sendable conformance

---

## File Changes Overview

### New Files (7 total)
```
Week 1:
- CardShowProPackage/Sources/.../Views/ForwardModeView.swift
- CardShowProPackage/Tests/.../ForwardCalculationTests.swift

Week 2:
- CardShowProPackage/Sources/.../Views/CalculationModeSelector.swift
- CardShowProPackage/Sources/.../Views/ReverseModeView.swift
- CardShowProPackage/Tests/.../CalculationModeTests.swift

Week 3:
- CardShowProPackage/Sources/.../Views/PlatformComparisonView.swift
- CardShowProPackage/Sources/.../Views/CustomFeeEditorSheet.swift
- CardShowProPackage/Tests/.../SalesCalculatorEdgeCaseTests.swift
```

### Modified Files (2 total)
```
Week 1:
- SalesCalculatorModel.swift (ALREADY DONE ✅)

Week 2:
- SalesCalculatorView.swift (add mode selector, switch between views)

Week 3:
- ForwardModeView.swift (add comparison button, edge case warnings)
```

---

## Testing Strategy

### Unit Tests (12 tests across 3 files)

**ForwardCalculationTests.swift (5 tests):**
1. Basic forward calculation - eBay
2. Forward calculation with negative profit
3. Forward calculation - TCGPlayer comparison
4. Forward calculation - In-Person (no fees)
5. Margin calculations

**CalculationModeTests.swift (3 tests):**
1. Mode defaults to forward
2. Mode persists across instances
3. Switching modes doesn't clear inputs

**SalesCalculatorEdgeCaseTests.swift (4 tests):**
1. Zero sale price returns zero profit
2. Micro profit detection
3. High value card calculation
4. Platform comparison returns all platforms

### Manual Testing
- Test on iPhone 16 Simulator (primary)
- Test on iPhone SE (small screen)
- Test on iPad (large screen)
- Test with VoiceOver (accessibility)
- Test on physical device (UserDefaults persistence)

---

## Success Criteria

### Week 1 Complete When:
- [x] Model changes implemented (DONE)
- [ ] ForwardModeView displays correctly
- [ ] All 5 unit tests pass
- [ ] Manual testing shows accurate calculations
- [ ] Negative profit warning displays

### Week 2 Complete When:
- [ ] Mode selector appears at top of screen
- [ ] Both forward and reverse modes work
- [ ] Mode preference persists across app launches
- [ ] All 3 mode tests pass
- [ ] No data loss when switching modes

### Week 3 Complete When:
- [ ] Platform comparison view functional
- [ ] Comparison results accurate and sorted
- [ ] All 4 edge case tests pass
- [ ] Warning banners appear for negative/micro profit
- [ ] No performance issues

---

## What to Update After Completion

### Code
- [ ] All 12 unit tests passing
- [ ] No compiler warnings
- [ ] No force unwraps
- [ ] Sendable conformance verified

### Documentation
- [ ] FEATURES.json: Set F006 "passes": true
- [ ] PROGRESS.md: Add completion entry
- [ ] README.md: Document new forward mode
- [ ] This spec: Mark all weeks complete

### Testing
- [ ] Manual testing checklist 100% complete
- [ ] Accessibility testing passed
- [ ] Performance benchmarks met
- [ ] Device testing confirmed

---

## Current Status

### Already Implemented

**Week 1 Model Layer (100% Complete):**

The model changes are complete. The `SalesCalculatorModel.swift` file now has:

✅ `CalculatorMode` enum (forward/reverse)
✅ `ProfitStatus` enum (profitable/breakeven/loss)
✅ `ForwardCalculationResult` struct with all metrics
✅ `calculateProfit()` method with correct formula
✅ Forward mode inputs (salePrice, itemCost, shippingCost, suppliesCost)
✅ Mode switching method
✅ Reset functionality for both modes

**Week 2 View Structure (60% Complete):**

The main view has been refactored. The `SalesCalculatorView.swift` file now has:

✅ Mode switching structure implemented
✅ Field enum expanded for both forward and reverse modes
✅ Switch statement routing to mode-specific views
✅ References to `ModeToggle`, `ForwardModeView`, `ReverseModeView`

**Missing:** The actual component files referenced by the main view.

### Next Immediate Steps

**Priority 1: Create Missing Components**
1. **Create ModeToggle.swift** (mode selector UI - see spec for design)
2. **Create ForwardModeView.swift** (price→profit UI - complete code in spec)
3. **Create ReverseModeView.swift** (extract existing reverse logic)

**Priority 2: Testing**
4. **Write ForwardCalculationTests.swift** (5 tests detailed in spec)
5. **Write CalculationModeTests.swift** (3 mode switching tests)
6. **Run all tests and verify calculations**

**Priority 3: Manual Verification**
7. **Manual testing with all 6 platforms**
8. **Test mode switching and persistence**
9. **Mark Weeks 1 and 2 complete**

Then proceed to Week 3 (Platform Comparison) as documented.

---

## Formula Quick Reference

### Forward Mode (Week 1)
```
Net Profit = Sale Price - Item Cost - Shipping - Platform Fee - Payment Fee

Where:
  Platform Fee = Sale Price × Platform Fee %
  Payment Fee = (Sale Price × Payment Fee %) + Fixed Fee
```

### Reverse Mode (Existing)
```
Sale Price = (Item Cost + Shipping + Desired Profit + Fixed Fee) / (1 - Total Fee %)

Where:
  Total Fee % = Platform Fee % + Payment Fee %
```

### Example: $100 Sale on eBay
```
Sale Price:    $100.00
Item Cost:     $ 50.00
Shipping:      $  3.00

Platform Fee:  $100 × 12.95% = $12.95
Payment Fee:   ($100 × 2.9%) + $0.30 = $3.20
Total Fees:    $19.15

Net Profit:    $100 - $50 - $3 - $19.15 = $27.85
Margin:        27.85% (on sale) or 55.7% (on cost)
```

---

## Risk Mitigation

### Technical Risks
- ✅ **Breaking existing code:** Avoided by keeping all old code intact
- ✅ **Decimal precision:** Using Decimal throughout, not Double
- ⚠️ **UserDefaults sync:** Test on physical device, not just simulator
- ⚠️ **Performance:** Cache calculations, limit comparison to 6 platforms

### UX Risks
- ✅ **Confusing mode labels:** Clear descriptions added ("What are my fees?")
- ⚠️ **Too many warnings:** Only show critical warnings (negative profit, micro-profit)
- ⚠️ **Mode switching confusion:** Preserve user inputs when switching

### Timeline Risks
- ✅ **Week 1 already started:** Model changes done, just need UI
- ⚠️ **Week 2 complexity:** UserDefaults persistence needs device testing
- ⚠️ **Week 3 scope creep:** Custom fee editor is optional, can defer to v1.1

---

## Post-Launch Enhancements (Future Work)

**V1.1 Features (Not in Current Spec):**
- Bulk calculations (quantity field)
- Platform presets (save custom fee structures)
- Calculation history
- Export to CSV/PDF
- "Worth it?" hourly rate calculator
- Advanced custom fee editor
- Multi-currency support

---

**Ready for Implementation:** This specification is complete and actionable. Start with Week 1 UI implementation using the detailed code examples in the full spec document.
