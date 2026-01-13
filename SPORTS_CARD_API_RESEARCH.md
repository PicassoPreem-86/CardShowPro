# Sports Card API Research Report
**Date:** January 13, 2026
**Project:** CardShowPro
**Purpose:** Evaluate feasibility of sports card pricing integration for future versions

---

## Executive Summary

**RECOMMENDATION: Defer sports card support to V3 or later**

Sports cards are **significantly more complex** than Pokemon/Magic TCG cards and present substantial technical and data challenges. While several API options exist, none offer a free tier robust enough for MVP testing, and the data complexity requires specialized handling that would significantly delay the core product launch.

**Key Findings:**
- No true free-tier APIs with comprehensive sports card data
- 10-20x more data complexity than Pokemon cards
- Dynamic pricing tied to real-time player performance
- Grading multipliers create exponential pricing variations
- Parallel/variation tracking requires sophisticated database design

---

## Available Sports Card APIs

### 1. SportsCardsPro
**Website:** https://www.sportscardspro.com/api-documentation

**Coverage:**
- Baseball, Basketball, Football, Hockey, Soccer, Racing, Wrestling, UFC

**API Features:**
- Prices API (single/multiple product pricing)
- Marketplace API
- HTTPS + JSON responses
- Authentication via 40-character token

**Data Fields:**
- Product ID, Name, Set Name
- Pricing by condition/grade
- Release Date, Sales Volume
- Prices in pennies (e.g., $17.32 = 1732)

**Limitations:**
- **Requires paid subscription** (no free tier)
- CSV downloads only for "Legendary subscribers"
- Updated once every 24 hours (not real-time)
- No historic pricing or sales data

**Verdict:** Professional-grade but expensive. Best for production, not MVP.

---

### 2. Card Hedger
**Website:** https://www.cardhedger.com/price_api_business

**Coverage:**
- Sports cards, Pokemon, TCG
- Described as "enterprise grade"

**API Features:**
- Curated and well-structured data
- Off-the-shelf and custom endpoints
- Sports card, Pokemon, and TCG price API

**Limitations:**
- **No pricing information publicly available**
- Requires direct contact for quote
- Appears enterprise-focused (likely expensive)

**Verdict:** Enterprise-level solution. Pricing likely prohibitive for small team MVP.

---

### 3. PSA Public API
**Website:** https://www.psacard.com/publicapi

**Coverage:**
- PSA graded cards (all types including sports)
- Population report data
- Authentication/verification

**API Features:**
- REST API over HTTPS
- OAuth 2 authentication
- JSON and XML response formats
- Certificate lookup
- Population data

**Rate Limits:**
- **Free tier: 100 API calls per day**
- Paid tiers available (contact sales@psacard.com)

**Limitations:**
- Only covers PSA-graded cards (not raw/ungraded)
- Daily limit too low for production use
- Requires PSA account credentials
- Documentation requires sign-in to access

**Verdict:** Useful for graded card verification but not comprehensive pricing. Good supplementary API for V2+.

---

### 4. eBay API (Browse API)
**Website:** https://developer.ebay.com/api-docs/buy/browse

**Coverage:**
- All sports card categories
- Sold listings (completed auctions)
- Active listings

**API Features:**
- Category filtering (Baseball: 213, Basketball: 214, Football: 215)
- Condition filtering
- Price range filtering
- Keyword search

**Limitations:**
- **eBay killed API access to detailed sold history** (October 2024)
- Requires eBay developer account
- Rate limits based on partnership tier
- No built-in sports card parsing (generic product API)
- Third-party tools (130 Point) use this but don't resell API access

**Verdict:** Possible supplementary data source but unreliable as primary. eBay keeps restricting third-party access.

---

### 5. Zyla API Hub - Sports Card and Trading Card API
**Website:** https://zylalabs.com/api-marketplace/sports/sports+card+and+trading+card+api/2511

**Coverage:**
- Pokemon, Marvel, Sports cards
- Card details and pricing data

**Limitations:**
- API returned 403 Forbidden during research
- Appears to be aggregator/marketplace
- **Pricing information not accessible**

**Verdict:** Cannot evaluate. Likely paid-only with unknown pricing.

---

### 6. CollX (Visual Recognition + Pricing)
**Website:** https://www.collx.app/

**Coverage:**
- 20+ million sports card database
- AI visual recognition
- Real-time market pricing

**Technology:**
- Deep learning image recognition (10+ years experience)
- Photo scanning with instant recognition
- CSV export (CollX Pro)
- 2025 Innovation of the Year award

**Limitations:**
- **No public developer API**
- Consumer-facing mobile app only
- Would require partnership/licensing deal

