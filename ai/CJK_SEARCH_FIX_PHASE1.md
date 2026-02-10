# Phase 1: Japanese and Chinese Card Search Fix

**Status**: ✅ IMPLEMENTED AND COMPILED SUCCESSFULLY

## Problem Summary

Japanese and Chinese cards weren't working in the scan flow, even though OCR detected the language correctly. Search was returning no results.

## Root Causes Identified

1. **Bundled Database Has Broken Normalization** - Python script destroys CJK characters during normalization (converts "ブルバサウルス" → "")
2. **DatabaseImporter Always Sets English** - Missing language detection logic
3. **Search Flow Tries Exact Match First** - Fails for CJK because `name_normalized` is empty

## Phase 1 Implementation (COMPLETED)

### Changes Made

#### 1. LocalCardDatabase.swift (Lines 237-310)

**Added `hasCJKCharacters()` helper:**
```swift
private func hasCJKCharacters(_ text: String) -> Bool {
    for scalar in text.unicodeScalars {
        if (0x3040...0x309F).contains(scalar.value) || // Hiragana
           (0x30A0...0x30FF).contains(scalar.value) || // Katakana
           (0x4E00...0x9FFF).contains(scalar.value) {  // CJK Unified Ideographs
            return true
        }
    }
    return false
}
```

**Modified `search()` method:**
- Detects if query contains CJK characters
- Skips exact match for CJK queries (won't work with broken normalization)
- Goes straight to FTS5 search (works with original names)
- Adds logging to show CJK detection status

#### 2. DatabaseImporter.swift (Lines 223-272)

**Added `detectLanguage()` method:**
```swift
private func detectLanguage(cardID: String, cardName: String) -> CardLanguage {
    // Check ID prefix first (most reliable)
    if cardID.hasPrefix("ja_") || cardID.hasPrefix("jp_") {
        return .japanese
    }
    if cardID.hasPrefix("zh-tw_") || cardID.hasPrefix("tc_") ||
       cardID.hasPrefix("zh-cn_") || cardID.hasPrefix("sc_") {
        return .chineseTraditional
    }
    // ... (French, German, Spanish, Italian, Portuguese)

    // Check name for CJK characters
    for scalar in cardName.unicodeScalars {
        if (0x3040...0x309F).contains(scalar.value) ||
           (0x30A0...0x30FF).contains(scalar.value) {
            return .japanese
        }
        if (0x4E00...0x9FFF).contains(scalar.value) {
            return .chineseTraditional
        }
    }

    return .english
}
```

**Updated `convertToLocalCard()`:**
- Calls `detectLanguage()` for each imported card
- Explicitly sets `language` parameter (fixes default-to-English bug)
- Explicitly sets `source: .pokemontcg` parameter

### Language Enum Constraints

The `CardLanguage` enum only supports:
- English (`en`)
- Japanese (`ja`)
- French (`fr`)
- German (`de`)
- Spanish (`es`)
- Italian (`it`)
- Portuguese (`pt`)
- Chinese Traditional (`zh-tw`)

**Note**: Korean cards and Chinese Simplified cards map to English and Traditional Chinese respectively since those enum cases don't exist.

## How This Fixes the Problem

### Before
- ❌ Japanese card "ブルバサウルス" → Exact match on empty `name_normalized` → No results
- ❌ All imported cards marked as English → Language filter excludes Japanese/Chinese cards

### After
- ✅ Japanese card "ブルバサウルス" → Detects CJK → Skips exact match → FTS5 searches original `name` → Finds matches
- ✅ Imported cards detected as Japanese/Chinese → Language filter includes them correctly

## Expected Results

| Test Case | Before | After |
|-----------|--------|-------|
| English card "Charizard" | ✅ Fast (<500ms) | ✅ Fast (<500ms) |
| Japanese card "リザードン" | ❌ No results | ✅ Fast (<500ms) |
| Chinese card "小火龍" | ❌ No results | ✅ Fast (<500ms) |

## Testing Instructions

1. **Build and run app** ✅ (Done - Build succeeded)

2. **Test with Japanese card:**
   - Scan a Japanese Pokémon card (e.g., リザードン)
   - Check console logs for:
     ```
     Searching for 'リザードン' (language: ja, isCJK: true)
     Skipping exact match for CJK query (using FTS5 only)
     FTS search found X results in Yms
     ```
   - Card should appear in <500ms

3. **Test with Chinese card:**
   - Scan a Chinese Pokémon card
   - Should see similar log messages
   - Results should appear fast

4. **Verify no regression on English:**
   - Scan an English card
   - Console should show "isCJK: false"
   - Should use exact match first (faster path)
   - Still fast (<500ms)

## Console Log Examples

**English card (no change):**
```
Searching for 'charizard' (language: en, isCJK: false)
Exact search found 8 results in 4.2ms
```

**Japanese card (now works):**
```
Searching for 'リザードン' (language: ja, isCJK: true)
Skipping exact match for CJK query (using FTS5 only)
FTS search found 12 results in 18.5ms
```

## Next Steps

### Phase 2 (Later): Fix Database Builder
Update `tools/build_pokemon_db.py` to preserve CJK characters in normalization:
- Check if name contains CJK characters
- If CJK: lowercase only, preserve characters
- If English: remove diacritics, convert to ASCII

### Phase 3 (Optional): Improve FTS5 Tokenization
- Add n-gram tokenization for better CJK partial matching
- Consider ICU tokenizer for better Japanese segmentation
- Language-specific search ranking

## Files Modified

1. `/CardShowProPackage/Sources/CardShowProFeature/Services/LocalCardDatabase.swift`
2. `/CardShowProPackage/Sources/CardShowProFeature/Services/DatabaseImporter.swift`

## Build Status

✅ Compiled successfully with warnings (unrelated to changes)
✅ Ready for testing on simulator/device
