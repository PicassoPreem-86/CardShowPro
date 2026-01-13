# Hostile User Testing Plan - Card Price Lookup (Scan Feature)
## "I Don't Trust Your Search Until You Prove It Works"

**Testing Philosophy:** Approach this like a professional skeptic who WANTS the feature to fail. The only acceptable outcome is genuine functionality that survives brutal, real-world abuse.

**Testing Date:** 2026-01-13
**Feature ID:** F001 (Card Recognition API Integration)
**Tester Mindset:** Anal-retentive Pokemon card collector who doesn't trust apps and expects perfection
**Success Criteria:** Search must work flawlessly with ZERO confusion, ZERO bugs, ZERO surprises

---

## Testing Environment

**Device:** iPhone 16 Simulator (iOS 18.5)
**Build:** CardShowPro Debug (latest from CardShowProPackage)
**Entry Point:** Scan Tab (text.magnifyingglass icon) → Card Price Lookup
**Expected Duration:** 90-120 minutes

---

## Category 1: Basic Functionality Torture (8 tests)

### TEST 1.1: "Does Search Even Work?" - Smoke Test
**Hostile Mindset:** "I bet this doesn't even return results"

**Scenario:** Search for the most iconic Pokemon card ever

**Steps:**
1. Launch app, tap "Scan" tab
2. Verify "Card Price Lookup" screen loads
3. Tap "Card Name" field → keyboard appears
4. Type: `Charizard`
5. Card Number: leave BLANK
6. Tap "Look Up Price" button

**Expected Result:**
- Loading indicator appears immediately
- Match selection sheet displays multiple Charizard results
- Each result shows:
  - 100x140 card image
  - Card name (heading4 font)
  - Set name (caption font)
  - Card number (caption font)
- Can tap a card to view pricing

**Pass Criteria:**
- ✅ Search completes in <5 seconds
- ✅ At least 10+ results returned (Charizard is in many sets)
- ✅ All images load successfully
- ✅ No crashes or frozen UI
- ✅ Can tap any card to proceed

**Hostile Questions:**
- "Why didn't it find any cards?"
  → API is working, results exist
- "Why are there so many Charizards?"
  → Multiple sets contain Charizard, sheet lets user choose
- "How do I know which one is mine?"
  → Set name and card number distinguish them

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/scan_1.1_basic_search.png`
**Notes:** _________________________________

---

### TEST 1.2: "Single Match Should Skip Sheet" - Smart UX Test
**Hostile Mindset:** "Don't make me tap through unnecessary steps"

**Scenario:** Search with specific card number that yields one result

**Steps:**
1. Reset search (tap "New Lookup" if needed)
2. Card Name: `Pikachu`
3. Card Number: `025`
4. Tap "Look Up Price"

**Expected Result:**
- NO match selection sheet (smart skip)
- Goes DIRECTLY to pricing results
- Shows 300pt large card image
- Card details section displays
- TCGPlayer pricing grid appears with variants

**Pass Criteria:**
- ✅ Skips unnecessary sheet when only 1 match
- ✅ Large image displays (300pt max width)
- ✅ Pricing data loads successfully
- ✅ At least 2 variants shown (Normal, Holofoil, etc.)

**Hostile Questions:**
- "Why did it skip the selection?"
  → Smart UX: 1 match = no need to choose
- "What if I wanted to see other options?"
  → Card number was specific enough

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/scan_1.2_single_match.png`
**Notes:** _________________________________

---

### TEST 1.3: "Card Number Formats" - Slash vs No Slash
**Hostile Mindset:** "If I type '25/102' instead of '25', this better work"

**Scenario:** Test both card number formats

**Steps:**
1. Search 1: Card Name `Pikachu`, Number `25` → Lookup
2. Record result set count: X
3. New Lookup
4. Search 2: Card Name `Pikachu`, Number `25/102` → Lookup
5. Record result set count: Y