**Verdict:** Best-in-class tech but not available for third-party integration. Consider licensing partnership in V4+.

---

## Sports Player Database APIs (for metadata)

While sports CARD pricing APIs are limited, player data APIs are abundant:

### BALLDONTLIE
- **Coverage:** NBA, NFL, MLB, NHL, EPL, WNBA
- **Free Tier:** 5 requests/minute
- **Paid Tiers:** $9.99-$299.99/month
- **Data:** Player stats, team data, game logs, historical data
- **Accuracy:** 99.9% claimed

### MySportsFeeds
- **Coverage:** NFL, MLB, NBA, NHL
- **Free Tier:** Non-commercial use completely free
- **Formats:** JSON, XML, CSV
- **Data:** Schedules, standings, stats, odds

### TheSportsDB
- **Coverage:** All major sports
- **Free Tier:** Basic API permanently free
- **Paid Tier:** $9/month for premium features
- **Data:** Team info, player bios, league data

**Strategy:** These could supplement card data by providing player name normalization, team affiliations, and career statistics to enhance search accuracy.

---

## Data Complexity Analysis: Pokemon vs Sports Cards

### Pokemon Cards (Current Implementation)
**Variables:**
- Card Name
- Set Name/Number
- Card Number
- Variant (Normal, Holofoil, Reverse Holo, 1st Edition)
- Language
- Condition (graded or ungraded)

**Pricing Model:**
- Relatively stable pricing
- Variant pricing follows predictable patterns
- Grading adds 2-5x multiplier
- Set completion is primary driver

**API Complexity:** LOW
- Single identifier (e.g., "base1-4") retrieves complete data
- PokemonTCG.io provides comprehensive free API
- Image URLs included
- Market price aggregated from TCGPlayer

---

### Sports Cards (Potential Future Support)
**Variables:**
- Player Name (with fuzzy matching needed)
- Year/Season
- Sport (MLB, NBA, NFL, NHL, Soccer, etc.)
- Brand/Manufacturer (Topps, Panini, Upper Deck, etc.)
- Product Line (Prizm, Chrome, Bowman, etc.)
- Card Number
- Rookie Card status
- **Parallel Type** (Base, Refractor, Prizm, etc.)
- **Parallel Color** (Silver, Gold, Orange, Red, Green, etc.)
- **Serial Number** (/10, /25, /50, /99, /299, etc.)
- **Insert Type** (base set vs insert set)
- **Variation Type** (SSP, Photo Variation, etc.)
- Autograph status (signed/unsigned)
- Memorabilia (jersey patch, bat piece, etc.)
- Grading Company (PSA, BGS, SGC, CGC)
- Grade (1-10, with BGS having 4 sub-grades)
- Centering quality
- **Player performance** (MVP, Championships, Hall of Fame)
- **Current team** (affects value)
- **Injury status** (dynamic, affects real-time pricing)

**Pricing Model:**
- **Highly volatile** - tied to player performance
- **Injury/scandal** can crash prices overnight
- **Playoff performance** can 5-10x prices in days
- **Grading multipliers:** PSA 10 vs PSA 9 often = 2-3x difference
- **Parallel scarcity:** Gold Prizm /10 worth 50x+ base parallel
- **Rookie cards:** 5-20x more valuable than later years
- **Hall of Fame induction:** Can permanently increase value 10x+

**API Complexity:** VERY HIGH
- Requires multiple API calls (card data + player data + real-time pricing)
- No single identifier system (must construct from multiple fields)
- Parallel/variation tracking exponentially increases database size
- Same player/year/brand can have 50+ distinct parallel variations
- Real-time pricing requires continuous monitoring
- Image URLs often not available in APIs
- Market price aggregation requires eBay/COMC/Goldin scraping

---

## Sports Card Complexity Deep Dive

### Grading Company Differences

| Company | Market Position | Grade Scale | Price Premium | Turnaround | Cost |
|---------|----------------|-------------|---------------|------------|------|
| **PSA** | Highest resale value | 1-10 | PSA 10 = highest | Slow | $25-$500 |
| **BGS** | Preferred for basketball/TCG | 1-10 + 4 sub-grades | BGS 10 = 1.5x PSA 10 | Medium | Similar to PSA |
| **SGC** | Best for vintage | 1-10 | Comparable for vintage | **Fastest** | $18-$20 |
| **CGC** | Growing acceptance | 1-10 | Lower than PSA/BGS | Fast | Similar |

**Key Challenge:** Must track grading company + grade + sub-grades (BGS) = exponential data complexity

### Grade Multiplier Examples

| Card Type | Raw (Ungraded) | PSA 8 | PSA 9 | PSA 10 |
|-----------|----------------|-------|-------|--------|
| Common card | $1 | $5 | $15 | $50 |
| Mid-tier card | $20 | $50 | $150 | $500 |
| High-value card | $200 | $500 | $2,000 | $10,000+ |

