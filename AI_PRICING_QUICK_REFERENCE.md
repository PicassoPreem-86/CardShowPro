# AI API Pricing Quick Reference
**Updated:** January 13, 2026

## Cost Per 1,000 Requests Comparison

### Card Analyzer (Vision + Analysis)
Assumptions: 1K input tokens + 500 output tokens per request

| Provider | Model | Cost per 1K requests | Monthly (10K) | Annual (120K) |
|----------|-------|---------------------|---------------|---------------|
| Google | Gemini 2.5 Flash | **$0.00** (free tier) or $0.75 | $0 or $7.50 | $0 or $90 |
| OpenAI | GPT-4o-mini | $0.22 | $2.25 | $27 |
| OpenAI | GPT-4o | $3.75 | $37.50 | $450 |
| Anthropic | Claude 3.5 Haiku | $0.75 | $7.50 | $90 |
| Anthropic | Claude 3.5 Sonnet | $10.50 | $105.00 | $1,260 |
| Ximilar | Card Grading API | $9.60-19.20* | $96-192 | $1,152-2,304 |
| Replicate | Llama 3.2 Vision | $5.00 | $50.00 | $600 |

*Estimated based on €59/100K credits, 10-20 credits per analysis

---

### Listing Generator (Text Only)
Assumptions: 500 input tokens + 1K output tokens per request

| Provider | Model | Cost per 1K requests | Monthly (5K) | Annual (60K) |
|----------|-------|---------------------|--------------|---------------|
| Google | Gemini 2.5 Flash | **$0.00** (free tier) or $0.68 | $0 or $3.38 | $0 or $40.56 |
| OpenAI | GPT-4o-mini | $0.68 | $3.38 | $40.56 |
| Anthropic | Claude 3.5 Haiku | $1.00 | $5.00 | $60 |
| OpenAI | GPT-4o | $6.25 | $31.25 | $375 |
| Anthropic | Claude 3.5 Sonnet | $16.50 | $82.50 | $990 |
| Google | Gemini 2.5 Pro | $2.50 | $12.50 | $150 |

---

### Market Agent (Text + Analysis)
Assumptions: 800 input tokens + 800 output tokens per request

| Provider | Model | Cost per 1K requests | Monthly (20K) | Annual (240K) |
|----------|-------|---------------------|---------------|---------------|
| Google | Gemini 2.5 Flash | **$0.00** (free tier) or $0.60 | $0 or $12.00 | $0 or $144 |
| OpenAI | GPT-4o-mini | $0.60 | $12.00 | $144 |
| Anthropic | Claude 3.5 Haiku | $1.20 | $24.00 | $288 |
| Google | Gemini 2.5 Pro | $2.40 | $48.00 | $576 |
| OpenAI | GPT-4o | $10.00 | $200.00 | $2,400 |
| Anthropic | Claude 3.5 Sonnet | $14.40 | $288.00 | $3,456 |

---

## Total Monthly Cost by Stack Configuration

### Stack A: All Free (Launch Recommended)
```
Card Analyzer:     Gemini 2.5 Flash (Free)    $0.00
Listing Generator: Gemini 2.5 Flash (Free)    $0.00
Market Agent:      Gemini 2.5 Flash (Free)    $0.00
                                              -------
TOTAL:                                         $0.00/month
```
**Best for:** V3 launch, testing features, minimizing risk

---

### Stack B: Hybrid Free + Premium Text
```
Card Analyzer:     Gemini 2.5 Flash (Free)    $0.00
Listing Generator: GPT-4o-mini                $3.38
Market Agent:      Gemini 2.5 Flash (Free)    $0.00
                                              -------
TOTAL:                                         $3.38/month
```
**Best for:** Better listing quality while keeping costs minimal

---

### Stack C: All OpenAI (Single Provider)
```
Card Analyzer:     GPT-4o-mini                $2.25
Listing Generator: GPT-4o-mini                $3.38
Market Agent:      GPT-4o-mini               $12.00
                                              -------
TOTAL:                                        $17.63/month
```
**Best for:** Simplicity, single API integration, predictable billing

---

### Stack D: All Claude (Premium Quality)
```
Card Analyzer:     Claude 3.5 Sonnet        $105.00
Listing Generator: Claude 3.5 Haiku           $5.00
Market Agent:      Claude 3.5 Sonnet        $288.00
                                              -------
TOTAL:                                       $398.00/month
```
**Best for:** Maximum reasoning quality (expensive!)

