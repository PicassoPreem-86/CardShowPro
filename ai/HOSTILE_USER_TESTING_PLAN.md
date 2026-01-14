# Hostile User Testing Plan - Sales Calculator
## "Nothing Works Until You Prove It Does"

**Testing Philosophy:** Approach this like a professional skeptic who actively WANTS to find problems. The only acceptable outcome is genuine functionality that survives brutal, real-world abuse.

**Testing Date:** 2026-01-13
**Tester Mindset:** Anal-retentive user who doesn't trust apps, doesn't like surprises, and only accepts perfection
**Success Criteria:** Calculator must handle EVERY scenario correctly with zero confusion

---

## Testing Environment

**Device:** iPhone 16 Simulator (iOS 17.0+)
**Build:** Latest from CardShowProPackage
**Entry Point:** Tools Tab → Sales Calculator
**Expected Duration:** 90-120 minutes (thorough testing takes time)

---

## Category 1: Basic Functionality Skepticism (10 tests)

### TEST 1.1: "Does This Even Work?" - Forward Mode Smoke Test
**Hostile Mindset:** "I bet this calculator gives me the wrong answer"

**Scenario:** I want to sell a $100 card on eBay. Show me my profit.

**Steps:**
1. Open Sales Calculator
2. Verify Forward Mode is DEFAULT (not buried in settings)
3. Select platform: eBay
4. Enter Sale Price: `$100.00`
5. Enter Item Cost: `$50.00`
6. Leave shipping/supplies at `$0.00`

**Expected Result:**
- Platform Fee (12.95%): `$12.95`
- Payment Fee (2.9% + $0.30): `$3.20`
- Total Fees: `$16.15`
- Total Costs: `$50.00`
- Net Profit: `$33.85`
- ROI: `67.7%`
- Profit Margin: `33.85%`

**Manual Verification:**
```
Sale Price: $100.00
Item Cost: -$50.00
Platform Fee (12.95%): -$12.95
Payment Fee (2.9% + $0.30): -$3.20
= Net Profit: $33.85 ✓
ROI: $33.85 / $50.00 = 67.7% ✓
Margin: $33.85 / $100.00 = 33.85% ✓
```

**Pass Criteria:**
- ✅ All calculations accurate to $0.01
- ✅ UI clearly shows this is PROFIT (not confusing)
- ✅ Color-coded green (profitable)
- ✅ No weird decimal rounding issues

**Hostile Questions:**
- "Why is my profit only $33.85 when I paid $50 and sold for $100?"
  → Calculator should make it OBVIOUS that $16.15 went to fees
- "Is this including PayPal fees or just eBay?"
  → Fee breakdown should be visible and clear
- "How do I know this isn't wrong?"
  → Numbers should match eBay's actual 2024 fee structure

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_1.1_forward_basic.png`
**Notes:** _________________________________

---

### TEST 1.2: "The Math Doesn't Math" - Reverse Mode Verification
**Hostile Mindset:** "If I want $20 profit, you better tell me EXACTLY what to charge"

**Scenario:** I bought a card for $50. I want exactly $20 profit after eBay fees.

**Steps:**
1. Reset calculator
2. Switch to **Reverse Mode** (toggle should be prominent)
3. Select platform: eBay
4. Enter Item Cost: `$50.00`
5. Enter Profit Mode: **$ Amount**
6. Enter Desired Profit: `$20.00`

**Expected Result:**
- Recommended Sale Price: `$83.47`
- Net Profit: `$20.00` (EXACTLY, not $19.98 or $20.03)

**Manual Verification:**
```
Reverse calculation formula:
ListPrice = (Cost + Profit + FixedFees) / (1 - TotalFeePercentage)
ListPrice = ($50 + $20 + $0.30) / (1 - 0.1585)
ListPrice = $70.30 / 0.8415 = $83.54 (approx)

Verify by calculating forward:
Sale: $83.54
Platform: $83.54 × 0.1295 = $10.82
Payment: ($83.54 × 0.029) + $0.30 = $2.72
Profit: $83.54 - $50 - $10.82 - $2.72 = $20.00 ✓
```

**Pass Criteria:**
- ✅ Sale price calculated correctly (within $0.05)
- ✅ Net profit is EXACTLY $20.00 (±$0.01)
- ✅ UI clearly labels this as "RECOMMENDED SALE PRICE"
- ✅ No confusion about which number is which

**Hostile Questions:**
- "If I charge $83.54, will I ACTUALLY get $20 profit?"
  → Calculator must account for ALL fees, no hidden surprises
- "What if eBay changes their fees tomorrow?"
  → UI should show fee percentages clearly

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_1.2_reverse_fixed.png`
**Notes:** _________________________________

---

### TEST 1.3: "Percentage Mode Is Confusing" - Reverse Mode with % Margin
**Hostile Mindset:** "I don't understand percentages, this better not screw me"

**Scenario:** 50% profit margin on a $100 card