**Multiplier Range:** 5x to 50x depending on card, grade, and market conditions

---

### Parallel/Variation Complexity

A single card (e.g., 2023 Panini Prizm Mike Trout Base) can exist in:

**Base Parallels:**
- Base (unlimited print run)
- Silver Prizm (common parallel)
- Green Prizm /275
- Blue Prizm /199
- Purple Prizm /99
- Orange Prizm /49
- Gold Prizm /10
- Black Prizm /5
- Gold Vinyl 1/1

**Plus each parallel can be:**
- Autographed or unsigned
- With memorabilia or without
- Different memorabilia types (jersey, patch, bat, etc.)
- Various grading companies/grades

**Result:** A single "card" in the set can have **100+ distinct SKUs** with wildly different values.

**Example Pricing:**
- Base: $2
- Silver Prizm: $8
- Purple /99: $75
- Gold /10: $1,500
- Gold 1/1: $15,000+

**Database Challenge:** Must track each variation separately with unique identifiers.

---

### Real-Time Pricing Volatility

Unlike Pokemon (stable franchise, consistent demand), sports cards are tied to **player performance:**

**Example: Injury Impact**
- Player suffers season-ending injury
- Card values drop 30-70% within **24-48 hours**
- Recovery announcements cause 20-40% rebounds
- Career-ending injury = near-total value loss

**Example: Playoff Performance**
- Unknown player has breakout playoff game
- Card value increases 5-10x overnight
- Sustained performance = permanent price increases
- One-hit wonder = price crashes back to baseline

**Example: Hall of Fame Induction**
- Announcement: +50% immediate
- Induction week: +100-200% spike
- Long-term: +300-500% sustained

**Pricing Challenge:** 24-hour cache (like current Pokemon implementation) is **inadequate** for sports cards. Requires hourly or real-time updates.

---

## Technical Implementation Challenges

### 1. Data Model Complexity
**Pokemon (current):**
```swift
struct CachedPrice {
    cardID: String        // "base1-4"
    cardName: String
    setName: String
    marketPrice: Double?
    // 5-6 variant prices
}
```

**Sports Cards (hypothetical):**
```swift
struct SportsCardPrice {
    // Base identification (7+ fields)
    playerName: String
    sport: Sport
    year: Int
    brand: String
    productLine: String
    cardNumber: String
    isRookie: Bool

    // Parallel/variation (4+ fields)
    parallelType: String?
    parallelColor: String?
    serialNumber: String?    // "/10", "/99", "1/1"
    insertType: InsertType?

    // Physical attributes (3+ fields)
    isAutographed: Bool
    hasMemorabilia: Bool
    memorabiliaType: String?

    // Grading (4+ fields)
    gradingCompany: GradingCompany?
    grade: Double?
    subGrades: SubGrades?    // BGS only
    certNumber: String?

    // Player context (4+ fields - DYNAMIC)
    currentTeam: String?
    careerStats: PlayerStats?
    injuryStatus: InjuryStatus?
    hallOfFameStatus: Bool

    // Pricing (must track by grading tier)
    rawPrice: Double?
    psa8Price: Double?
    psa9Price: Double?
    psa10Price: Double?
    bgsPrice: Double?

    // Metadata
    lastUpdated: Date       // MUST be recent!
    priceSource: String
    imageURL: URL?
}
```

**Complexity Increase:** 5-6 fields → 30+ fields = **6x data model complexity**

---

### 2. Search Implementation
**Pokemon (current):**
- User types: "Charizard"
- API returns: All Charizard cards with unique IDs
- User selects card → instant price lookup
- **Search success rate: ~95%**

**Sports Cards (hypothetical):**
- User types: "Mike Trout 2023 Prizm"
- Must search:
  1. Player name (fuzzy matching: "Trout", "M. Trout", "Michael Trout")
  2. Year/Season
  3. Brand/Product line
  4. Card number (if known)
- Returns: **50+ variations** (all parallels, autographs, etc.)
- User must specify:
  - Which parallel? (Base, Silver, Gold /10, etc.)
  - Autographed or not?
  - Graded or raw?
  - If graded: PSA/BGS/SGC and what grade?
- **Search success rate: ~60-70%** (estimated)

**UI Challenge:** Current CardShowPro UI assumes simple card selection. Sports cards require multi-step refinement process.

---

### 3. Pricing Cache Strategy
**Pokemon (current - works well):**
```swift
// 24-hour cache is acceptable
staleTTL: TimeInterval = 86400  // 24 hours

// Three-tier caching:
1. Memory (NSCache) - instant
2. SwiftData - fast
3. PokemonTCG.io API - fallback
```