---

### Stack E: Best-in-Class (Specialized)
```
Card Analyzer:     Ximilar (87% PSA accuracy) $96-192
Listing Generator: Claude 3.5 Haiku            $5.00
Market Agent:      Claude 3.5 Sonnet         $288.00
                                              -------
TOTAL:                                   $389-485/month
```
**Best for:** Competitive differentiation, accuracy is critical

---

### Stack F: Balanced Quality/Cost
```
Card Analyzer:     Gemini 2.5 Flash (Paid)    $7.50
Listing Generator: GPT-4o-mini                $3.38
Market Agent:      Gemini 2.5 Pro            $48.00
                                              -------
TOTAL:                                        $58.88/month
```
**Best for:** Proven features, moderate scale, quality-conscious

---

## Free Tier Limits

### Google Gemini (AI Studio - Free Tier)
- **Rate Limits:** 5-15 requests per minute
- **Token Limits:** 250,000 tokens per minute
- **Daily Limits:** ~1,000 requests per day (varies by model)
- **Context Window:** Up to 1M tokens
- **Duration:** Unlimited (subject to change)
- **Data Usage:** Google may use inputs/outputs for improvement
- **Restriction:** US only (as of Jan 2026)

**Our Usage Fit:**
- 35K requests/month ÷ 30 days = ~1,167 requests/day
- 1,167 ÷ 1,440 minutes = ~0.8 requests/minute
- **✅ FITS COMFORTABLY IN FREE TIER**

---

### OpenAI (No Free Tier)
- **Tier 1:** Requires $5+ payment history
- **Rate Limits:** 30,000 tokens per minute (Tier 1)
- **Pay-as-you-go:** Starts at $0 balance
- **Minimum Purchase:** $5

---

### Anthropic Claude (Chat Free, API Paid)
- **Free Chat:** Web interface only, no API access
- **API:** Requires paid account
- **Pro Plan:** $20/month (chat only, not API)

---

### Ximilar
- **Free Tier:** 3,000 credits/month
- **Business Plan:** €59/month for 100,000 credits
- **Card Analysis:** ~10-20 credits per request
- **Free Tier Capacity:** ~150-300 card analyses
- **Our Usage:** 10K/month = Requires business plan

---

### Hugging Face
- **Free Tier:** Limited rate limits, community models
- **Pro Plan:** $9/month (20× credits, not API credits)
- **Inference API:** Pay-as-you-go at provider rates
- **Free Models:** Limited quality/speed

---

## Cost as % of Revenue

Assuming 1,000 paid users × $9.99/month = $9,990 MRR:

| Stack | Monthly Cost | % of MRR | Break-even Users | Profit per User |
|-------|--------------|----------|------------------|-----------------|
| Stack A (Free) | $0 | 0.00% | 0 | $9.99 |
| Stack B (Hybrid) | $3.38 | 0.03% | 1 | $9.99 |
| Stack C (OpenAI) | $17.63 | 0.18% | 2 | $9.98 |
| Stack F (Balanced) | $58.88 | 0.59% | 6 | $9.93 |
| Stack E (Premium) | $389-485 | 3.9-4.9% | 39-49 | $9.50-9.60 |

**Analysis:** Even the most expensive stack costs < 5% of revenue, which is excellent for SaaS margins.

---

## Token Usage Estimates

### Card Analyzer
**Input:**
- System prompt: ~200 tokens
- Card image (front): ~500 tokens (vision encoding)
- Card image (back): ~500 tokens (vision encoding)
- Analysis instructions: ~300 tokens
- **Total Input:** ~1,500 tokens (rounded to 1K in calculations)

**Output:**
- Grade estimate: ~50 tokens
- Centering analysis: ~100 tokens
- Corner/edge/surface details: ~200 tokens
- Confidence score + reasoning: ~150 tokens
- **Total Output:** ~500 tokens

---

### Listing Generator
**Input:**
- System prompt: ~150 tokens
- Card details (name, set, condition): ~100 tokens
- Platform requirements (eBay/TCGPlayer): ~100 tokens
- SEO instructions: ~150 tokens
- **Total Input:** ~500 tokens

**Output:**
- SEO title: ~20 tokens
- Description: ~400 tokens
- Keywords/hashtags: ~80 tokens
- **Total Output:** ~500 tokens (allow up to 1K for detailed listings)

