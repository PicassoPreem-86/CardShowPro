# Pro Market Agent API Research Report
**Date:** January 13, 2026
**Purpose:** Identify viable APIs for market data and sold listings to power price trends and market insights

---

## Executive Summary

### Critical Finding: eBay Sold Listings Access is Restricted

**The biggest challenge for building Pro Market Agent is that eBay has ELIMINATED free access to sold listings data:**

- **eBay Finding API** (which had `findCompletedItems`) was deprecated January 2024 and will be **decommissioned February 5, 2025**
- **eBay Browse API** (replacement) only shows **active listings** - NO sold/completed items
- **eBay Marketplace Insights API** (Terapeak) provides sold data but is **restricted to approved enterprise partners only**
- Applications for Marketplace Insights access are being **consistently denied** by eBay

### MVP Recommendation: START WITH TRADING CARD GAME (TCG) DATA ONLY

For a V3 MVP launch, we recommend focusing on **TCG price data** (Pokemon, MTG, Yu-Gi-Oh) using free/affordable APIs, then exploring sports card data through paid scrapers or partnerships later.

**Why this approach:**
1. Multiple free/low-cost APIs available for TCG data with historical pricing
2. Can build and validate core "Pro Market Agent" features without expensive data subscriptions
3. TCG market has strong price volatility and trend data for meaningful insights
4. Can add sports cards in V4 once revenue justifies paid data sources

---

## API Comparison Matrix

| API Provider | Card Types | Free Tier | Historical Data | Data Update Frequency | Cost for 1K Requests |
|--------------|-----------|-----------|-----------------|----------------------|---------------------|
| **PokemonPriceTracker** | Pokemon only | 100 calls/day | 90+ days (daily) | Daily | $0 (free) / $9.99/mo (20K/day) |
| **JustTCG** | MTG, Pokemon, Yu-Gi-Oh, Lorcana, One Piece, Digimon | 1,000 calls/month | 180 days | Every 6 hours | $0 (free tier) |
| **CardMarket API** | Pokemon, Lorcana, One Piece (coming) | 100 req/day | 30d & 7d averages | Real-time | $0 (free) / $9.90/mo (3K/day) |
| **Scryfall** | MTG only | Unlimited (10 req/sec) | None (current only) | Daily | $0 (always free) |
| **TCGCSV** | All TCG via TCGPlayer | Unlimited downloads | None (snapshots) | Daily at 20:00 UTC | $0 (free CSV/JSON) |
| **TCGPlayer Official** | All TCG | NO NEW ACCESS | Current prices only | Real-time | N/A (not accepting new developers) |
| **PSA Public API** | All graded cards | 100 calls/day | Via Auction Prices | Various | $0 (free tier) |
| **eBay Browse API** | All items | 5,000 calls/day | ❌ NONE (active only) | Real-time | $0 (free) |
| **eBay Marketplace Insights** | All items | ❌ NO ACCESS | Full sold history | Real-time | ❌ Enterprise only |
| **SerpApi (eBay scraper)** | All items | 250 searches/mo | Via sold filter | Real-time | $0.025 per search ($25 for 1K) |
| **RapidAPI eBay Avg Price** | All items | Unknown | Sold listings | Real-time | Unknown (requires account) |
| **Apify eBay Sold Scraper** | All items | $5 free credits/mo | Sold listings | On-demand | ~$0.63 per 1K items |
| **StockX API** | Sneakers, Cards, Collectibles | ❌ NO ACCESS | Full market data | Real-time | Must apply (approval required) |
| **Card Ladder** | Sports & TCG | ❌ NO PUBLIC API | 100M+ sales history | Real-time | Enterprise only (contact for access) |
| **Card Hedger** | Sports & TCG | Unknown | Unknown | Unknown | Unknown (contact required) |

---

## Detailed API Analysis

### 1. PokemonPriceTracker API ⭐ **RECOMMENDED FOR POKEMON MVP**

**Website:** https://www.pokemonpricetracker.com/pokemon-card-price-api