**Steps:**
1. Reset calculator
2. Reverse Mode
3. Platform: eBay
4. Item Cost: `$100.00`
5. Profit Mode: **% Margin**
6. Tap preset: **50%**

**Expected Result:**
- Recommended Sale Price: `$178.30`
- Net Profit: `$50.00`
- ROI: `50%`

**Pass Criteria:**
- ✅ 50% preset button clearly selected
- ✅ Net profit is exactly $50 (50% of $100 cost)
- ✅ Terminology doesn't confuse "margin" vs "markup" vs "ROI"

**Hostile Questions:**
- "Is 50% margin the same as 50% markup?"
  → NO! Margin = profit/revenue, Markup = profit/cost
  → Calculator should use MARGIN terminology consistently
- "Why do I need to charge $178 to make $50?"
  → Fees explanation should be obvious

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_1.3_reverse_percent.png`
**Notes:** _________________________________

---

### TEST 1.4: "Mode Switching Should Be Seamless" - Toggle Stress Test
**Hostile Mindset:** "If I switch modes, you better not lose my data or crash"

**Scenario:** Rapidly switch between modes with data entered

**Steps:**
1. Forward Mode: Enter sale price $100, cost $50
2. Note the profit shown: ~$33.85
3. Switch to Reverse Mode
4. Verify cost is still $50 (data preserved)
5. Switch back to Forward Mode
6. Verify sale price is still $100 (data preserved)
7. Repeat 5 times rapidly

**Pass Criteria:**
- ✅ No crashes
- ✅ Data persists across mode switches
- ✅ No weird UI glitches or frozen inputs
- ✅ Smooth animation (not jarring)
- ✅ Clear visual indicator which mode is active

**Hostile Questions:**
- "Why did my numbers disappear?"
  → Data should NEVER be lost during mode switching
- "Which mode am I in?"
  → Mode toggle should be IMPOSSIBLE to miss

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_1.4_mode_toggle.png`
**Notes:** _________________________________

---

### TEST 1.5: "Platform Comparison Better Work" - All 6 Platforms Side-by-Side
**Hostile Mindset:** "I don't trust you to tell me which platform is best"

**Scenario:** $100 sale price, $50 cost, which platform is most profitable?

**Steps:**
1. Forward Mode
2. Sale Price: `$100.00`, Cost: `$50.00`
3. Tap **"Compare All Platforms"** button (should be prominent)
4. View comparison sheet

**Expected Result:**
Platform ranking by net profit (highest to lowest):
1. **In-Person:** $50.00 profit (0% fees)
2. **Facebook:** $44.60 profit (5% + $0.40)
3. **TCGPlayer:** $33.95 profit (15.75% + $0.30)
4. **eBay:** $33.85 profit (15.85% + $0.30)
5. **StockX:** $37.50 profit (12.5% fees)
6. **Custom:** TBD (depends on default fees)