**Sports Cards (would require):**
```swift
// Cache TTL varies by card type and player status
dynamicStaleTTL(card: SportsCard) -> TimeInterval {
    if card.player.isInjured || card.player.isInPlayoffs {
        return 3600  // 1 hour
    } else if card.player.isRetired || card.player.isHallOfFame {
        return 259200  // 3 days (stable pricing)
    } else {
        return 43200  // 12 hours
    }
}

// Multi-source aggregation needed:
1. eBay sold comps (most accurate)
2. COMC listings (secondary market)
3. PSA population report (graded cards)
4. Beckett values (guide pricing)
5. SportsCardsPro (aggregated data)

// Pricing confidence score required:
struct PriceConfidence {
    value: Double
    confidence: ConfidenceLevel  // High, Medium, Low
    lastSale: Date?
    sampleSize: Int
}
```

**Implementation Complexity:** Current caching system would need **complete redesign** for sports cards.

---

### 4. API Cost Analysis

**Pokemon (current - FREE):**
- PokemonTCG.io: Free unlimited API calls
- No authentication required
- Comprehensive data included
- Images included
- **Monthly cost: $0**

**Sports Cards (estimated):**

| Service | Monthly Cost | Coverage | Notes |
|---------|--------------|----------|-------|
| SportsCardsPro API | $50-$200/mo (estimated) | Baseball, Basketball, Football, Hockey | Paid subscription required |
| PSA API | $0 (100/day) or contact sales | PSA graded only | Free tier too limited |
| eBay API | $0-$500/mo | All cards, sold comps | Restricted access, unreliable |
| Player Data API | $0-$40/mo | Player stats, team info | BALLDONTLIE or MySportsFeeds |
| **Total Estimated** | **$100-$500/month** | Basic coverage | Still missing parallels/variations |

**For comprehensive sports card support: $200-$500/month minimum API costs**

---

## Comparison: Pokemon vs Sports Card Implementation

| Factor | Pokemon (Current) | Sports Cards (Future) | Complexity Ratio |
|--------|-------------------|----------------------|------------------|
| **API Cost** | $0/month | $100-500/month | ∞ (free → paid) |
| **Free Tier Viable?** | Yes (unlimited) | No | N/A |
| **Data Model Fields** | 10-12 | 30-35 | 3x |
| **Unique Card Variants** | 3-5 per card | 50-200 per card | 20x |
| **Search Complexity** | Simple name search | Multi-field + fuzzy | 5x |
| **Cache TTL** | 24 hours (static) | 1-48 hours (dynamic) | Complex logic |
| **Pricing Volatility** | Low (stable) | Very High (dynamic) | 10x |
| **Database Size** | ~50K cards | ~10M+ variants | 200x |
| **Image Availability** | 100% (API provided) | ~30% (API provided) | 0.3x |
| **Player Context Needed** | No | Yes (performance, injuries) | Required |
| **Real-time Updates** | Not needed | Essential | Critical |
| **Grading Multipliers** | 2-3x | 5-50x | 15x |
| **Implementation Time** | 2-3 weeks (done) | **3-6 months** (estimated) | 10x |

**Overall Complexity: Sports cards are 10-20x more complex than Pokemon cards.**

---

## Biggest Challenges for Sports Card Support

### 1. No Free-Tier API for MVP Testing
- All comprehensive sports card APIs require paid subscriptions
- Free options (PSA 100/day) insufficient for testing
- Cannot validate market fit without significant upfront investment

### 2. Data Standardization Gap
- No equivalent to PokemonTCG.io (comprehensive, free, standardized)
- Beckett/PSA/eBay use different naming conventions
- Parallel names vary by manufacturer (Prizm vs Refractor vs Chrome)
- Requires custom normalization layer

### 3. Parallel/Variation Explosion
- Single player/year/set = 50-200+ distinct variations
- Must track serial numbers (/10, /99, etc.)
- Database grows exponentially
- Search/filtering UI becomes complex

### 4. Real-Time Pricing Requirements
- 24-hour cache inadequate (player injuries, performances)
- Requires hourly or real-time updates
- Increases API call volume 10-24x
- Higher infrastructure costs

### 5. Grading Company Fragmentation
- PSA, BGS, SGC, CGC all have different scales
- BGS has 4 sub-grades (centering, corners, edges, surface)
- Price multipliers vary by company and grade
- Population reports not unified

### 6. Player Performance Integration
- Card values tied to real-time sports performance
- Requires sports data API (additional cost)
- Complex logic: injuries, playoffs, retirement, scandals
- Machine learning potentially needed for price prediction