**Expected Result:**
- Both formats are accepted (no error)
- `25/102` is MORE specific → fewer results
- `25` alone → more results (all sets with #25 Pikachu)

**Pass Criteria:**
- ✅ Both formats work without errors
- ✅ Slash "/" character is accepted in input field
- ✅ "25/102" returns ONLY Base Set cards
- ✅ "25" returns ALL Pikachu #25 across sets
- ✅ Input field hint text clarifies both formats

**Hostile Questions:**
- "Why does '25' give me 50 results?"
  → Multiple sets have Pikachu #25
- "Why does '25/102' only give me 1?"
  → Slash format specifies set size (102 cards)

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 1.4: "Loading States Better Be Smooth" - Async UX Test
**Hostile Mindset:** "I hate waiting. Show me SOMETHING while loading"

**Scenario:** Verify loading indicators and smooth transitions

**Steps:**
1. Card Name: `Mewtwo`
2. Tap "Look Up Price"
3. Observe loading sequence

**Expected Observations:**
- Button disables immediately when tapped
- Loading indicator appears (ProgressView, cyan color)
- "Looking up prices..." text displays
- When results arrive, smooth animation transition
- Match selection sheet slides up from bottom

**Pass Criteria:**
- ✅ Loading indicator appears within 0.1s of tap
- ✅ Loading view is centered and professional
- ✅ Transition to results is smooth (no jarring pop-in)
- ✅ Button re-enables after results/error

**Hostile Questions:**
- "Did it freeze?"
  → Loading indicator proves it's working
- "Why is it taking so long?"
  → API call is real-time, speed varies by network

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 1.5: "Pricing Data Accuracy" - Real-World Verification
**Hostile Mindset:** "These prices better match TCGPlayer's website"

**Scenario:** Verify pricing accuracy against official source

**Steps:**
1. Search: `Charizard`, Number `4`, Set `Base Set`
2. View TCGPlayer pricing results
3. Record app's prices:
   - Normal Market: $____
   - Holofoil Market: $____
4. Visit: https://www.tcgplayer.com/product/3464/pokemon-base-set-charizard
5. Compare prices

**Expected Result:**
- Prices should match TCGPlayer within $5 (prices fluctuate)
- At minimum: Normal and Holofoil variants shown
- Market price highlighted in green (success color)

**Pass Criteria:**
- ✅ Prices accurate within $5 or 10% margin
- ✅ Multiple variants displayed (not just 1)
- ✅ Market price is MOST PROMINENT
- ✅ Low/Mid/High prices also shown

**Hostile Questions:**
- "Why is your price different from TCGPlayer?"
  → Prices update daily, API may lag slightly
- "Why only show Market price?"
  → Low/Mid/High are ALSO shown in grid

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/scan_1.5_pricing_accuracy.png`
**Notes:** _________________________________

---

### TEST 1.6: "Image Loading Failures" - Error State Handling
**Hostile Mindset:** "What if the image doesn't load? Show me a fallback"

**Scenario:** Simulate image loading failure

**Steps:**
1. Search for a card with broken image URL (rare but happens)
2. OR disconnect WiFi mid-search to break image loading
3. Observe fallback behavior

**Expected Result:**
- Placeholder image appears (photo.fill icon)
- Text: "Image Unavailable" or similar
- Gray background (not jarring)
- Pricing data STILL loads (independent of image)
- No crashes

**Pass Criteria:**
- ✅ Graceful fallback (not blank white square)
- ✅ Icon + text provide context
- ✅ Pricing works even if image fails
- ✅ No error alerts spam user

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 1.7: "Copy Prices Feature" - Clipboard Export
**Hostile Mindset:** "I want to paste these prices into a spreadsheet"

**Scenario:** Copy pricing to clipboard and verify format

**Steps:**
1. Search any card, view pricing
2. Tap "Copy Prices" button
3. Observe toast notification
4. Open Notes app (or Safari address bar)
5. Paste clipboard contents

**Expected Result:**
- Toast appears at TOP of screen (not blocking content)
- Toast says: "Prices copied to clipboard"
- Toast auto-dismisses after 2 seconds
- Clipboard contains:
  ```
  Pikachu #25
  Base Set

  Normal: $5.00
  Holofoil: $150.00
  ...
  ```

**Pass Criteria:**
- ✅ Copy button is prominent (not hidden)
- ✅ Toast appears and dismisses automatically
- ✅ Clipboard format is readable (not JSON)
- ✅ All variant prices included

**Hostile Questions:**
- "Where did it copy to?"
  → Toast confirms success
- "Why is the format weird?"
  → Should be human-readable, not code

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/scan_1.7_copy_toast.png`
**Notes:** _________________________________

---

### TEST 1.8: "New Lookup Reset" - State Management Test
**Hostile Mindset:** "If I tap 'New Lookup', EVERYTHING should clear"

**Scenario:** Reset after viewing results

**Steps:**
1. Search any card, view pricing
2. Scroll through results
3. Tap "New Lookup" button
4. Verify state

**Expected Result:**
- Card Name field: EMPTY
- Card Number field: EMPTY
- Pricing results: GONE
- Loading indicator: GONE
- Error message: GONE
- Ready for new search

**Pass Criteria:**
- ✅ All fields reset to empty
- ✅ Previous results are cleared
- ✅ No leftover state from last search
- ✅ Keyboard focus returns to Card Name field

**Hostile Questions:**
- "Why is my last search still showing?"
  → Should be completely cleared
- "Do I have to delete the text manually?"
  → NO, "New Lookup" clears all

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

## Category 2: Real-World User Hostility (8 tests)

### TEST 2.1: "Typo Tolerance" - Forgiving Search
**Hostile Mindset:** "If I misspell 'Pikachu' as 'Pikachoo', find it anyway"

**Scenario:** Common misspellings

**Steps:**
1. Search: `Pikachoo` (double-o typo)
2. Observe results

**Expected Behavior:**
- EITHER: Returns results (fuzzy search)
- OR: Shows "No cards found" with suggestion

**Pass Criteria:**
- ⚠️ Fuzzy search not required for MVP
- ✅ Error message is helpful, not cryptic
- ✅ Doesn't crash on typo
- ✅ User can correct and re-search easily

**Hostile Questions:**
- "Why didn't it find anything?"
  → Exact match required (fuzzy search is future feature)

**Verdict:** [ ] PASS [ ] PARTIAL [ ] FAIL
**Notes:** _________________________________

---

### TEST 2.2: "Common Cards Are Fast" - Performance Test
**Hostile Mindset:** "Pikachu, Charizard, Mewtwo should be instant"

**Scenario:** Search top 10 most popular cards

**Steps:**
1. Search: `Pikachu` → Time: _____ seconds
2. Search: `Charizard` → Time: _____ seconds
3. Search: `Mewtwo` → Time: _____ seconds
4. Search: `Blastoise` → Time: _____ seconds
5. Search: `Venusaur` → Time: _____ seconds

**Pass Criteria:**
- ✅ All searches complete in <3 seconds
- ✅ No rate limiting errors
- ✅ Results are accurate for each

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 2.3: "Rare Cards Exist" - Obscure Card Search
**Hostile Mindset:** "What if I search for a promo card or Japanese exclusive?"

**Scenario:** Search uncommon/promo cards

**Steps:**
1. Search: `Ancient Mew` (movie promo)
2. Search: `Prerelease Raichu` (rare error card)
3. Search: `Shining Charizard` (Neo Destiny)

**Expected Result:**
- All cards found (PokemonTCG.io has comprehensive data)
- Pricing may show "No pricing available" (acceptable)
- Images still load

**Pass Criteria:**
- ✅ Rare cards are found in API
- ✅ No crashes if pricing missing
- ✅ "No Pricing Available" section displays gracefully

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 2.4: "Special Characters in Names" - Unicode Test
**Hostile Mindset:** "Pokémon has accents. Your search better handle é"

**Scenario:** Cards with special characters

**Steps:**
1. Search: `Flabébé` (French accent)
2. Search: `Nidoran♀` (female symbol)
3. Search: `Ho-Oh` (hyphen)

**Expected Result:**
- Either: Accepts accents/symbols and finds card
- OR: Strips special chars and finds close match

**Pass Criteria:**
- ✅ No crashes on special characters
- ✅ Either exact or approximate match works
- ✅ Input field accepts Unicode

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 2.5: "Set Disambiguation" - Multiple Sets with Same Card
**Hostile Mindset:** "There are 20 different Pikachu #25 cards. Help me find the right one."

**Scenario:** Search ambiguous card

**Steps:**
1. Search: `Pikachu` (no number)
2. Count results in match selection sheet
3. Verify set names are CLEARLY visible
4. Verify set names are DIFFERENT for each result

**Pass Criteria:**
- ✅ 20+ results displayed (Pikachu is common)
- ✅ Set name is PROMINENT (not tiny text)
- ✅ Each result shows DIFFERENT set
- ✅ User can distinguish cards easily

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 2.6: "Network Timeout Handling" - Slow Connection
**Hostile Mindset:** "I'm on crappy WiFi at a card show. Don't freeze on me."

**Scenario:** Simulate slow network (if possible via Mac Network Link Conditioner)

**Steps:**
1. Enable 3G speed simulation (slow network)
2. Search: `Charizard`
3. Observe behavior during long load

**Expected Behavior:**
- Loading indicator remains visible
- Doesn't timeout immediately (<30s)
- User can cancel search (optional)
- Error message if API fails after timeout

**Pass Criteria:**
- ✅ Doesn't freeze UI during wait
- ✅ Loading indicator stays active
- ✅ Eventually succeeds or shows error
- ⚠️ Cancel button nice-to-have

**Verdict:** [ ] PASS [ ] PARTIAL [ ] FAIL
**Notes:** _________________________________

---

### TEST 2.7: "API Rate Limiting" - Rapid Search Spam
**Hostile Mindset:** "What if I search 10 times in 10 seconds?"

**Scenario:** Stress test API limits

**Steps:**
1. Search: `Pikachu` → Wait for results → New Lookup
2. Search: `Charizard` → Wait → New Lookup
3. Search: `Mewtwo` → Wait → New Lookup
4. Repeat 10 times rapidly

**Expected Behavior:**
- All searches succeed (PokemonTCG.io has generous limits)
- OR rate limit error displays gracefully

**Pass Criteria:**
- ✅ No crashes
- ✅ If rate limited, shows clear error
- ✅ User can retry after cooldown

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 2.8: "Copy-Paste Workflow" - Real User Flow
**Hostile Mindset:** "I want to look up 5 cards and copy all prices to Excel"

**Scenario:** Multi-card lookup session

**Steps:**
1. Search Card 1 → Copy prices → New Lookup
2. Search Card 2 → Copy prices → New Lookup
3. Search Card 3 → Copy prices → New Lookup
4. Verify clipboard updates each time
5. Paste all 3 into Notes (separated)

**Pass Criteria:**
- ✅ Clipboard updates on each copy
- ✅ Previous prices are overwritten (expected)
- ✅ Format is consistent across all 3
- ✅ No crashes during rapid workflow

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

## Category 3: Edge Case Torture Tests (7 tests)

### TEST 3.1: "Empty Input Fields" - Validation Test
**Hostile Mindset:** "What if I tap 'Look Up Price' with nothing entered?"

**Scenario:** Submit empty form

**Steps:**
1. Leave Card Name EMPTY
2. Leave Card Number EMPTY
3. Tap "Look Up Price"

**Expected Behavior:**
- Button is DISABLED (grayed out)
- OR shows error: "Enter card name to search"
- Does NOT make API call

**Pass Criteria:**
- ✅ Empty search is prevented
- ✅ Clear feedback why button disabled
- ✅ No wasted API calls

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 3.2: "SQL Injection Attempt" - Security Test
**Hostile Mindset:** "Let me try to break your database"

**Scenario:** Enter malicious input

**Steps:**
1. Card Name: `' OR '1'='1`
2. Card Number: `'; DROP TABLE cards; --`
3. Tap "Look Up Price"

**Expected Behavior:**
- Treats input as literal string (no SQL execution)
- API safely handles malicious input
- Returns "No cards found" or similar
- No crashes, no security issues

**Pass Criteria:**
- ✅ No crashes
- ✅ No data corruption
- ✅ Safe API handling (PokemonTCG.io handles this)

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 3.3: "Ultra-Long Card Name" - Input Limits
**Hostile Mindset:** "What if I paste 1000 characters into the name field?"

**Scenario:** Test input field limits

**Steps:**
1. Paste 500-character string into Card Name field
2. Observe behavior
3. Attempt search

**Expected Behavior:**
- Field truncates at reasonable limit (e.g., 100 chars)
- OR allows long input but API safely handles
- OR shows character counter/limit

**Pass Criteria:**
- ✅ No crashes
- ✅ UI doesn't break (text wraps or scrolls)
- ✅ API call succeeds or fails gracefully

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 3.4: "Unicode and Emoji in Search" - Character Encoding Test
**Hostile Mindset:** "What if I type 🔥💧⚡ instead of Fire/Water/Electric?"

**Scenario:** Emoji and unusual characters

**Steps:**
1. Card Name: `Pikachu 😊⚡🔥`
2. Tap "Look Up Price"

**Expected Behavior:**
- Either: API strips emoji and searches "Pikachu"
- OR: Returns "No cards found"
- Does NOT crash

**Pass Criteria:**
- ✅ No crashes
- ✅ Handles non-ASCII gracefully
- ✅ Error message (if any) is helpful

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 3.5: "Rapid Search Spam" - State Management Stress
**Hostile Mindset:** "What if I type, delete, type, delete 100 times?"

**Scenario:** Spam input fields rapidly

**Steps:**
1. Type in Card Name: `Pikachu`
2. Delete all
3. Type: `Charizard`
4. Delete all
5. Repeat 20 times as fast as possible
6. Then do a real search: `Mewtwo`

**Pass Criteria:**
- ✅ No lag or frozen UI
- ✅ Final search executes correctly
- ✅ No leftover state from spam typing

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 3.6: "Mid-Search Cancellation" - Task Cancellation Test
**Hostile Mindset:** "If I start a search and immediately tap 'New Lookup', don't crash"

**Scenario:** Cancel in-flight request

**Steps:**
1. Card Name: `Pikachu`
2. Tap "Look Up Price"
3. IMMEDIATELY tap "New Lookup" (before results load)
4. Observe behavior

**Expected Behavior:**
- Previous search is cancelled
- Loading indicator disappears
- Fields reset
- No error alerts

**Pass Criteria:**
- ✅ No crashes
- ✅ Task cancels cleanly (.task modifier auto-cancels)
- ✅ UI resets properly

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 3.7: "Back-to-Back Identical Searches" - Caching Test
**Hostile Mindset:** "If I search 'Pikachu' twice, is it smart enough to cache?"

**Scenario:** Repeat same search

**Steps:**
1. Search: `Pikachu` → Wait for results
2. Tap "New Lookup"
3. Search: `Pikachu` again → Time it

**Expected Behavior:**
- Second search should be fast (API may cache)
- OR takes same time (no client-side cache, acceptable)

**Pass Criteria:**
- ✅ Second search works correctly
- ⚠️ Caching not required for MVP
- ✅ No stale data issues

**Verdict:** [ ] PASS [ ] PARTIAL [ ] FAIL
**Notes:** _________________________________

---

## Category 4: UI/UX Hostility (6 tests)

### TEST 4.1: "Keyboard Behavior" - Input Flow Test
**Hostile Mindset:** "Keyboard better appear when I tap, and GTFO when I'm done"

**Scenario:** Keyboard lifecycle

**Steps:**
1. Tap Card Name field
2. Verify keyboard appears
3. Verify "Done" button in toolbar (thunder yellow)
4. Type "Pikachu" and press Return/Search
5. Verify keyboard dismisses
6. Tap Card Number field
7. Verify keyboard appears again
8. Tap "Done" in toolbar
9. Verify keyboard dismisses

**Pass Criteria:**
- ✅ Keyboard appears instantly on field tap
- ✅ Thunder yellow "Done" button visible
- ✅ Return key labeled "Search" on name field
- ✅ Return key labeled "Done" on number field
- ✅ Keyboard dismisses on Return/Done
- ✅ @FocusState manages focus correctly

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 4.2: "Match Selection Sheet Usability" - Sheet UX Test
**Hostile Mindset:** "If there are 50 results, I better be able to find the right one"

**Scenario:** Navigate large result set

**Steps:**
1. Search: `Pikachu` (should yield 20+ results)
2. Match selection sheet appears
3. Scroll through results
4. Verify images, names, set names are readable
5. Tap a result in the middle of the list
6. Verify it loads that specific card

**Pass Criteria:**
- ✅ Sheet scrolls smoothly
- ✅ All images load (not just first 5)
- ✅ Card name is PROMINENT (heading4)
- ✅ Set name distinguishes cards clearly
- ✅ Tapping ANY card works

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 4.3: "Image Loading Performance" - AsyncImage Test
**Hostile Mindset:** "If images take forever to load, I'm uninstalling"

**Scenario:** Image loading speed

**Steps:**
1. Search any card with image
2. Observe 300pt large image loading
3. Time from API response to image visible

**Expected Result:**
- Image loads in <2 seconds (on good network)
- Shows placeholder while loading (not blank)
- Smooth fade-in when loaded

**Pass Criteria:**
- ✅ Placeholder prevents layout shift
- ✅ Image loads reasonably fast
- ✅ Smooth transition (not jarring pop)

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 4.4: "Small Screen Layout" - iPhone SE Test
**Hostile Mindset:** "Not everyone has a Pro Max"

**Scenario:** Test on iPhone SE (smallest supported device)

**Steps:**
1. Switch simulator to iPhone SE (3rd gen)
2. Navigate to Scan tab
3. Perform search
4. View pricing results

**Expected Behavior:**
- All input fields visible without scrolling
- Match selection sheet displays properly
- Pricing grid adapts (may stack vertically)
- Buttons not cut off

**Pass Criteria:**
- ✅ Layout adapts to small screen
- ✅ No horizontal scrolling required
- ✅ Text not truncated
- ✅ All features functional

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/scan_4.4_iphone_se.png`
**Notes:** _________________________________

---

### TEST 4.5: "Landscape Mode" - Rotation Test
**Hostile Mindset:** "I hold my phone sideways, deal with it"

**Scenario:** Rotate to landscape

**Steps:**
1. Open Scan tab (portrait)
2. Rotate simulator to landscape (Cmd+Left/Right)
3. Verify layout

**Expected Behavior:**
- EITHER: Layout adapts gracefully
- OR: Locks to portrait (acceptable for MVP)

**Pass Criteria:**
- ✅ If landscape supported, layout doesn't break
- ⚠️ If locked to portrait, no crashes

**Verdict:** [ ] PASS [ ] PARTIAL [ ] FAIL
**Notes:** _________________________________

---

### TEST 4.6: "VoiceOver Support" - Accessibility Test
**Hostile Mindset:** "If VoiceOver doesn't work, you're excluding blind users"

**Scenario:** Enable VoiceOver

**Steps:**
1. Enable VoiceOver (Settings → Accessibility)
2. Navigate to Scan tab
3. Swipe through elements

**Expected Result:**
- All fields have labels ("Card name text field")
- Button has label ("Look up price button")
- Results are announced
- Pricing values are read aloud

**Pass Criteria:**
- ✅ Every element has accessibilityLabel
- ✅ Input fields announce current value
- ✅ Results are navigable with swipes

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

## Category 5: API/Network Skepticism (6 tests)

### TEST 5.1: "No Internet Connection" - Offline Test
**Hostile Mindset:** "What happens if I'm in airplane mode?"

**Scenario:** Disable WiFi

**Steps:**
1. Turn on Airplane Mode
2. Attempt search: `Pikachu`
3. Observe error handling

**Expected Result:**
- Error message: "No internet connection" or similar
- Error section displays (not cryptic)
- Retry option available
- No crashes

**Pass Criteria:**
- ✅ Detects offline state
- ✅ Error message is user-friendly
- ✅ "Dismiss" button clears error
- ✅ Can retry after reconnecting

**Verdict:** [ ] PASS [ ] FAIL
**Screenshot:** `/tmp/scan_5.1_offline.png`
**Notes:** _________________________________

---

### TEST 5.2: "Slow Network Simulation" - Performance Under Stress
**Hostile Mindset:** "I'm on 3G at a card show basement. Don't timeout instantly."

**Scenario:** Enable slow network (Mac Network Link Conditioner)

**Steps:**
1. Enable "3G" or "Very Bad Network" profile
2. Search: `Charizard`
3. Observe behavior

**Expected Behavior:**
- Loading indicator stays visible
- Doesn't timeout for at least 30 seconds
- Eventually succeeds or shows timeout error

**Pass Criteria:**
- ✅ Waits reasonably long before timeout
- ✅ UI remains responsive during wait
- ✅ Error message if timeout occurs

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 5.3: "Invalid API Response" - Malformed Data Handling
**Hostile Mindset:** "What if the API returns garbage?"

**Scenario:** (Difficult to test without mock server)

**Expected Behavior:**
- App gracefully handles JSON parsing errors
- Shows "Failed to load data" or similar
- No crashes on unexpected response

**Pass Criteria:**
- ✅ do/try/catch handles errors
- ✅ User sees helpful error (not stack trace)

**Verdict:** [ ] PASS [ ] PARTIAL [ ] FAIL
**Notes:** _________________________________

---

### TEST 5.4: "404 / Card Not Found" - Missing Card Handling
**Hostile Mindset:** "What if the card doesn't exist in the API?"

**Scenario:** Search non-existent card

**Steps:**
1. Card Name: `ZZZInvalidCardName999`
2. Tap "Look Up Price"

**Expected Result:**
- Error: "No cards found matching 'ZZZInvalidCardName999'"
- Error section displays
- "Dismiss" button clears error

**Pass Criteria:**
- ✅ Clear error message
- ✅ No crashes
- ✅ User can try new search

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 5.5: "Partial Data Handling" - Card with Missing Pricing
**Hostile Mindset:** "What if TCGPlayer has no price data for this card?"

**Scenario:** Search card with no pricing

**Steps:**
1. Search obscure promo card (e.g., `Ancient Mew`)
2. View results

**Expected Behavior:**
- Card details section displays
- Pricing section shows: "No Pricing Available"
- Gray info icon + message
- No crashes

**Pass Criteria:**
- ✅ Handles missing pricing gracefully
- ✅ "No Pricing Available" section displays
- ✅ User can still see card image/details
- ✅ Can copy (empty pricing is valid)

**Verdict:** [ ] PASS [ ] FAIL
**Notes:** _________________________________

---

### TEST 5.6: "API 500 Error" - Server Failure Handling
**Hostile Mindset:** "PokemonTCG.io might go down. Handle it."

**Scenario:** (Difficult to test without forcing error)

**Expected Behavior:**
- Error: "Service unavailable. Try again later."
- No crashes
- Retry option

**Pass Criteria:**
- ✅ Error handling catches 500 responses
- ✅ User-friendly error message

**Verdict:** [ ] PASS [ ] PARTIAL [ ] FAIL
**Notes:** _________________________________

---

## Scoring Rubric

**Category 1: Basic Functionality (24 points)**
- 8 tests × 3 points each
- Deduct 1 point for minor issues, 3 points for failures

**Category 2: Real-World Scenarios (24 points)**
- 8 tests × 3 points each

**Category 3: Edge Cases (14 points)**
- 7 tests × 2 points each

**Category 4: UI/UX (12 points)**
- 6 tests × 2 points each

**Category 5: API/Network (12 points)**
- 6 tests × 2 points each

**Bonus Points (Up to +10):**
- Exceptional error handling
- Delightful animations
- Above-and-beyond UX

**Penalties (Down to -10):**
- Crashes (-5 each)
- Data loss (-5 each)
- Security issues (-10)

**TOTAL: 100 points possible (86 base + 10 bonus - 10 penalty max)**

---

## Grade Scale

| Grade | Score | Meaning | Action |
|-------|-------|---------|--------|
| **A+** | 95-100 | Perfect, delightful | ✅ Ship now, celebrate |
| **A** | 90-94 | Excellent, minor polish | ✅ Ship with confidence |
| **B** | 80-89 | Good, some issues | ✅ Ship with notes |
| **C** | 70-79 | Functional but flawed | ⚠️ Fix P0/P1, then ship |
| **D** | 60-69 | Major problems | ❌ Major rework needed |
| **F** | <60 | Broken | ❌ Start over |

---

## Post-Testing Actions

**If Grade ≥ B:**
1. Mark F001 as passing in FEATURES.json
2. Create SCAN_FEATURE_TEST_RESULTS.md
3. Update PROGRESS.md with completion
4. Commit: `verify: Scan Feature hostile testing complete (Grade: [X])`

**If Grade = C:**
1. Document all failures
2. Create bug tickets for P0/P1 issues
3. Keep F001: passes = false
4. Fix issues, re-test

**If Grade < C:**
1. Major redesign required
2. Focus on most critical failures first

---

## Test Execution Template

**Tester Name:** _________________
**Date Started:** _________________
**Date Completed:** _________________
**Total Time:** _________ minutes

**Environment:**
- Simulator: iPhone 16 / iOS 18.5
- Build: CardShowPro (latest)
- Commit: ____________

**Overall Impression:**
_________________________________________________________
_________________________________________________________

**Would you use this feature?** [ ] YES [ ] NO

**Final Grade:** _____

---

*This testing plan represents a hostile, skeptical user who actively looks for problems. Success means the Scan feature survives all 35 brutal tests with grace.*