---

### Market Agent
**Input:**
- System prompt: ~200 tokens
- Card details: ~100 tokens
- Pricing history: ~300 tokens
- Market trends: ~200 tokens
- **Total Input:** ~800 tokens

**Output:**
- Recommendation (Buy/Sell/Hold): ~50 tokens
- Reasoning (3-5 bullets): ~400 tokens
- Confidence score: ~50 tokens
- Supporting data: ~300 tokens
- **Total Output:** ~800 tokens

---

## Rate Limit Planning

### Gemini Free Tier
- **15 RPM limit**
- Our usage: ~0.8 RPM average
- Peak usage (5x average): ~4 RPM
- **✅ Headroom:** 11 RPM available for spikes

### OpenAI Tier 1
- **30,000 TPM (tokens per minute)**
- Card Analyzer: 1.5K tokens × 10 req = 15K tokens/min (if all at once)
- **⚠️ Potential limit hit during peak usage**
- Solution: Implement request queuing

### Rate Limit Mitigation
1. **Queue system:** Non-urgent requests (listings, market analysis)
2. **Caching:** Store results for 7 days, reuse for duplicate cards
3. **Batch processing:** Group multiple analyses
4. **Exponential backoff:** Retry failed requests with delays

---

## Development Considerations

### API SDK Availability
| Provider | Swift SDK | REST API | Authentication | Ease of Use |
|----------|-----------|----------|----------------|-------------|
| OpenAI | ✅ Official | ✅ Yes | API Key | Easy |
| Anthropic | ✅ Official | ✅ Yes | API Key | Easy |
| Google Gemini | ❌ None | ✅ Yes | API Key | Moderate |
| Ximilar | ❌ None | ✅ Yes | Token | Moderate |
| Replicate | ❌ None | ✅ Yes | API Key | Moderate |

---

### Integration Time Estimates
| Provider | Setup | Testing | Production-Ready |
|----------|-------|---------|------------------|
| OpenAI | 2 hours | 4 hours | 1 day |
| Anthropic | 2 hours | 4 hours | 1 day |
| Google Gemini | 4 hours | 6 hours | 2 days |
| Ximilar | 3 hours | 8 hours | 2 days |
| Multi-provider fallback | +8 hours | +12 hours | +3 days |

---

## Optimization Tips

### Reduce Token Usage
1. **Shorter prompts:** Remove unnecessary instructions
2. **Structured output:** Use JSON mode to reduce verbose responses
3. **Image compression:** Resize card images to 1024×1024 max
4. **Prompt caching:** Cache system prompts (Anthropic feature)

### Improve Response Time
1. **Parallel requests:** Send front/back images simultaneously
2. **Async processing:** Don't block UI while waiting
3. **Prefetch:** Predict user actions and pre-call API
4. **Edge caching:** Use CDN for common card data

### Reduce Costs
1. **Caching layer:** SwiftData + 7-day TTL
2. **Duplicate detection:** Don't re-analyze same card
3. **Batch processing:** Queue non-urgent requests
4. **Free tier maximization:** Use Gemini first, fallback to paid

---

## Decision Matrix

Choose your stack based on priorities:

| Priority | Recommended Stack | Cost | Quality |
|----------|------------------|------|---------|
| **Lowest cost** | Stack A (All Free) | $0/mo | Good |
| **Best balance** | Stack B (Hybrid) | $3/mo | Excellent |
| **Single provider** | Stack C (OpenAI) | $18/mo | Excellent |
| **Best quality** | Stack E (Specialized) | $390-485/mo | Best |
| **Simplicity** | Stack C (OpenAI) | $18/mo | Excellent |
| **Scalability** | Stack F (Balanced Paid) | $59/mo | Excellent |

---

## Action Items

- [ ] Decide on Stack (A, B, C, E, or F)
- [ ] Create API accounts
- [ ] Get API keys
- [ ] Set up billing alerts ($50, $100, $200 thresholds)
- [ ] Implement rate limiting in code
- [ ] Add caching layer (SwiftData)
- [ ] Build fallback logic (optional)
- [ ] Test with 100 sample cards
- [ ] Monitor costs for 30 days
- [ ] Adjust based on actual usage

---

**RECOMMENDATION:** Start with **Stack A (All Free)** for V3 launch. Monitor for 30-60 days, then upgrade selectively based on user feedback and usage patterns.