**Pass Criteria:**
- ✅ All 6 platforms listed
- ✅ Ranked by profit (best at top)
- ✅ Best platform highlighted with star or color
- ✅ Shows fees, profit, and ROI for each
- ✅ Easy to read, not cluttered
- ✅ "Done" button returns to calculator (doesn't lose data)

**Hostile Questions:**
- "How do I know In-Person is best?"
  → Best platform should be VISUALLY OBVIOUS (star, highlight, etc.)
- "What if I prefer eBay even if it's not the cheapest?"
  → User should be able to tap any platform to select it (optional)
- "Is this comparison accurate?"
  → Manually verify at least 3 platforms' calculations

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_1.5_comparison.png`
**Notes:** _________________________________

---

### TEST 1.6: "Negative Profit Should Scream at Me" - Loss Warning
**Hostile Mindset:** "If I'm losing money, you better YELL at me"

**Scenario:** Card that will lose money after fees

**Steps:**
1. Forward Mode
2. Sale Price: `$50.00`
3. Item Cost: `$45.00`
4. Shipping Cost: `$5.00`
5. Supplies Cost: `$2.00`
6. Platform: eBay

**Expected Result:**
- Total Costs: $52.00
- Total Fees: ~$8.08
- Net Profit: **-$10.08** (LOSS)

**Pass Criteria:**
- ✅ Profit displayed in RED
- ✅ Large warning banner: "YOU WILL LOSE MONEY"
- ✅ Shows exact loss amount: "You will lose $10.08"
- ✅ Warning icon (exclamation triangle)
- ✅ Status badge says "LOSS" (not "profitable")

**Hostile Questions:**
- "Why would I ever do this?"
  → Some sellers intentionally take losses to clear inventory, but they need to KNOW
- "Can I ignore this warning?"
  → Yes, but it should be IMPOSSIBLE to miss

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_1.6_negative_profit.png`
**Notes:** _________________________________

---

### TEST 1.7: "Zero Inputs Shouldn't Break It" - Edge Case Handling
**Hostile Mindset:** "I'm going to enter all zeros and see if this crashes"

**Scenario:** Enter $0 for everything

**Steps:**
1. Reset calculator
2. Forward Mode
3. Sale Price: `$0.00`
4. Cost: `$0.00`
5. Platform: eBay

**Expected Result:**
- No crash
- Either shows $0 profit gracefully
- OR shows helpful message: "Enter a sale price to calculate profit"

**Pass Criteria:**
- ✅ App doesn't crash
- ✅ No weird errors or "NaN" displayed
- ✅ UI remains functional
- ✅ If shows $0, it should be correct (not confusing)

**Hostile Questions:**
- "What happens if I calculate with no data?"
  → Should be graceful, not broken

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_1.7_zero_inputs.png`
**Notes:** _________________________________

---

### TEST 1.8: "Penny Cards Are Real" - Micro-Value Calculation
**Hostile Mindset:** "I sell bulk commons for $1 each, your calculator better work"

**Scenario:** $5 card with $3 shipping

**Steps:**
1. Forward Mode
2. Sale Price: `$5.00`
3. Item Cost: `$0.50`
4. Shipping Cost: `$3.00`
5. Platform: eBay

**Expected Result:**
- Platform Fee: $0.65
- Payment Fee: $0.45
- Total Fees: $1.10
- Net Profit: ~$0.40

**Pass Criteria:**
- ✅ Calculation accurate for small amounts
- ✅ No rounding errors
- ✅ Possibly shows warning: "Profit is very small"

**Hostile Questions:**
- "Is $0.40 profit worth shipping this?"
  → Calculator should make it obvious this is micro-profit

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_1.8_penny_card.png`
**Notes:** _________________________________

---

### TEST 1.9: "High-Value Cards Exist" - Large Number Handling
**Hostile Mindset:** "I sell $10,000 PSA 10 cards, your calculator better not break"

**Scenario:** $10,000 sale on eBay

**Steps:**
1. Forward Mode
2. Sale Price: `$10,000.00`
3. Item Cost: `$5,000.00`
4. Platform: eBay

**Expected Result:**
- Platform Fee (12.95%): $1,295.00
- Payment Fee (2.9% + $0.30): $290.30
- Total Fees: $1,585.30
- Net Profit: $3,414.70

**Pass Criteria:**
- ✅ Handles 5-digit numbers without issue
- ✅ No weird formatting (e.g., "$10,000.00" not "$10000" or "$1e4")
- ✅ Calculations remain accurate at scale

**Hostile Questions:**
- "Are these eBay's actual fees for $10K sales?"
  → YES, eBay caps some fees but 12.95% applies to trading cards

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_1.9_high_value.png`
**Notes:** _________________________________

---

### TEST 1.10: "Supplies Cost Adds Up" - Full Cost Accounting
**Hostile Mindset:** "If I spend $5 on a top-loader and bubble mailer, that better reduce my profit"

**Scenario:** $100 sale with all costs

**Steps:**
1. Forward Mode
2. Sale Price: `$100.00`
3. Item Cost: `$50.00`
4. Shipping Cost: `$3.00`
5. Supplies Cost: `$5.00`
6. Platform: eBay

**Expected Result:**
- Total Costs: $58.00
- Net Profit: ~$25.85 (not $33.85 like Test 1.1)

**Pass Criteria:**
- ✅ Supplies cost reduces net profit correctly
- ✅ "Total Costs" line shows $58.00
- ✅ Fee breakdown still visible

**Hostile Questions:**
- "Why is my profit $8 lower than before?"
  → Should be obvious that supplies cost $5 extra

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_1.10_supplies_cost.png`
**Notes:** _________________________________

---

## Category 2: Real-World Seller Hostility (10 tests)

### TEST 2.1: "eBay's Fees Are Highway Robbery" - Fee Verification
**Hostile Mindset:** "I don't believe eBay charges 16%. Prove it."

**Scenario:** Verify eBay's actual 2024 fee structure

**Steps:**
1. Forward Mode, eBay, Sale Price: $100
2. Tap **"Fee Breakdown"** (should be collapsible section)
3. View detailed fees

**Expected Breakdown:**
- Platform Fee: $12.95 (12.95% Final Value Fee)
- Payment Processing: $3.20 (2.9% + $0.30 Managed Payments)
- **Total: $16.15**

**Pass Criteria:**
- ✅ Fee breakdown is accessible (not hidden)
- ✅ Shows both platform and payment fees separately
- ✅ Shows percentages, not just dollar amounts
- ✅ Matches eBay's actual 2024 rates (verify via eBay seller portal)

**Hostile Questions:**
- "Where did you get these numbers?"
  → Should cite source or at least match reality
- "What about promoted listings or optional fees?"
  → Calculator assumes standard fees (no promotions)

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_2.1_fee_breakdown.png`
**Notes:** _________________________________

---

### TEST 2.2: "TCGPlayer vs eBay - Which Is Cheaper?" - Platform Comparison Accuracy
**Hostile Mindset:** "I bet your comparison is wrong"

**Scenario:** $200 card, compare TCGPlayer vs eBay

**Steps:**
1. Forward Mode, Sale Price: $200, Cost: $100
2. Platform: eBay → Note profit
3. Platform: TCGPlayer → Note profit
4. Tap **"Compare All Platforms"**
5. Verify TCGPlayer and eBay ranking

**Expected Results:**
- eBay: Platform 12.95%, Payment 2.9%+$0.30 = $31.70 fees, $68.30 profit
- TCGPlayer: Platform 12.85%, Payment 2.9%+$0.30 = $31.40 fees, $68.60 profit
- **TCGPlayer should rank higher** (saves $0.30)

**Pass Criteria:**
- ✅ TCGPlayer shows slightly higher profit
- ✅ Comparison view ranks them correctly
- ✅ Manual calculation matches displayed results

**Hostile Questions:**
- "Why is TCGPlayer only $0.30 better?"
  → 0.1% fee difference on $200 = minor savings
- "Is this accounting for shipping policies?"
  → Calculator assumes same shipping cost on both platforms

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_2.2_tcg_vs_ebay.png`
**Notes:** _________________________________

---

### TEST 2.3: "Facebook Marketplace Is 'Free' Right?" - Hidden Fee Discovery
**Hostile Mindset:** "Facebook says no selling fees, but you're showing fees"

**Scenario:** Compare Facebook vs eBay

**Steps:**
1. Sale Price: $100, Cost: $50
2. Platform: Facebook Marketplace

**Expected Result:**
- Platform Fee (5%): $5.00
- Payment Fee (flat): $0.40
- **Total Fees: $5.40**
- Net Profit: $44.60

**Pass Criteria:**
- ✅ Shows that Facebook DOES charge fees (for shipped items)
- ✅ Fee structure is accurate (5% + $0.40 for 2024)
- ✅ Profit is significantly higher than eBay ($44.60 vs $33.85)

**Hostile Questions:**
- "I thought Facebook was free?"
  → Free for local pickup, but 5% for shipping
- "Why does Facebook only charge $0.40 payment fee?"
  → Facebook Checkout has different structure than PayPal

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_2.3_facebook_fees.png`
**Notes:** _________________________________

---

### TEST 2.4: "StockX Fees Are Confusing" - Verification of StockX Math
**Hostile Mindset:** "StockX fees change based on seller level, how do you handle that?"

**Scenario:** $300 sneaker card on StockX

**Steps:**
1. Sale Price: $300, Cost: $150
2. Platform: StockX

**Expected Result:**
- Platform Fee (9.5%): $28.50
- Payment Fee (3%): $9.00
- Total Fees: $37.50
- Net Profit: $112.50

**Pass Criteria:**
- ✅ Fees accurate for 9.5% + 3% structure
- ⚠️ Note: StockX fees vary (9.5% is lowest tier)
- ✅ If there's a note/disclaimer about tier, that's good

**Hostile Questions:**
- "What if I'm a higher-tier seller with 8% fees?"
  → Calculator uses default 9.5%, user can use Custom platform
- "Does StockX have payment processing fees?"
  → Yes, 3% built in

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_2.4_stockx.png`
**Notes:** _________________________________

---

### TEST 2.5: "In-Person Sales Have Zero Fees Right?" - Cash Sale Verification
**Hostile Mindset:** "If I'm calculating an in-person sale, there better be NO fees"

**Scenario:** $100 cash sale at a card show

**Steps:**
1. Sale Price: $100, Cost: $50
2. Platform: In-Person

**Expected Result:**
- Platform Fee: $0.00
- Payment Fee: $0.00
- Total Fees: $0.00
- Net Profit: $50.00 (exactly sale - cost)

**Pass Criteria:**
- ✅ No fees charged
- ✅ Profit is exactly $50 (100% of markup)
- ✅ This should rank #1 in platform comparison

**Hostile Questions:**
- "What about credit card processing?"
  → Assumes cash, no processing
- "What about table fees at the show?"
  → Not platform fees, user adds to item cost manually

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_2.5_in_person.png`
**Notes:** _________________________________

---

### TEST 2.6: "Custom Platform - Can I Edit Fees?" - Customization Test
**Hostile Mindset:** "If this is 'custom', I better be able to change the fees"

**Scenario:** Top-rated eBay seller with 10% fees (not 12.95%)

**Steps:**
1. Platform: Custom Fees
2. **Attempt to edit fee percentages**
   - Can you tap on "10%" and change it?
   - Can you tap on "2.9%" and change it?
   - Can you tap on "$0.30" and change it?

**Expected Behavior:**
- ✅ Custom platform allows fee editing
- ✅ Clear UI for changing percentages
- ✅ Changes persist during session
- OR
- ❌ Custom platform does NOT allow editing (FAIL)

**Pass Criteria:**
- ✅ If editing is possible, it works smoothly
- ❌ If editing is NOT possible, "Custom Fees" is useless

**Hostile Questions:**
- "How do I change the custom fees?"
  → Should be obvious (edit icon, tap to edit, etc.)
- "Can I save my custom fee presets?"
  → Nice to have, but not required for MVP

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_2.6_custom_fees.png`
**Notes:** _________________________________

---

### TEST 2.7: "International Shipping Kills Margins" - High Shipping Cost Impact
**Hostile Mindset:** "If I ship to Japan for $25, that better be accounted for"

**Scenario:** $100 card, $25 international shipping

**Steps:**
1. Forward Mode
2. Sale Price: $100
3. Item Cost: $50
4. Shipping Cost: $25
5. Platform: eBay

**Expected Result:**
- Total Costs: $75
- Fees: ~$16.15
- Net Profit: ~$8.85 (much lower than $33.85 from Test 1.1)

**Pass Criteria:**
- ✅ Shipping cost reduces profit correctly
- ✅ "Total Costs" line shows $75
- ✅ Profit margin dropped from 33.85% to 8.85%

**Hostile Questions:**
- "Why is my profit so much lower?"
  → Calculator should make it obvious that $25 went to shipping
- "Should I charge more to cover shipping?"
  → User can try different sale prices to find break-even

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_2.7_international_shipping.png`
**Notes:** _________________________________

---

### TEST 2.8: "Reset Button Better Actually Reset" - Data Clearing
**Hostile Mindset:** "If I tap Reset, EVERYTHING should clear"

**Scenario:** Enter data, then reset

**Steps:**
1. Forward Mode
2. Enter: Sale $100, Cost $50, Shipping $5, Supplies $2
3. Switch to TCGPlayer platform
4. Tap **Reset** button
5. Verify all fields

**Expected Result:**
- Sale Price: $0 or empty
- Item Cost: $0 or empty
- Shipping: $0 or empty
- Supplies: $0 or empty
- Platform: eBay (default) OR stays on TCGPlayer
- Mode: Forward (default) OR stays in current mode

**Pass Criteria:**
- ✅ All numeric fields cleared
- ✅ Results disappear (no stale data)
- ✅ Calculator is ready for new calculation
- ✅ No leftover state from previous calculation

**Hostile Questions:**
- "Why is there still data showing?"
  → Reset should be COMPLETE reset
- "Did it reset the mode too?"
  → Acceptable either way, but should be consistent

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_2.8_reset.png`
**Notes:** _________________________________

---

### TEST 2.9: "Graded Card Math" - Combined Costs Calculation
**Hostile Mindset:** "I paid $200 for raw, $50 for grading. Calculator better handle combined costs."

**Scenario:** PSA 10 graded card

**Steps:**
1. Forward Mode
2. Sale Price: $500
3. Item Cost: $250 (manually combine $200 card + $50 grading)
4. Platform: eBay

**Expected Result:**
- Treats $250 as single item cost
- Calculates profit correctly

**Pass Criteria:**
- ✅ Accepts combined cost
- ⚠️ No separate "Grading Cost" field (user must add manually)
- ✅ Calculation is accurate

**Hostile Questions:**
- "Can I break out card cost vs grading cost?"
  → NO, not in MVP (future feature)
- "Does profit calculation care about the breakdown?"
  → NO, $250 total cost is what matters

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_2.9_graded_card.png`
**Notes:** _________________________________

---

### TEST 2.10: "Copy Price to Clipboard" - Export Functionality
**Hostile Mindset:** "I better be able to copy this price without typing it manually"

**Scenario:** Calculate price, then copy result

**Steps:**
1. Reverse Mode
2. Item Cost: $50, Profit: $20, Platform: eBay
3. Result: Sale Price $83.54
4. **Attempt to copy sale price**
   - Long-press on price
   - Look for "Copy" button
   - Tap copy (if exists)

**Expected Behavior:**
- ✅ Sale price copies to clipboard
- ✅ Confirmation toast: "Copied $83.54"
- OR
- ⚠️ Copy functionality not implemented (acceptable for MVP)

**Pass Criteria:**
- ✅ If copy exists, it works reliably
- ⚠️ If no copy, not a deal-breaker but noted

**Hostile Questions:**
- "How do I copy this to list on eBay?"
  → If no copy, user must manually type

**Verdict:** [ ] PASS [ ] PARTIAL [ ] FAIL
**Screenshot:** `/tmp/test_2.10_copy_price.png`
**Notes:** _________________________________

---

## Category 3: Edge Case Torture Tests (8 tests)

### TEST 3.1: "Decimal Precision Matters" - Rounding Accuracy
**Hostile Mindset:** "If you're off by even $0.01, I don't trust you"

**Scenario:** $47.99 sale (weird price) with precise calculation

**Steps:**
1. Forward Mode
2. Sale Price: $47.99
3. Item Cost: $20.00
4. Platform: eBay

**Expected Result:**
- Platform Fee: $6.21 (12.95% of $47.99)
- Payment Fee: $1.69 (2.9% + $0.30)
- Net Profit: $20.09

**Manual Verification:**
```
Platform: $47.99 × 0.1295 = $6.2148 → $6.21
Payment: ($47.99 × 0.029) + $0.30 = $1.6917 → $1.69
Profit: $47.99 - $20.00 - $6.21 - $1.69 = $20.09 ✓
```

**Pass Criteria:**
- ✅ Calculations accurate to 2 decimal places
- ✅ No weird rounding artifacts
- ✅ All intermediate values visible in breakdown

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_3.1_decimal_precision.png`
**Notes:** _________________________________

---

### TEST 3.2: "Negative Item Cost" - Invalid Input Handling
**Hostile Mindset:** "What if I accidentally enter negative cost?"

**Scenario:** Typo or acquired card via trade (negative cost)

**Steps:**
1. Forward Mode
2. Sale Price: $100
3. Item Cost: `-$50` (try to enter negative)

**Expected Behavior:**
- ❌ Blocks negative input (doesn't let you type minus)
- OR
- ⚠️ Accepts but shows warning: "Item cost cannot be negative"
- OR
- ❌ Accepts and calculates (FAIL - gives wrong profit)

**Pass Criteria:**
- ✅ Either prevents or warns about negative input
- ❌ Silently accepting negative = FAIL

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_3.2_negative_cost.png`
**Notes:** _________________________________

---

### TEST 3.3: "Extreme Fee Percentages" - 99% Fee Test
**Hostile Mindset:** "What if a platform charges 99% fees? (They don't, but break it)"

**Scenario:** Custom platform with absurd fees

**Steps:**
1. Platform: Custom Fees
2. IF editable, set Platform Fee: 99%
3. Sale Price: $100, Cost: $50

**Expected Behavior:**
- Calculator either:
  - Shows warning: "Fees too high"
  - Calculates and shows $1 profit (correct but absurd)
  - Breaks gracefully (doesn't crash)

**Pass Criteria:**
- ✅ Doesn't crash
- ✅ Handles extreme percentages mathematically
- ⚠️ May show warning about unrealistic fees

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 3.4: "Maximum Safe Integer" - $999,999 Card Test
**Hostile Mindset:** "Rich people problems - million-dollar cards exist"

**Scenario:** Ultra-rare card sale

**Steps:**
1. Forward Mode
2. Sale Price: $999,999
3. Item Cost: $500,000
4. Platform: eBay

**Expected Result:**
- Platform Fee: $129,499.87
- Payment Fee: $29,299.67
- Net Profit: $341,199.46

**Pass Criteria:**
- ✅ Handles 6-digit numbers
- ✅ No integer overflow
- ✅ UI doesn't break with large numbers
- ✅ Comma formatting: "$999,999" (readable)

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_3.4_max_value.png`
**Notes:** _________________________________

---

### TEST 3.5: "Floating Point Errors" - $0.01 + $0.01 + $0.01 Test
**Hostile Mindset:** "Computers can't add decimals correctly. Prove you're using Decimal type."

**Scenario:** Accumulation test for rounding errors

**Steps:**
1. Calculate profit for $10 sale, $5 cost, eBay
2. Record profit: X
3. Calculate again with exact same inputs
4. Record profit: Y
5. Verify X == Y (byte-for-byte identical)

**Pass Criteria:**
- ✅ Same inputs ALWAYS give same outputs
- ✅ No cumulative floating-point drift
- ✅ Using Decimal type (not Float/Double)

**Code Check:**
```swift
// Should use Decimal, NOT Double
var salePrice: Decimal  // ✅ CORRECT
var salePrice: Double   // ❌ WRONG
```

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 3.6: "Break-Even Scenario" - Zero Profit Target
**Hostile Mindset:** "What if I just want to break even?"

**Scenario:** Calculate list price for $0 profit

**Steps:**
1. Reverse Mode
2. Item Cost: $50
3. Profit: $0.00
4. Platform: eBay

**Expected Result:**
- Recommended Sale Price: $59.47
- Net Profit: $0.00 (exactly, not $0.02)

**Manual Verification:**
```
ListPrice = ($50 + $0 + $0.30) / 0.8415 = $59.85
Fees = $9.85
Profit = $59.85 - $50 - $9.85 = $0.00 ✓
```

**Pass Criteria:**
- ✅ Calculates break-even price correctly
- ✅ Profit is exactly $0
- ✅ Status badge shows "BREAK EVEN" (not loss or profit)

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_3.6_break_even.png`
**Notes:** _________________________________

---

### TEST 3.7: "Empty Input Fields" - Partial Data Entry
**Hostile Mindset:** "What if I forget to enter something?"

**Scenario:** Enter sale price but not cost

**Steps:**
1. Forward Mode
2. Sale Price: $100
3. Leave Item Cost EMPTY (not $0, but blank)
4. Platform: eBay

**Expected Behavior:**
- Treats empty as $0
- OR shows message: "Enter item cost to calculate profit"

**Pass Criteria:**
- ✅ Handles blank inputs gracefully
- ✅ Doesn't show "NaN" or error text
- ✅ Clear what user needs to do next

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 3.8: "Rapid Input Spam" - Performance Test
**Hostile Mindset:** "What if I type really fast and change numbers constantly?"

**Scenario:** Stress test input handling

**Steps:**
1. Forward Mode
2. Type in sale price field: `1234567890` quickly
3. Delete and retype: `$100.00`
4. Switch to cost field, spam: `999888777`
5. Delete and enter: `$50.00`
6. Check result

**Pass Criteria:**
- ✅ No lag or frozen UI
- ✅ Calculations update in real-time
- ✅ No leftover state from spam typing
- ✅ Final result is correct

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

## Category 4: UI/UX Hostility (5 tests)

### TEST 4.1: "I'm Colorblind" - Accessibility Check
**Hostile Mindset:** "If your profit/loss colors don't have text labels, I can't use this"

**Scenario:** Verify color-blind accessibility

**Steps:**
1. Calculate a profitable sale (green profit)
2. Calculate a loss (red profit)
3. Verify BOTH have text labels, not just color

**Expected:**
- ✅ Profitable: Green + "PROFITABLE" badge + ✓ icon
- ✅ Loss: Red + "LOSS" badge + ⚠️ icon
- ✅ Break-even: Gray + "BREAK EVEN" badge + — icon

**Pass Criteria:**
- ✅ Status is NEVER indicated by color alone
- ✅ Text and icons provide redundancy
- ✅ Passes WCAG accessibility guidelines

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 4.2: "Dark Mode Better Work" - Theme Consistency
**Hostile Mindset:** "I use Dark Mode. If your text is unreadable, I'm uninstalling"

**Scenario:** Enable Dark Mode

**Steps:**
1. Open iOS Settings → Display → Dark Mode
2. Return to app
3. Navigate to Sales Calculator

**Expected:**
- ✅ All text readable (high contrast)
- ✅ Input fields visible
- ✅ Buttons clearly tappable
- ✅ No white backgrounds blinding user

**Pass Criteria:**
- ✅ Dark Mode fully supported
- ⚠️ Light Mode fully supported (test both)

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_4.2_dark_mode.png`
**Notes:** _________________________________

---

### TEST 4.3: "VoiceOver Support" - Blind User Experience
**Hostile Mindset:** "If VoiceOver doesn't work, you're excluding blind users"

**Scenario:** Enable VoiceOver

**Steps:**
1. Enable VoiceOver (Triple-click home button or Settings)
2. Navigate to Sales Calculator
3. Swipe through all elements

**Expected:**
- ✅ All input fields have labels ("Sale price text field")
- ✅ Results are announced ("Net profit: thirty-three dollars and eighty-five cents")
- ✅ Buttons have clear labels ("Compare all platforms button")
- ✅ Platform picker is navigable

**Pass Criteria:**
- ✅ Every interactive element has accessibilityLabel
- ✅ Results are announced with .updatesFrequently trait
- ✅ Full calculator is usable with VoiceOver

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 4.4: "Tiny iPhone SE Screen" - Small Device Layout
**Hostile Mindset:** "Not everyone has an iPhone 16 Pro Max"

**Scenario:** Test on smallest supported device

**Steps:**
1. Switch simulator to iPhone SE (3rd gen)
2. Navigate to Sales Calculator
3. Verify layout

**Expected:**
- ✅ All fields visible without horizontal scrolling
- ✅ Buttons not cut off
- ✅ Text not truncated with "..."
- ✅ Comparison view readable

**Pass Criteria:**
- ✅ Layout adapts to small screens
- ✅ No critical information hidden

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/test_4.4_iphone_se.png`
**Notes:** _________________________________

---

### TEST 4.5: "Landscape Mode" - Rotation Support
**Hostile Mindset:** "I hold my phone sideways, deal with it"

**Scenario:** Rotate device to landscape

**Steps:**
1. Open Sales Calculator (portrait)
2. Rotate simulator to landscape (Cmd+Left/Right)
3. Verify layout

**Expected:**
- ✅ Layout adapts gracefully
- OR
- ⚠️ Landscape not supported (locks to portrait)

**Pass Criteria:**
- ✅ If landscape supported, layout works
- ⚠️ If landscape blocked, should lock orientation

**Verdict:** [ ] PASS [ ] PARTIAL [ ] FAIL
**Screenshot:** `/tmp/test_4.5_landscape.png`
**Notes:** _________________________________

---

## Category 5: "I Don't Trust Your Math" (Mathematical Verification)

### TEST 5.1: Manual Cross-Check - eBay $100 Sale
**Scenario:** Verify eBay calculation against official calculator

**Steps:**
1. Forward Mode: $100 sale, $50 cost, eBay
2. Record app result: Fees $X, Profit $Y
3. Visit: https://www.ebay.com/sh/finance/fees
4. Enter $100, category "Trading Cards"
5. Compare results

**Pass Criteria:**
- ✅ Fees match eBay's official calculator (±$0.10)
- ✅ Any discrepancies are documented

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 5.2: Manual Cross-Check - TCGPlayer $200 Sale
**Scenario:** Verify TCGPlayer against real-world fees

**Steps:**
1. App: $200 sale, TCGPlayer
2. Record fees
3. Check TCGPlayer fee structure documentation
4. Verify 12.85% + 2.9% + $0.30 is accurate for 2024

**Pass Criteria:**
- ✅ Fees match TCGPlayer's current structure

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 5.3: Reverse Calculation Proof - Work Backwards
**Scenario:** Reverse mode $20 profit → Forward mode should return $20

**Steps:**
1. Reverse Mode: Cost $50, Profit $20, eBay
2. Record sale price: $X
3. Switch to Forward Mode
4. Enter Sale Price $X, Cost $50, eBay
5. Verify profit = $20.00 (exactly)

**Pass Criteria:**
- ✅ Round-trip calculation is exact
- ✅ Forward and Reverse modes are inverses

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 5.4: Platform Comparison Math Audit
**Scenario:** Manually verify comparison rankings

**Steps:**
1. Forward: $100 sale, $50 cost
2. Comparison view shows all 6 platforms
3. Manually calculate profit for each:
   - In-Person: $100 - $50 = $50.00
   - Facebook: $100 - $5.40 - $50 = $44.60
   - StockX: $100 - $12.50 - $50 = $37.50
   - TCGPlayer: $100 - $16.05 - $50 = $33.95
   - eBay: $100 - $16.15 - $50 = $33.85
   - Custom: TBD
4. Verify app ranking matches manual ranking

**Pass Criteria:**
- ✅ All 6 calculations correct
- ✅ Ranking is highest to lowest profit

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 5.5: Negative Profit Math Verification
**Scenario:** Loss scenario should show correct loss amount

**Steps:**
1. Forward: Sale $30, Cost $50, Shipping $5, eBay
2. App shows loss of $X
3. Manual calculation:
   - Fees: ($30 × 0.1585) + $0.30 = $5.06
   - Total out: $50 + $5 + $5.06 = $60.06
   - Total in: $30
   - Loss: -$30.06

**Pass Criteria:**
- ✅ Loss amount is exactly -$30.06

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

## Final Evaluation

### Scoring Rubric

**Category 1: Basic Functionality (30 points)**
- 10 tests × 3 points each
- Deduct 1 point for minor issues, 3 points for failures

**Category 2: Real-World Scenarios (30 points)**
- 10 tests × 3 points each

**Category 3: Edge Cases (20 points)**
- 8 tests × 2.5 points each

**Category 4: UI/UX (10 points)**
- 5 tests × 2 points each

**Category 5: Math Verification (10 points)**
- 5 tests × 2 points each

**TOTAL: 100 points**

### Grade Scale

| Grade | Score | Meaning | Action |
|-------|-------|---------|--------|
| **A** | 90-100 | Production ready, no blockers | ✅ Ship it |
| **B** | 80-89 | Minor polish needed, functional | ✅ Ship with notes |
| **C** | 70-79 | Significant issues, usable | ⚠️ Fix P0/P1 bugs first |
| **D** | 60-69 | Major problems, barely functional | ❌ Major rework |
| **F** | <60 | Broken, unusable | ❌ Start over |

---

## Post-Testing Actions

**If Grade ≥ B:**
1. Update `/Users/preem/Desktop/CardshowPro/ai/FEATURES.json`:
   ```json
   {
     "id": "F006",
     "passes": true,
     "grade": "B+",
     "testDate": "2026-01-13",
     "notes": "Forward/Reverse modes working, platform comparison functional"
   }
   ```
2. Create test results document: `SALES_CALC_TEST_RESULTS.md`
3. Update `PROGRESS.md` with completion
4. Commit: `verify: Sales Calculator brutal testing complete (Grade: B+)`

**If Grade = C:**
1. Document all failures
2. Create bug tickets for P0/P1 issues
3. Keep `F006: passes = false`
4. Fix issues, re-test

**If Grade < C:**
1. Major redesign required
2. Focus on most critical failures first

---

## Test Execution Notes

**Tester Name:** _________________
**Date Started:** _________________
**Date Completed:** _________________
**Total Time:** _________ minutes

**Environment:**
- Simulator: iPhone 16 / iOS 17.0
- Build: CardShowPro (latest)
- Commit: ____________

**Overall Impression:**
_________________________________________________________
_________________________________________________________
_________________________________________________________

**Would you use this calculator?** [ ] YES [ ] NO

**Final Grade:** _____

---

*This testing plan represents a hostile, skeptical user who actively looks for problems. Success means the calculator survives all 38 brutal tests with grace.*
