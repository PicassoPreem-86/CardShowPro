# Sports Card API Research - Executive Summary

**Date:** January 13, 2026
**Recommendation:** DEFER TO V3 OR LATER

---

## Key Findings

### Complexity Comparison
- **Pokemon Cards:** 3-5 variants per card, stable pricing, free API
- **Sports Cards:** 50-200+ variants per card, volatile pricing, paid APIs only
- **Complexity Ratio:** 10-20x more complex than Pokemon

### API Availability
| API Provider | Free Tier | Coverage | Verdict |
|--------------|-----------|----------|---------|
| SportsCardsPro | NO (paid only) | MLB, NBA, NFL, NHL | Professional, expensive |
| Card Hedger | NO (contact sales) | Sports + TCG | Enterprise-focused |
| PSA API | YES (100/day) | PSA graded only | Too limited for MVP |
| eBay API | YES (limited) | All cards | Unreliable, restricted |
| CollX | NO (no API) | 20M+ cards | Best tech, not available |

**CRITICAL:** No comprehensive free API exists for MVP testing.

---

## Cost Analysis

### Pokemon (Current)
- API Cost: $0/month
- Development: 2-3 months
- Complexity: BASELINE

### Sports Cards (Estimated)
- API Cost: $100-500/month
- Development: 6-12 months (single sport → full support)
- Complexity: 10-20x Pokemon

---

## Major Challenges

1. **No Free Tier** - Cannot test market fit without significant investment
2. **Data Complexity** - 30+ fields vs 10 for Pokemon, 50-200 variants per card
3. **Real-Time Pricing** - Player injuries/performance = overnight value changes
4. **Grading Multipliers** - PSA 10 vs PSA 9 = 2-5x price difference
5. **Parallel Tracking** - Same card in 100+ variations (colors, serial numbers)
6. **Market Fragmentation** - Must aggregate eBay + COMC + Goldin + PSA
7. **Player Context** - Must track injuries, team changes, performance stats
8. **Image Scarcity** - APIs don't provide card images (requires scraping)

---

## Data Model Comparison

### Pokemon Card
```
- Card ID (unique)
- Name
- Set
- 3-5 variants
- Static pricing
```

### Sports Card
```
- Player (with fuzzy matching)
- Year, Sport, Brand, Product Line
- Card Number
- Parallel Type, Color, Serial Number
- Autograph, Memorabilia Type
- Grading Company (PSA/BGS/SGC/CGC)
- Grade (1-10) + Sub-grades (BGS)
- Player Stats (dynamic)
- Injury Status (real-time)
- 50-200+ variants per player/year/set
```

**Field Count:** 10 → 30+ (3x increase)
**Variants per Card:** 3-5 → 50-200 (40x increase)

---

## Pricing Volatility Examples

### Pokemon (Stable)
- Charizard Base Set PSA 10: $5,000-6,000 (steady)
- 24-hour price cache = perfectly acceptable

### Sports Cards (Volatile)
- Player injury announced → **-50% in 24 hours**
- Playoff breakout performance → **+300% in 48 hours**
- Hall of Fame induction → **+200% permanent**
- 24-hour cache = unacceptable, needs hourly updates

---

## Recommended Timeline

### V1: Pokemon TCG (Current)
- **Timeline:** 2-3 months
- **Cost:** $0/month API
- **Status:** In progress

### V2: Magic: The Gathering
- **Timeline:** +2-3 months
- **Cost:** $0/month (Scryfall API free)
- **Complexity:** 30% of V1 (reuse architecture)

### V3: Yu-Gi-Oh (Optional)
- **Timeline:** +1-2 months
- **Cost:** $0/month (YGOPRODeck API free)
- **Complexity:** 20% of V1

### V4A: Sports Cards - Single Sport MVP
- **Timeline:** +4-6 months after V3
- **Cost:** $200-300/month API
- **Budget Needed:** $10K+ (API + testing + dev time)
- **Prerequisites:**
  - 1000+ active users on TCG version
  - Positive cash flow
  - User demand validated

### V4B: Multi-Sport Expansion
- **Timeline:** +3-4 months after V4A
- **Cost:** $400-600/month
- **Only if:** V4A proves successful