#### Pricing
- **Free Tier:** 100 API calls/day, basic price data, community support
- **Standard:** $9.99/month, 20,000 calls/day, full data from all sources, historical price data, email support
- **Business:** $99/month, 200,000 calls/day, advanced filtering, bulk operations, commercial licensing

#### Data Coverage
- 23,000+ Pokemon cards (English & Japanese)
- TCGPlayer prices
- eBay sold prices (PSA 8, 9, 10)
- CardMarket prices
- PSA population data

#### Historical Data
- **1+ years** of historical data available
- **90+ days** with daily granularity
- Daily price updates
- Volatility metrics and trend indicators

#### Use Cases for Pro Market Agent
✅ "Charizard PSA 10 prices up 15% this week"
✅ "Recent sold listings at $X, $Y, $Z"
✅ Price trend charts (90-day view)
⚠️ Seasonal trends require 12+ months (paid tier)

#### Verdict
**EXCELLENT for Pokemon MVP.** Free tier sufficient for testing, paid tier needed for production.

---

### 2. JustTCG API ⭐ **RECOMMENDED FOR MULTI-GAME TCG**

**Website:** https://justtcg.com/

#### Pricing
- **Free Tier:** 1,000 API calls/month, no credit card required
- **Paid Tiers:** Available but not detailed on website

#### Data Coverage
- Magic: The Gathering (100K+ cards)
- Pokemon TCG (20K+ cards)
- Yu-Gi-Oh! (35K+ cards)
- Disney Lorcana (1K+ cards)
- One Piece TCG (5K+ cards)
- Digimon TCG (4K+ cards)

#### Historical Data
- **180 days** of historical data
- Currently collecting daily pricing
- 30d and 90d access noted as "coming soon"
- Prices updated **every 6 hours**

#### Features
- 100% TCG-focused (no sports cards)
- Condition-specific pricing
- Metagame-influenced data
- Detailed historical data for pro traders

#### Use Cases for Pro Market Agent
✅ Multi-game support (biggest advantage over Pokemon-only APIs)
✅ "Black Lotus trending up 5% this month"
✅ Price comparison across TCGs
✅ 6-hour update frequency (better than daily)

#### Verdict
**BEST for multi-TCG support.** Free tier allows 33 calls/day (1000/month), sufficient for MVP testing.

---

### 3. CardMarket API ⭐ **RECOMMENDED FOR EU MARKET DATA**

**Website:** http://cardmarket-api.com/

#### Pricing
- **Basic (Free):** 100 requests/day, 30 req/minute, all endpoints
- **Pro:** $9.90/month, 3,000 requests/day, 300 req/minute
- **Ultra:** $24.90/month, 15,000 requests/day, 300 req/minute
- **Mega:** $49.50/month, 50,000 requests/day, 600 req/minute

#### Data Coverage
- Pokemon (primary focus)
- Disney Lorcana
- Riftbound (coming soon)
- One Piece (coming soon)
- Multiple European countries (DE, FR, ES, IT)

#### Historical Data
- **30-day average** pricing
- **7-day average** pricing
- Price history data for trend identification and market prediction

#### Data Sources
- Cardmarket (EU pricing)
- TCGPlayer (US pricing)
- Combined global market view

#### Use Cases for Pro Market Agent
✅ Global price comparison (EU vs US markets)
✅ "This card is 20% cheaper in Europe"
✅ 7d/30d trend analysis
⚠️ Limited to 100 requests/day on free tier

#### Verdict
**EXCELLENT for global market insights.** Free tier viable for MVP if request volume is low (<100/day).

---

### 4. Scryfall API (Magic: The Gathering Only)

**Website:** https://scryfall.com/docs/api

#### Pricing
- **Always FREE**
- Rate limit: 50-100ms between requests (~10 req/sec)
- Unlimited bulk data downloads

#### Data Coverage
- MTG cards ONLY
- Comprehensive card database
- Card images and artwork
- Current prices from TCGPlayer

#### Historical Data
- ❌ **NONE** - current prices only
- Prices updated daily
- Bulk data snapshots available

#### Use Cases for Pro Market Agent
✅ Current MTG card prices
✅ Card identification and metadata
❌ No price trends or historical data
❌ No sold listings data