### 7. Image Availability
- APIs rarely include card images
- Would need to scrape/aggregate from multiple sources
- Potential copyright issues
- Visual recognition (CollX-style) requires ML/AI investment

### 8. Market Fragmentation
- eBay, COMC, Goldin, Heritage Auctions, PWCC, MySlabs
- No single source of truth
- Must aggregate across platforms
- Each has different API access/costs

---

## Recommendation: Phased Approach

### V1 (Current) - Pokemon TCG Only
**Status:** In Progress
**Focus:** Single-game mastery
**API:** PokemonTCG.io (free, comprehensive)
**Timeline:** 2-3 months to MVP

**Why start here:**
- Free API reduces risk
- Simple data model validates core architecture
- Large, passionate collector base
- Stable pricing allows 24-hour cache
- Proves product-market fit before expanding

---

### V2 - Magic: The Gathering
**Timeline:** +2-3 months after V1 launch
**Focus:** Second TCG with similar complexity

**API Options:**
- Scryfall API (free, comprehensive)
- MTG JSON (free dataset)
- TCGPlayer API (commercial)

**Why Magic next:**
- Similar complexity to Pokemon (manageable)
- Free API available (Scryfall)
- Large market ($1B+ annually)
- Collector behavior similar to Pokemon
- Reuses existing caching architecture

**Effort:** 30-40% of V1 effort (architecture reusable)

---

### V3 - Yu-Gi-Oh! (Optional)
**Timeline:** +1-2 months after V2
**Focus:** Third major TCG

**API Options:**
- YGOPRODeck API (free)
- TCGPlayer API

**Why Yu-Gi-Oh:**
- Rounds out "Big 3" TCGs
- Free API available
- Similar technical requirements
- Smaller market than Pokemon/Magic but still significant

**Effort:** 20-30% of V1 effort (patterns established)

---

### V4+ - Sports Cards (Multi-Phase)

#### Phase 4A: Single Sport MVP (Baseball or Basketball)
**Timeline:** +4-6 months after V3
**Focus:** Prove sports card viability with ONE sport

**Implementation:**
- Choose baseball (largest market) or basketball (highest volatility)
- Partner with single data provider (SportsCardsPro or Card Hedger)
- Limit to base cards + major parallels only (no SSP/variations initially)
- Implement dynamic pricing cache (1-12 hour TTL)
- Add player performance tracking (MySportsFeeds API)
- **Budget:** $200-300/month API costs

**Success Metrics:**
- User engagement compared to Pokemon/Magic
- Pricing accuracy within 10% of market
- Search success rate >70%
- User retention comparable to TCG users

**Go/No-Go Decision:** If metrics hit targets, proceed to 4B. Otherwise, refocus on TCG improvements.

---

#### Phase 4B: Multi-Sport Expansion
**Timeline:** +3-4 months after 4A success
**Focus:** Add remaining major sports

**Implementation:**
- Add football, hockey, soccer
- Implement sport-specific pricing logic
- Enhance player database with multi-sport stats
- Add grading company comparison features
- **Budget:** $400-600/month API costs

---

#### Phase 4C: Advanced Features
**Timeline:** +6-12 months after 4B
**Focus:** Full sports card feature parity

**Implementation:**
- Complete parallel/variation tracking
- PSA/BGS/SGC grade comparison
- Visual card recognition (CollX-style)
- Real-time price alerts (injury/performance triggers)
- Portfolio tracking with performance analytics
- **Budget:** $800-1500/month API costs + ML infrastructure

---

## Risk Assessment

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| No free API for testing | **100%** | High | Budget $200-300/mo for V4 |
| Data quality issues | High | High | Multi-source aggregation |
| API rate limits | Medium | Medium | Implement aggressive caching |
| Pricing accuracy <90% | High | Critical | User confidence lost |
| Real-time updates fail | Medium | High | Fallback to daily updates |
| Image availability low | High | Medium | Partner with CollX or similar |

### Business Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| High API costs kill margins | Medium | Critical | Charge premium for sports cards |
| Users expect instant updates | High | Medium | Set expectations (4-hour delay) |
| Grading data inconsistent | High | High | Display confidence scores |
| Low user adoption | Medium | High | Start with single sport MVP |
| Competitor launches first | Low | Medium | Focus on UX superiority |

### Market Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Sports card market contracts | Low | High | Diversify across TCG+sports |
| Beckett/PSA restricts APIs | Medium | Critical | Build scraping fallbacks |
| CollX monopolizes market | Medium | High | Focus on dealer/show use case |
| Pricing volatility too high | High | Medium | Show price ranges, not absolutes |

---

## Competitive Analysis

### Existing Sports Card Apps