### V4C: Advanced Features (Image Recognition, Real-time Alerts)
- **Timeline:** +6-12 months after V4B
- **Cost:** $800-1500/month + ML infrastructure
- **Effort:** 2000-3000 hours

**Total for Full Sports Support: 2-3 developer-years, $30K-60K**

---

## Go/No-Go Criteria for Sports Cards

### MUST HAVE before attempting:

- [ ] 1000+ active users on Pokemon/Magic
- [ ] 40%+ retention at 90 days
- [ ] $5K+ monthly revenue (positive cash flow)
- [ ] $10K+ budget secured for sports card development
- [ ] 20-30 user interviews validating sports card demand
- [ ] Team member with sports card domain expertise
- [ ] 6-month API cost runway ($1200-1800)

### RED FLAGS (do not proceed):

- [ ] TCG version has <500 users
- [ ] Revenue not covering development costs
- [ ] Users not willing to pay premium for sports cards
- [ ] Team lacks sports card knowledge
- [ ] Cannot commit 6+ months of development time

---

## Alternative Strategy: TCG Mastery

Instead of sports cards, consider becoming **the best TCG app**:

### Additional TCGs to Add:
- Flesh and Blood (growing market)
- One Piece (hot new TCG, 2023 launch)
- Digimon
- Dragon Ball Super
- Weiss Schwarz

### TCG-Specific Features:
- Deck building tools
- Tournament tracking
- Trade matching
- Set completion tracking
- Investment portfolio analytics

### Advantages:
- Stay in free API ecosystem
- Lower complexity = faster velocity
- Clearer market positioning (TCG specialist vs generalist)
- Younger collector demographic (higher app adoption)
- Avoid sports card volatility/complexity

### Market Size:
- Global TCG market: $7.5B (2025, growing 10-15% annually)
- Pokemon secondary market: $1.5B+
- Magic secondary market: $1B+

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| No free API for MVP | HIGH | Budget $200-300/mo, start after cash flow positive |
| Pricing accuracy <90% | CRITICAL | Multi-source aggregation, confidence scores |
| User unwilling to pay premium | HIGH | Validate demand first, offer free tier with limits |
| Development takes 2x longer | HIGH | Start with single sport, limit scope |
| API providers restrict access | MEDIUM | Build scraping fallbacks, diversify sources |
| Sports card market crashes | LOW | Diversify TCG+sports, focus on show dealers |

---

## Final Recommendation

**DEFER sports cards until V4+ based on these criteria:**

1. **Proven TCG Success**
   - 1000+ active users
   - $5K+ monthly revenue
   - 40%+ 90-day retention

2. **Budget Secured**
   - $10K+ for V4A single sport MVP
   - 6-month API cost runway
   - Testing/sample card budget

3. **User Demand Validated**
   - 20-30 user interviews
   - Willingness to pay $5-10/mo premium
   - Show dealer interest confirmed

4. **Technical Foundation Ready**
   - Caching proven reliable at scale
   - Search UX refined
   - Team has capacity for 6-month project

**If proceeding with sports cards:**
- Start with ONE sport (baseball or basketball)
- Limit to base cards + major parallels (no variations initially)
- Partner with ONE data provider
- Set realistic expectations (4-12 hour updates, not real-time)
- Charge premium ($5-10/month sports card access)
- Build confidence scoring (price ranges, not absolutes)

**Better approach for small team:**
- Master Pokemon/Magic/Yu-Gi-Oh (9-12 months)
- Add more TCGs (Flesh and Blood, One Piece, etc.)
- Build TCG-specific features (deck building, tournaments)
- Become "best TCG app" vs "mediocre everything app"
- Revisit sports cards in 2027 after TCG dominance proven

---

## Bottom Line

**Sports cards are technically feasible but commercially risky for an early-stage product.**

The 10-20x complexity increase, lack of free APIs, and volatile pricing model make sports cards **unsuitable for MVP validation** but potentially **viable for V4+ expansion** with proper budget, planning, and proven TCG success.

**Focus on TCG excellence first. Add sports cards only after achieving product-market fit and securing budget.**

---

See **SPORTS_CARD_API_RESEARCH.md** for complete technical details, API documentation, code examples, and competitive analysis.