#### Verdict
**GOOD for card identification, BAD for Pro Market Agent.** No historical data means no trend analysis.

---

### 5. TCGCSV (Free TCG Data Dumps)

**Website:** https://tcgcsv.com/

#### Pricing
- **100% FREE**
- Unlimited CSV/JSON downloads
- No API - direct file downloads

#### Data Coverage
- All TCGPlayer categories
- Pokemon (categoryId: 3)
- Magic: The Gathering
- Yu-Gi-Oh!
- All other TCGs on TCGPlayer

#### Historical Data
- ❌ **NONE** - daily snapshots only
- Updated daily at 20:00 UTC
- Can manually track changes by downloading daily

#### Data Format
- CSV files
- JSON data files
- GitHub repository access
- 4 data tiers: Categories, Groups, Products, Pricing

#### Use Cases for Pro Market Agent
✅ Free baseline price data
⚠️ Manual work required for historical tracking
❌ No real-time updates
❌ No sold listings

#### Verdict
**USEFUL for backup data source.** Not suitable as primary API due to lack of historical tracking.

---

### 6. PSA Public API (Graded Cards)

**Website:** https://www.psacard.com/publicapi

#### Pricing
- **Free:** 100 API calls/day (requires PSA account)
- OAuth 2 authentication required

#### Data Coverage
- PSA graded cards only
- Population reports (card counts by grade)
- Auction prices from eBay, Goldin, etc.
- Over 5 million auction results

#### Historical Data
- ✅ Via **Auction Prices Realized** feature
- Free web tool: www.PSAcard.com/AuctionPrices
- API access to historical auction data

#### Use Cases for Pro Market Agent
✅ "PSA 10 population increased by 50 this month"
✅ Graded card market trends
✅ Investment-grade insights
⚠️ Only covers graded cards (subset of market)

#### Verdict
**VALUABLE for graded card segment.** Complement to raw card pricing APIs. 100 calls/day sufficient for MVP.

---

### 7. eBay Browse API ❌ **NOT VIABLE**

**Website:** https://developer.ebay.com/api-docs/buy/browse

#### Pricing
- **Free:** 5,000 calls/day
- Can request increase after Application Growth Check

#### Data Coverage
- All eBay items
- Active listings only
- Current prices, bids, watch counts

#### Historical Data
- ❌ **NONE** - Finding API `findCompletedItems` was deprecated
- ❌ **NO SOLD LISTINGS** - Browse API doesn't support completed items
- Marketplace Insights API (sold data) restricted to enterprise partners

#### Verdict
**USELESS for Pro Market Agent.** Only shows active listings. Sold data requires Marketplace Insights API which is NOT available to regular developers.

---

### 8. eBay Marketplace Insights API ❌ **NO ACCESS**

**Official:** Part of eBay Buy API (Terapeak data)

#### Access Requirements
- ❌ **Application required** - consistently DENIED
- ❌ **Limited to approved partners** only (like Terapeak)
- ❌ **Not available to regular developers**

#### What It Would Provide (If Accessible)
- Historical sold listings
- Market research data
- Average selling prices
- Sales velocity

#### Verdict
**INACCESSIBLE.** eBay has locked this behind enterprise partnership requirements.

---

### 9. SerpApi (eBay Scraper) 💰 **PAID OPTION**

**Website:** https://serpapi.com/ebay-search-api
**Pricing:** https://serpapi.com/pricing

#### Pricing
- **Free:** 250 searches/month
- **Starter:** $25/month (1,000 searches)
- **Developer:** $75/month (5,000 searches)
- **Production:** $150/month (15,000 searches)
- **Big Data:** $275/month (30,000 searches)

**Cost per 1K requests:** $25

#### Data Coverage
- All eBay items
- Can filter for "Sold" items
- Returns scraped eBay search results

#### Use Cases for Pro Market Agent
✅ Access to sold listings data
✅ Real-time eBay market data
⚠️ Costs $25 per 1,000 searches (expensive for frequent lookups)
⚠️ Scraping-based (less reliable than official API)