| App | Focus | Strengths | Weaknesses | Pricing |
|-----|-------|-----------|------------|---------|
| **CollX** | Visual scan + pricing | 20M card database, AI recognition | No API, closed platform | Free + $10/mo Pro |
| **130 Point** | eBay sold comps | Shows "best offer" prices | eBay-dependent, mobile-focused | Free + $10/mo |
| **Beckett** | Price guide | Brand recognition, historical data | Outdated model, subscription required | $40-100/yr |
| **CardLadder** | Price tracking | Charts, trends, analytics | Limited free tier | $10-30/mo |
| **Market Movers** | Analytics | Professional-grade data | Expensive | $15-50/mo |

**CardShowPro Differentiation Opportunity:**
- Focus on **in-person show transactions** (scan, price, negotiate on-the-spot)
- **Dealer tools** (bulk scanning, inventory management)
- **Cross-category** (TCG + Sports in one app)
- **Offline mode** (pre-cached pricing for shows)

---

## Cost-Benefit Analysis

### V1-V3 (TCG Only): 6-9 months
**Investment:**
- Development: 6-9 months (already budgeted)
- API Costs: $0/month (free APIs)
- Total: Developer time only

**Return:**
- Prove product-market fit
- Build user base (TCG collectors)
- Generate revenue (premium features)
- Validate architecture
- **Risk: LOW**

---

### V4A (Single Sport MVP): +4-6 months
**Investment:**
- Development: 4-6 months
- API Costs: $200-300/month
- Testing: $500-1000 (sample card purchases)
- Total: ~$2000-4000 + dev time

**Return:**
- Access sports card market ($13B vs $7.5B TCG)
- Validate sports card complexity handling
- Test user willingness to pay premium
- Prove/disprove sports card viability
- **Risk: MEDIUM**

**Break-even:** Need ~100 sports card users paying $5/mo premium OR 500 users paying $1/mo extra

---

### V4B-V4C (Full Sports Support): +9-18 months
**Investment:**
- Development: 9-18 months
- API Costs: $400-1500/month
- ML/AI Infrastructure: $500-2000/month (for image recognition)
- Total: ~$20,000-60,000 + substantial dev time

**Return:**
- Comprehensive sports card platform
- Compete with CollX, CardLadder, 130 Point
- Dealer/professional user tier ($50-100/month)
- Potential licensing deals (show organizers)
- **Risk: HIGH** (uncertain market fit, high costs)

**Break-even:** Need 500-1000 premium users OR 50-100 professional/dealer accounts

---

## Estimated Development Effort

### V1: Pokemon TCG (Current)
- **Timeline:** 2-3 months
- **Complexity:** BASELINE (1x)
- **Team Size:** 1-2 developers
- **Total Effort:** 500-800 hours

### V2: Magic The Gathering
- **Timeline:** +2-3 months
- **Complexity:** 0.3-0.4x (reuse architecture)
- **Total Effort:** 200-300 hours

### V3: Yu-Gi-Oh
- **Timeline:** +1-2 months
- **Complexity:** 0.2-0.3x (patterns established)
- **Total Effort:** 100-200 hours

### V4A: Sports Cards - Single Sport MVP
- **Timeline:** +4-6 months
- **Complexity:** 3-5x Pokemon (new data model, caching, APIs)
- **Total Effort:** 1500-2000 hours
- **Includes:**
  - Data model redesign
  - Multi-field search
  - Player database integration
  - Dynamic cache TTL logic
  - Grading company support (PSA/BGS/SGC)
  - Parallel/variation basic support
  - API integration (SportsCardsPro + MySportsFeeds)
  - Testing with real cards

### V4B: Sports Cards - Multi-Sport
- **Timeline:** +3-4 months
- **Complexity:** 1.5-2x V4A (expand existing system)
- **Total Effort:** 800-1200 hours

### V4C: Sports Cards - Advanced Features
- **Timeline:** +6-12 months
- **Complexity:** 2-3x V4A (ML/AI, advanced analytics)
- **Total Effort:** 2000-3000 hours
- **Includes:**
  - Image recognition (CollX-style)
  - Complete parallel tracking
  - Real-time price alerts
  - Performance-based pricing updates
  - Portfolio analytics
  - Dealer bulk tools

**Total for Full Sports Support: V4A-V4C = 4300-6200 hours (2-3 developer-years)**

---

## Critical Success Factors for Sports Card Support

### Must-Have Before Attempting:

1. **Proven TCG Success**
   - V1 (Pokemon) must have 1000+ active users
   - Premium conversion rate >10%
   - Retention rate >40% at 90 days
   - Positive cash flow covering development

2. **API Budget Secured**
   - $200-300/month for V4A
   - $400-600/month for V4B
   - $800-1500/month for V4C
   - 6-month runway minimum