#### Verdict
**VIABLE but EXPENSIVE.** At 1 search per card lookup, 1,000 users = $25/month. Could work for V4 with revenue.

---

### 10. RapidAPI eBay Average Selling Price 💰 **UNKNOWN COST**

**Website:** https://rapidapi.com/ecommet/api/ebay-average-selling-price

#### Pricing
- ❌ **Unknown** - requires RapidAPI account to view pricing
- RapidAPI typically offers free tiers with limits

#### Data Coverage
- eBay sold listings
- Average, minimum, maximum prices
- Individual listing details
- Automatic captcha solving

#### Features
- Search recently sold items
- Filter by keywords, category, aspects
- Returns up to 60, 120, or 240 results

#### Use Cases for Pro Market Agent
✅ Average selling prices (key metric)
✅ Min/max price ranges
✅ Recent sold listings
⚠️ Cost unknown (need to test)

#### Verdict
**POTENTIALLY VIABLE.** Need to create account and test free tier limits and paid pricing.

---

### 11. Apify eBay Sold Listings Scraper 💰 **PAID OPTION**

**Website:** https://apify.com/marielise.dev/ebay-sold-listings-intelligence

#### Pricing
- **Free:** $5 credits/month (Apify Free plan)
- **Cost:** ~$0.63 per 1,000 items scraped
- Pay-per-result model

#### Data Coverage
- eBay sold listings
- Price research tool
- On-demand scraping

#### Use Cases for Pro Market Agent
✅ Affordable sold listings access
✅ $0.63 per 1K items = very reasonable
✅ $5 free credits = ~8,000 items/month free
⚠️ Scraping-based (less reliable than API)

#### Verdict
**MOST AFFORDABLE scraper option.** $0.63 per 1K vs $25 per 1K for SerpApi. Good for V4 sports card data.

---

### 12. StockX API ❌ **NO ACCESS**

**Website:** https://developer.stockx.com/

#### Access Requirements
- ❌ Must apply for API access
- ❌ Must be accepted into affiliate program
- ❌ Approval process required

#### Data Coverage (If Accessible)
- Sneakers
- Trading cards
- Collectibles
- Historical sales data
- Market analytics

#### Verdict
**REQUIRES APPLICATION.** May be viable in future but cannot rely on for V3 MVP.

---

### 13. Card Ladder ❌ **ENTERPRISE ONLY**

**Website:** https://cardladder.com/

#### Access Requirements
- ❌ **Enterprise API** - must contact for access
- No public developer API

#### Data Coverage (If Accessible)
- 100M+ historical sales
- Sports cards & TCG
- eBay, Goldin, Heritage, Fanatics data
- PSA, BGS, SGC, CGC population reports

#### Verdict
**ENTERPRISE ONLY.** Not viable for MVP. Could explore partnership for V4+ if revenue justifies cost.

---

### 14. Card Hedger ❌ **UNKNOWN**

**Website:** https://www.cardhedger.com/price_api_business

#### Access Requirements
- ❌ No public pricing information
- Must contact for API access

#### Data Coverage
- Sports cards
- Pokemon cards
- TCG cards
- "Curated and well structured data"

#### Verdict
**UNKNOWN VIABILITY.** Would need to contact for pricing and access details.

---

## Use Case Validation

### Required Capabilities for Pro Market Agent

| Use Case | Requirement | Best API Options |
|----------|-------------|------------------|
| **"Charizard prices up 15% this week"** | Daily historical prices (7+ days) | ✅ PokemonPriceTracker (90+ days), ✅ JustTCG (180d), ✅ CardMarket (7d) |
| **"Best time to sell based on seasonal trends"** | 12+ months historical data | ✅ PokemonPriceTracker (1+ year), ✅ JustTCG (180d), ⚠️ Manual tracking with TCGCSV |
| **"Recent sold listings at $X, $Y, $Z"** | Sold transaction data | ❌ eBay: SerpApi ($25/1K), Apify ($0.63/1K), RapidAPI (unknown) |
| **"PSA 10 population increased - prices may drop"** | Graded card population data | ✅ PSA Public API (100/day free), ✅ PokemonPriceTracker (includes PSA) |
| **"This card trending in competitive play"** | Real-time metagame data | ✅ JustTCG (metagame-influenced), ⚠️ Would need separate tournament API |
| **"EU market 20% cheaper than US"** | Multi-region pricing | ✅ CardMarket API (Cardmarket + TCGPlayer) |

---

## Cost Projections

### Scenario 1: TCG-Only MVP (V3 Launch)

**Monthly API Costs:**

| API | Tier | Monthly Cost | Calls/Day | Use Case |
|-----|------|--------------|-----------|----------|
| JustTCG | Free | $0 | ~33 calls | Multi-game TCG price lookup |
| PokemonPriceTracker | Free | $0 | 100 calls | Pokemon price trends |
| CardMarket API | Free | $0 | 100 calls | EU market comparison |
| PSA Public API | Free | $0 | 100 calls | Graded card populations |
| **TOTAL** | | **$0/month** | **333+ calls/day** | Covers TCG market data |

**Limitations:**
- No sports card data
- No eBay sold listings
- Limited to ~333 API calls per day total
- Users must stay within free tier limits

**Viability for MVP:** ✅ **YES - Can build Pro Market Agent V3 with FREE APIs for TCG market**

---

### Scenario 2: TCG + Sports Cards (V4 Expansion)

**Monthly API Costs:**

| API | Tier | Monthly Cost | Calls | Use Case |
|-----|------|--------------|-------|----------|
| PokemonPriceTracker | Standard | $9.99 | 20,000/day | Pokemon production tier |
| JustTCG | Paid | ~$20-50 (est.) | Higher limit | Multi-game TCG production |
| Apify eBay Scraper | Pay-per-use | $5-20 | ~8K-32K items | Sports card sold listings |
| SerpApi | Starter | $25 | 1,000/month | Supplemental eBay data |
| **TOTAL** | | **$60-105/month** | **High volume** | Full market coverage |

**Viability for V4:** ✅ **YES - Reasonable cost once app has revenue**

---

### Scenario 3: Enterprise-Grade (V5+)

**Monthly API Costs:**

| API | Tier | Monthly Cost | Use Case |
|-----|------|--------------|----------|
| PokemonPriceTracker | Business | $99 | 200,000/day, commercial license |
| JustTCG | Pro/Business | $100-200 (est.) | High-volume TCG |
| SerpApi | Production | $150 | 15,000 eBay searches/month |
| Card Ladder | Enterprise | $500+ (est.) | 100M+ sales database access |
| **TOTAL** | | **$850-950/month** | Professional-grade market intelligence |

**Viability for V5+:** ⚠️ **DEPENDS ON REVENUE** - Need 200+ paying Pro subscribers to justify cost

---

## Recommendations by Version

### V3 MVP Launch: TCG-ONLY (FREE TIER) ⭐ **RECOMMENDED**

**Strategy:** Launch Pro Market Agent with TCG support only using free APIs

**APIs to Implement:**
1. **JustTCG (Free)** - Primary API for MTG, Pokemon, Yu-Gi-Oh, etc.
2. **PokemonPriceTracker (Free)** - Supplement for Pokemon with 90-day history
3. **CardMarket API (Free)** - EU vs US price comparison
4. **PSA Public API (Free)** - Graded card population data

**Features Enabled:**
- ✅ Price trend analysis (7-180 days)
- ✅ "Card X up/down Y% this week"
- ✅ Historical price charts
- ✅ PSA population tracking
- ✅ Multi-game support (6 TCGs)
- ✅ EU vs US market comparison

**Features Delayed to V4:**
- ❌ Sports cards (basketball, baseball, etc.)
- ❌ eBay sold listings for individual items
- ❌ Real-time market volume data
- ❌ Seasonal trends (>180 days history)

**Marketing Positioning:**
- "Pro Market Agent for Trading Card Games"
- Focus on Pokemon, MTG, Yu-Gi-Oh competitive players
- Emphasize graded card investment intelligence

**Cost:** $0/month (100% free APIs)
**Risk:** Low - All APIs confirmed free with reasonable limits
**Development Time:** 2-3 sprints to implement 4 APIs