3. **Sports Card Expertise**
   - Team member with sports card domain knowledge
   - Advisor/consultant familiar with grading, parallels, market
   - Access to test cards across grading companies

4. **Infrastructure Ready**
   - Dynamic cache TTL system built
   - Multi-source API aggregation framework
   - Pricing confidence scoring algorithm
   - Fuzzy player name matching

5. **User Research Completed**
   - Interview 20-30 sports card collectors
   - Validate willingness to pay premium vs free alternatives
   - Understand show dealer workflows
   - Identify must-have vs nice-to-have features

---

## Alternative Strategy: Defer Sports Cards Indefinitely

### Focus on TCG Mastery Instead

Rather than attempt sports cards (high complexity, high cost), consider doubling down on TCG excellence:

**V1-V3:** Pokemon, Magic, Yu-Gi-Oh (9-12 months)

**V4:** Additional TCGs
- Flesh and Blood (growing market)
- Digimon
- One Piece (hot new TCG)
- Dragon Ball Super
- Weiss Schwarz

**V5:** TCG-Specific Features
- Deck building tools
- Tournament tracking
- Trade matching
- Set completion tracking
- Investment portfolio analytics

**Advantages:**
- Stay in free API ecosystem
- Lower complexity = faster velocity
- Clearer differentiation (TCG specialist)
- Avoid sports card pricing volatility
- Build deep moat in TCG space

**Market Opportunity:**
- Global TCG market: $7.5B (2025)
- Growing 10-15% annually
- Pokemon alone: $1.5B+ secondary market
- Magic: $1B+
- Younger collector demographic (higher app adoption)

---

## Final Recommendation

### DO NOT pursue sports cards until:

1. **V1-V2 Success Proven** (Pokemon + Magic)
   - 1000+ active users
   - Positive cash flow
   - Clear product-market fit

2. **Budget Secured** ($10K+ for V4A MVP)
   - $200-300/month API costs × 12 months = $2400-3600
   - $500-1000 testing/sample cards
   - 4-6 months developer time budgeted

3. **User Demand Validated**
   - User surveys show sports card interest
   - Willingness to pay premium for sports
   - Show dealers express interest

4. **Technical Foundation Ready**
   - Three-tier caching proven reliable
   - Search UX refined through TCG iterations
   - Team has capacity for 3-6 month project

### Proceed with sports cards IF:

1. **Single sport MVP** (baseball or basketball only)
2. **Limited scope** (base cards + major parallels, no variations initially)
3. **Partner with ONE data provider** (SportsCardsPro or Card Hedger)
4. **Set realistic expectations** (4-12 hour price updates, not real-time)
5. **Charge premium** ($5-10/month for sports card access)
6. **Build confidence scoring** (show price ranges, not absolutes)
7. **Plan for 6-month development** (not a quick add-on)

---

## Conclusion

**Sports cards are feasible but represent a significantly larger undertaking than Pokemon/Magic TCG cards.**

The lack of comprehensive free APIs, extreme data complexity (parallels, grading, player performance), and real-time pricing requirements make sports cards **unsuitable for an MVP** but potentially **viable for V4+ with proper budget and planning**.

**Recommended Path:**
1. **V1:** Master Pokemon (current focus)
2. **V2:** Add Magic: The Gathering
3. **V3:** Add Yu-Gi-Oh (optional)
4. **V4:** Re-evaluate sports cards based on TCG success
5. **V4A:** IF proceeding, start with single sport MVP
6. **V4B-C:** Expand only after V4A proves viable

**Key Metrics to Hit Before Sports Cards:**
- 1000+ active users on TCG version
- $5K+ monthly revenue
- 40%+ 90-day retention
- $10K+ budget secured for sports card development
- Sports card user demand validated

**Alternative:** Consider becoming the **best TCG app** rather than attempting sports cards. Focus creates competitive moats; spreading too thin risks mediocrity in all categories.

---

## Appendix: Technical Architecture Considerations

### If/When Implementing Sports Cards:

**Database Schema:**
```swift
// Sports Card Entities (SwiftData)
@Model final class SportsCard {
    // Core Identity
    let id: UUID
    let playerID: String           // Link to player database
    let sport: Sport
    let year: Int
    let manufacturerID: String     // Link to manufacturer
    let productLineID: String      // Link to product line
    let cardNumber: String

    // Variation Details
    let parallelID: String?        // Link to parallel types
    let serialNumber: String?      // "/10", "/99", etc.
    let isAutographed: Bool
    let hasMemorabilia: Bool
    let memorabiliaType: String?

    // Pricing Cache
    var cachedPrices: [CachedPrice] // One per grading tier
    var lastPriceUpdate: Date
    var priceConfidence: ConfidenceLevel
}

@Model final class Player {
    let id: String
    let name: String
    let sport: Sport
    let teamHistory: [TeamAffiliation]
    let rookieYear: Int
    let isActive: Bool
    let injuryStatus: InjuryStatus?
    let hallOfFame: Bool
    let careerStats: Data?         // JSON blob
    var lastStatsUpdate: Date
}

@Model final class CardManufacturer {
    let id: String
    let name: String               // "Panini", "Topps", etc.
    let productLines: [ProductLine]
}

@Model final class ProductLine {
    let id: String
    let name: String               // "Prizm", "Chrome", etc.
    let manufacturerID: String
    let years: [Int]
    let availableParallels: [Parallel]
}

@Model final class Parallel {
    let id: String
    let name: String               // "Silver Prizm", "Gold Refractor"
    let color: String?
    let printRun: Int?             // nil if unlimited
    let serialNumbered: Bool
    let scarcityTier: ScarcityTier
}

enum ConfidenceLevel: String, Codable {
    case high      // 10+ recent sales
    case medium    // 3-9 recent sales
    case low       // 1-2 recent sales
    case unknown   // No recent sales
}
```

**API Orchestration:**
```swift
@MainActor
final class SportsCardPricingService {
    private let sportsCardAPI: SportsCardProAPI
    private let playerStatsAPI: MySportsFeeds
    private let psaAPI: PSAPublicAPI
    private let ebayAPI: EBayBrowseAPI
    private let repository: SportsCardRepository

    // Aggregate pricing from multiple sources
    func getPrice(for card: SportsCard, grade: Grade?) async throws -> PriceEstimate {
        // Check cache with dynamic TTL
        if let cached = try getCachedPrice(card, grade: grade),
           !isCacheStale(cached, for: card) {
            return cached.toPriceEstimate()
        }

        // Fetch from multiple sources in parallel
        async let sportsCardPrice = sportsCardAPI.getPrice(card)
        async let ebayComps = ebayAPI.getSoldListings(card, grade: grade)
        async let psaPopulation = psaAPI.getPopulation(card)

        // Aggregate results
        let aggregated = try await aggregatePrices(
            sportsCard: sportsCardPrice,
            ebay: ebayComps,
            psa: psaPopulation
        )

        // Calculate confidence
        let confidence = calculateConfidence(aggregated)

        // Save to cache
        let cached = CachedPrice(
            card: card,
            grade: grade,
            estimate: aggregated,
            confidence: confidence,
            timestamp: Date()
        )
        try repository.savePrice(cached)

        return aggregated
    }

    // Dynamic cache staleness based on player status
    private func isCacheStale(_ cached: CachedPrice, for card: SportsCard) -> Bool {
        let player = getPlayer(card.playerID)
        let ttl: TimeInterval

        if player.injuryStatus != nil || player.isInPlayoffs {
            ttl = 3600  // 1 hour for high-volatility
        } else if !player.isActive {
            ttl = 259200  // 3 days for retired players
        } else {
            ttl = 43200  // 12 hours for active players
        }

        return Date().timeIntervalSince(cached.timestamp) > ttl
    }
}
```

**Search Implementation:**
```swift
@MainActor
final class SportsCardSearchService {
    // Multi-stage search pipeline
    func search(query: String, filters: SearchFilters) async throws -> [SportsCard] {
        // Stage 1: Parse query
        let parsed = try parseQuery(query)
        // "Mike Trout 2023 Prizm Gold" ->
        //   player: "Mike Trout", year: 2023, product: "Prizm", parallel: "Gold"

        // Stage 2: Fuzzy player name matching
        let playerMatches = try await fuzzyMatchPlayer(parsed.playerName)
        // Handles: "Trout", "M. Trout", "Michael Trout", "Trout, Mike"

        // Stage 3: Filter by year/product/parallel
        let cardMatches = try searchCards(
            players: playerMatches,
            year: parsed.year,
            product: parsed.product,
            parallel: parsed.parallel,
            filters: filters
        )

        // Stage 4: Rank by relevance
        return rankResults(cardMatches, query: query)
    }

    // Player name fuzzy matching
    private func fuzzyMatchPlayer(_ name: String) async throws -> [Player] {
        // Use Levenshtein distance or similar
        // Account for "First Last" vs "Last, First"
        // Handle nicknames (e.g., "Magic" -> "Magic Johnson")
        // Use player stats API for canonical names
    }
}
```

---

**This concludes the sports card API research report.**

**TL;DR:** Sports cards are 10-20x more complex than Pokemon. Defer to V4+ after TCG success is proven. Budget $10K+ and 6 months for a single-sport MVP. Consider focusing on TCG mastery instead.