---

### V4 Expansion: ADD SPORTS CARDS (PAID TIER)

**Strategy:** Add sports card data once Pro subscriptions generate revenue

**APIs to Add:**
1. **Upgrade PokemonPriceTracker to Standard** ($9.99/mo) - 20K calls/day
2. **Upgrade JustTCG to Paid Tier** (~$20-50/mo est.) - Higher limits
3. **Add Apify eBay Scraper** ($5-20/mo) - Sports card sold listings
4. **Add SerpApi Starter** ($25/mo) - 1,000 eBay searches/month

**New Features Enabled:**
- ✅ Sports cards (basketball, baseball, football, hockey)
- ✅ eBay sold listings analysis
- ✅ "Recent sales at $X, $Y, $Z"
- ✅ Higher API rate limits for production scale

**Cost:** $60-105/month
**Break-Even:** ~15-20 Pro subscribers ($4.99/mo tier)
**Revenue Needed:** $100/month minimum

---

### V5+ Enterprise: FULL MARKET INTELLIGENCE

**Strategy:** Professional-grade market data for power users

**APIs to Add:**
1. **Card Ladder Enterprise API** - 100M+ sales database
2. **SerpApi Production** ($150/mo) - 15K searches/month
3. **Consider Marketplace Insights partnership** - Official eBay data

**New Features Enabled:**
- ✅ Full market history (multi-year)
- ✅ Sales velocity and liquidity metrics
- ✅ Investment-grade analytics
- ✅ Institutional data quality

**Cost:** $850-950/month
**Break-Even:** ~200 Pro subscribers
**Target Audience:** Card shops, dealers, investment firms

---

## Technical Implementation Considerations

### API Request Optimization

**Problem:** Free tiers have strict daily limits (100-333 calls/day total)

**Solutions:**
1. **Aggressive caching:** Cache price data for 6-24 hours
2. **Batch requests:** Request multiple cards in single API call when supported
3. **Smart refresh:** Only update prices when user actively viewing
4. **Background sync:** Refresh popular cards overnight
5. **User-specific limits:** "You have 10 price lookups remaining today"

### Data Freshness Strategy

**Daily Updates:**
- Background sync for user's portfolio/watchlist
- Update during off-peak hours
- Cache results for 24 hours

**Real-Time Updates:**
- Reserve API calls for user-initiated lookups
- Show "Last updated: X hours ago" timestamp
- Offer "Refresh price" button (counts against daily limit)

### Fallback Hierarchy

**If primary API fails or rate-limited:**
1. Try secondary API (e.g., JustTCG → PokemonPriceTracker)
2. Use cached data (show staleness warning)
3. Gracefully degrade to "Price unavailable - try again in X hours"

### Sports Card Future-Proofing

**Architecture Considerations:**
1. **Abstract "PriceService" protocol** - Easy to add new API providers
2. **Card type routing** - TCG → JustTCG, Sports → eBay scraper
3. **Modular subscriptions** - TCG free, Sports paid add-on
4. **Feature flags** - Enable sports cards when revenue threshold met

---

## Risk Analysis

### Risk 1: Free Tier Rate Limits Too Restrictive

**Likelihood:** HIGH
**Impact:** MEDIUM

**Scenario:** Users exceed 100-333 calls/day, hit rate limits, poor UX

**Mitigation:**
- Implement aggressive caching (24-hour cache)
- Show clear "API calls remaining today" UI
- Offer paid tier that upgrades all APIs ($9.99/mo covers all Standard tiers)
- Prioritize portfolio/watchlist cards for auto-refresh

### Risk 2: APIs Change Terms or Shut Down

**Likelihood:** MEDIUM
**Impact:** HIGH

**Scenario:** Free tier eliminated, pricing increased, API deprecated

**Mitigation:**
- Use multiple API providers (redundancy)
- Abstract API calls behind PriceService protocol
- Monitor API provider status/announcements
- Have backup API ready to swap in

### Risk 3: Sports Card Demand Lower Than Expected

**Likelihood:** MEDIUM
**Impact:** LOW

**Scenario:** Users primarily want TCG data, sports card investment doesn't pay off

**Mitigation:**
- Start with free TCG-only (validates demand before spending)
- Survey users about sports card interest before investing in V4
- Make sports cards optional paid add-on ($2.99/mo extra)

### Risk 4: TCGPlayer Shuts Down Free Data Access

**Likelihood:** LOW
**Impact:** VERY HIGH

**Scenario:** TCGPlayer blocks TCGCSV, restricts API partners, requires paid licensing

**Mitigation:**
- Don't rely solely on TCGPlayer-derived data
- Use CardMarket API (independent European source)
- Build relationships with API providers (JustTCG, PokemonPriceTracker)
- Consider scraping as nuclear option (legally risky)

---

## Legal & Compliance Considerations

### API Terms of Service

**PokemonPriceTracker:**
- ✅ Commercial use allowed with paid tier
- ⚠️ Free tier may have non-commercial restrictions (check ToS)

**JustTCG:**
- ✅ Appears to allow commercial use
- ⚠️ Verify ToS before production launch

**CardMarket API:**
- ✅ Commercial licensing available
- ⚠️ Verify EU data protection compliance (GDPR)

**Scryfall:**
- ✅ Free forever, but cannot paywall Scryfall data
- ⚠️ Cannot require payment to access Scryfall-sourced info
- ⚠️ Must clearly attribute Scryfall data

**eBay Scrapers (SerpApi, Apify):**
- ⚠️ Review eBay's Terms of Service regarding scraping
- ⚠️ May violate eBay ToS (use at own risk)
- ⚠️ Consider legal review before production use

### Recommended Actions

1. **Review all API ToS documents** before V3 launch
2. **Contact API providers** to confirm commercial use allowed
3. **Add proper attribution** in app (especially Scryfall)
4. **Consult lawyer** if using eBay scrapers (gray area)

---

## Final Recommendation

### ✅ YES - Pro Market Agent is VIABLE for V3 with FREE TCG APIs

**Recommended V3 Implementation:**

1. **Primary API:** JustTCG (1,000 calls/month free)
   - Magic: The Gathering
   - Pokemon TCG
   - Yu-Gi-Oh!
   - 4 other TCGs
   - 180-day price history

2. **Secondary API:** PokemonPriceTracker (100 calls/day free)
   - Enhanced Pokemon data
   - 90+ day history
   - PSA prices
   - eBay sold data (Pokemon only)

3. **Tertiary API:** CardMarket (100 calls/day free)
   - EU market comparison
   - 30-day averages
   - Global price insights

4. **Supplementary API:** PSA Public API (100 calls/day free)
   - Graded card populations
   - Auction history
   - Investment metrics

**Total Cost:** $0/month

**Total Daily API Capacity:**
- JustTCG: ~33 calls/day (1000/month)
- PokemonPriceTracker: 100 calls/day
- CardMarket: 100 calls/day
- PSA: 100 calls/day
- **Combined: 333+ calls/day**

**Sufficient For:** 50-100 active users checking prices 3-5x/day with caching

### ❌ DEFER: Sports Card Support to V4

**Reasoning:**
- No free APIs available for sports card sold listings
- eBay access requires paid scrapers ($25-60/month)
- Should validate TCG market demand first
- Can add sports cards once Pro subscriptions generate $100+/month revenue

**Defer to V4 when revenue supports:**
- Apify eBay Scraper (~$5-20/month)
- SerpApi Starter ($25/month)
- Upgraded PokemonPriceTracker Standard ($9.99/month)

---

## Next Steps

### Immediate (Pre-V3 Development)

1. ✅ **Create accounts and test APIs:**
   - Sign up for JustTCG free tier
   - Sign up for PokemonPriceTracker free tier
   - Sign up for CardMarket API free tier
   - Sign up for PSA Public API (requires PSA account)

2. ✅ **Verify API capabilities:**
   - Test historical data endpoints
   - Confirm data format and quality
   - Measure API response times
   - Validate rate limit enforcement

3. ✅ **Review Terms of Service:**
   - Confirm commercial use allowed
   - Check attribution requirements
   - Verify data usage restrictions
   - Document any compliance requirements

### V3 Development Sprint

1. **Implement PriceService protocol:**
   - Abstract API calls behind unified interface
   - Support multiple API providers
   - Implement fallback logic
   - Add caching layer (24-hour default)

2. **Build Pro Market Agent features:**
   - Price trend charts (7d, 30d, 90d, 180d)
   - "% change this week" insights
   - PSA population tracking
   - EU vs US price comparison
   - Historical price table

3. **Implement rate limit handling:**
   - Track API calls per day
   - Show "X calls remaining" to user
   - Cache aggressively
   - Graceful degradation when rate-limited

4. **Add user education:**
   - "TCG market data only (sports cards coming in V4)"
   - Explain API call limits
   - Show data freshness timestamps
   - Offer upgrade path to paid APIs

### Post-V3 Launch (Monitoring)

1. **Track API usage patterns:**
   - Which cards get looked up most
   - How often users hit rate limits
   - Which APIs are most reliable
   - User feedback on data quality

2. **Measure feature adoption:**
   - % of users accessing Pro Market Agent
   - Engagement with trend charts
   - Feedback on insights quality
   - Conversion to Pro subscriptions

3. **Plan V4 expansion:**
   - When revenue hits $100/month, add sports cards
   - Survey users about sports card interest
   - Test Apify/SerpApi eBay scrapers
   - Evaluate Card Ladder partnership

---

## Appendix: API Endpoint Examples

### JustTCG API (Example)

**Documentation:** https://justtcg.com/docs

```
GET /api/v1/cards/search?name=Charizard&game=pokemon
GET /api/v1/prices/history?cardId=123&period=90d
```

*(Note: Actual endpoints TBD - need to review docs after signup)*

### PokemonPriceTracker API (Example)

```
GET /api/cards?name=Charizard&set=base-set
GET /api/prices/history?cardId=pokemon-base-set-4&days=90
GET /api/psa/population?cardId=pokemon-base-set-4
```

### CardMarket API (Example)

```
GET /api/v1/cards/search?name=Pikachu
GET /api/v1/prices?cardId=123&region=EU
GET /api/v1/prices?cardId=123&region=US
```

### PSA Public API (Example)

```
GET /api/population/report?certNumber=12345678
GET /api/auction/prices?cardDescription=2000%20Pokemon%20Charizard
```

---

## Appendix: Competitive Analysis

### Existing Market Intelligence Tools

**Card Ladder:**
- 100M+ sales history
- $10-20/month subscription
- Sports & TCG coverage
- Mobile app + web

**CollX (Sports Cards):**
- Free scanning & price guide
- AI-powered recognition
- eBay integration
- 6M+ cards

**TCGPlayer App:**
- Free price lookups
- Scanner included
- Listing integration
- TCG-only

**130 Point:**
- Sports card focus
- Market tracking
- PSA integration
- $5-10/month

### Our Competitive Advantages

1. **Multi-category:** TCG + Sports (V4) in one app
2. **Integrated workflow:** Price lookup → Sales calculator → Contact management
3. **Free tier:** Basic market insights with free APIs
4. **Card show focus:** Built for dealers, not just collectors
5. **Trend analysis:** Not just current prices, but market intelligence

---

## Questions to Resolve Before V3

1. **JustTCG Commercial Use:**
   - Can we use free tier for commercial app?
   - What are paid tier costs?
   - Any attribution requirements?

2. **PokemonPriceTracker Licensing:**
   - Is free tier commercial-use OK?
   - When do we need Standard tier?
   - Bulk data access available?

3. **CardMarket API Compliance:**
   - GDPR considerations for EU data?
   - Attribution requirements?
   - Rate limit enforcement strictness?

4. **Data Freshness Expectations:**
   - How stale can cached data be?
   - Do users expect real-time updates?
   - Is 24-hour cache acceptable?

5. **Monetization Strategy:**
   - Should Pro Market Agent be Pro-tier only?
   - Or offer limited free version (10 lookups/day)?
   - Separate "Sports Card Add-on" for $2.99/mo?

---

**END OF REPORT**

*For questions or updates, contact development team.*
