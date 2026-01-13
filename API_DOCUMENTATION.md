# CardShow Pro - API Documentation

**Version:** 1.0
**Last Updated:** January 13, 2026
**Document Owner:** Engineering Team
**Status:** Active Development

---

## Table of Contents

1. [Overview](#overview)
2. [API Dependencies Summary](#api-dependencies-summary)
3. [PokemonTCG.io API (Active)](#pokemontcgio-api-active)
4. [TCGPlayer API (Planned)](#tcgplayer-api-planned)
5. [eBay API (Planned)](#ebay-api-planned)
6. [OpenAI API (Planned - AI Features)](#openai-api-planned---ai-features)
7. [API Client Architecture](#api-client-architecture)
8. [Error Handling Strategy](#error-handling-strategy)
9. [Rate Limiting & Throttling](#rate-limiting--throttling)
10. [Caching Strategy](#caching-strategy)
11. [Offline Mode & Fallback Behavior](#offline-mode--fallback-behavior)
12. [API Key Management & Security](#api-key-management--security)
13. [Testing Strategy](#testing-strategy)
14. [Monitoring & Analytics](#monitoring--analytics)

---

## Overview

CardShow Pro relies on multiple external APIs to provide card data, pricing information, market insights, and AI-powered features. This document serves as the central reference for all API integrations.

### Design Principles

1. **API-Agnostic Architecture** - Business logic doesn't depend on specific API implementations
2. **Graceful Degradation** - App remains functional when APIs are unavailable
3. **Caching-First** - Minimize API calls through intelligent caching
4. **Rate Limit Awareness** - Respect all API rate limits to avoid service interruptions
5. **Security-First** - Never expose API keys in client code

---

## API Dependencies Summary

| API | Status | Purpose | Cost | Rate Limits | Authentication |
|-----|--------|---------|------|-------------|----------------|
| **PokemonTCG.io** | ✅ Active | Pokemon card data, images | Free | 20,000 requests/day | None (public) |
| **TCGPlayer** | 🔄 Planned | Multi-game pricing data | TBD | TBD | API Key + OAuth |
| **eBay** | 🔄 Planned | Sold listings, market data | Free tier | 5,000 calls/day | OAuth 2.0 |
| **OpenAI** | 🔄 Planned | AI features (grading, insights, listings) | Pay-per-token | Rate limits vary by tier | API Key |

### Dependency Risk Assessment

| API | Business Impact if Unavailable | Mitigation |
|-----|-------------------------------|------------|
| PokemonTCG.io | HIGH - Price lookup fails | Cache recent searches, fallback to TCGPlayer |
| TCGPlayer | MEDIUM - Less accurate pricing | Use PokemonTCG.io as fallback |
| eBay | LOW - Market insights unavailable | Feature degrades gracefully |
| OpenAI | LOW - AI features disabled | Clear messaging, manual alternatives |

---

## PokemonTCG.io API (Active)

### Overview

**Base URL:** `https://api.pokemontcg.io/v2/`
**Documentation:** https://docs.pokemontcg.io/
**Authentication:** None required (public API)
**Rate Limit:** 20,000 requests per day (~833/hour, ~14/minute)
**Cost:** Free

### Current Usage

CardShow Pro uses PokemonTCG.io for:
- Card search by name
- Card details (image, set, number, variants)
- TCGPlayer pricing data (market, low, mid, high)
- Set information

### Endpoints Used

#### 1. Search Cards

**Endpoint:** `GET /cards`

**Query Parameters:**
```
q=name:"Charizard" set.name:"Base Set"
orderBy=name
page=1
pageSize=20
```

**Example Request:**
```swift
let baseURL = "https://api.pokemontcg.io/v2/cards"
var components = URLComponents(string: baseURL)
components?.queryItems = [
    URLQueryItem(name: "q", value: "name:\"\(cardName)\""),
    URLQueryItem(name: "orderBy", value: "name"),
    URLQueryItem(name: "pageSize", value: "20")
]

let request = URLRequest(url: components!.url!)
let (data, response) = try await URLSession.shared.data(for: request)
```

**Response Format:**
```json
{
  "data": [
    {
      "id": "base1-4",
      "name": "Charizard",
      "supertype": "Pokémon",
      "number": "4",
      "set": {
        "id": "base1",
        "name": "Base Set",
        "series": "Base",
        "printedTotal": 102,
        "total": 102,
        "releaseDate": "1999/01/09",
        "images": {
          "symbol": "https://images.pokemontcg.io/base1/symbol.png",
          "logo": "https://images.pokemontcg.io/base1/logo.png"
        }
      },
      "images": {
        "small": "https://images.pokemontcg.io/base1/4.png",
        "large": "https://images.pokemontcg.io/base1/4_hires.png"
      },
      "tcgplayer": {
        "url": "https://prices.pokemontcg.io/tcgplayer/base1-4",
        "updatedAt": "2026/01/13",
        "prices": {
          "holofoil": {
            "low": 150.00,
            "mid": 180.00,
            "high": 250.00,
            "market": 175.00,
            "directLow": null
          },
          "normal": {
            "low": 50.00,
            "mid": 75.00,
            "high": 100.00,
            "market": 70.00,
            "directLow": null
          }
        }
      }
    }
  ],
  "page": 1,
  "pageSize": 20,
  "count": 15,
  "totalCount": 15
}
```

**Key Fields:**
- `id` - Unique card identifier
- `name` - Card name
- `number` - Card number within set
- `set.name` - Set name (e.g., "Base Set")
- `images.large` - High-res card image URL
- `tcgplayer.prices` - Pricing data by variant

#### 2. Get Card by ID

**Endpoint:** `GET /cards/{id}`

**Example Request:**
```swift
let url = URL(string: "https://api.pokemontcg.io/v2/cards/base1-4")!
let (data, response) = try await URLSession.shared.data(from: url)
```

**Response:** Single card object (same structure as search results)

**Use Case:** Fetching full details after user selects from search results

#### 3. Get Sets

**Endpoint:** `GET /sets`

**Example Request:**
```swift
let url = URL(string: "https://api.pokemontcg.io/v2/sets")!
let (data, response) = try await URLSession.shared.data(from: url)
```

**Response:**
```json
{
  "data": [
    {
      "id": "base1",
      "name": "Base Set",
      "series": "Base",
      "printedTotal": 102,
      "total": 102,
      "releaseDate": "1999/01/09",
      "images": {
        "symbol": "https://images.pokemontcg.io/base1/symbol.png",
        "logo": "https://images.pokemontcg.io/base1/logo.png"
      }
    }
  ]
}
```

**Use Case:** Populating set selection dropdown, showing set logos

### Current Implementation

**Location:** `CardShowProPackage/Sources/CardShowProFeature/Services/PokemonTCGService.swift`

**Key Methods:**
```swift
actor PokemonTCGService {
    static let shared = PokemonTCGService()

    // Search cards by name
    func searchCards(query: String) async throws -> [PokemonCard]

    // Get card details by ID
    func getCard(id: String) async throws -> PokemonCard

    // Get pricing for specific card
    func getPricing(cardId: String) async throws -> CardPricing
}
```

### Rate Limit Handling

**Current Strategy:**
- No explicit rate limiting (relying on 20K/day generous limit)
- Consider adding if user base grows significantly

**Future Enhancement:**
```swift
actor RateLimiter {
    private var requestCount = 0
    private var windowStart = Date()
    private let maxRequestsPerMinute = 14

    func checkRateLimit() async throws {
        let now = Date()
        if now.timeIntervalSince(windowStart) > 60 {
            requestCount = 0
            windowStart = now
        }

        guard requestCount < maxRequestsPerMinute else {
            throw APIError.rateLimitExceeded
        }

        requestCount += 1
    }
}
```

### Known Limitations

1. **Pokemon Only** - Does not support other TCGs (Magic, Yu-Gi-Oh, sports cards)
2. **Pricing Freshness** - Pricing data updated daily, not real-time
3. **Incomplete Data** - Some older sets missing pricing information
4. **No Graded Card Pricing** - Only raw card prices available

### Error Scenarios

| HTTP Status | Meaning | Handling |
|------------|---------|----------|
| 200 | Success | Parse and return data |
| 400 | Bad Request (invalid query) | Show user-friendly error, log for debugging |
| 404 | Card not found | Display "No results found" message |
| 429 | Rate limit exceeded | Queue request, retry after delay |
| 500 | Server error | Retry with exponential backoff, use cache if available |
| Network timeout | No connection | Use cached data, show offline message |

---

## TCGPlayer API (Planned)

### Overview

**Base URL:** `https://api.tcgplayer.com/`
**Documentation:** https://docs.tcgplayer.com/
**Authentication:** API Key + OAuth 2.0
**Rate Limit:** TBD (requires partnership discussion)
**Cost:** Free tier available, paid tiers for higher volumes

### Why TCGPlayer?

1. **Multi-Game Support** - Pokemon, Magic, Yu-Gi-Oh, sports cards, One Piece TCG
2. **Authoritative Pricing** - Industry standard for card pricing
3. **Real-Time Data** - More accurate than PokemonTCG.io
4. **Graded Card Pricing** - Includes PSA/BGS graded card values
5. **Market Insights** - Historical trends, popularity data

### Planned Endpoints

#### 1. Get Pricing by Product ID

**Endpoint:** `GET /pricing/product/{productId}`

**Use Case:** Fetch current market prices after card identified

#### 2. Search Products

**Endpoint:** `GET /catalog/products`

**Query Parameters:**
- `categoryId` - Game type (Pokemon = 3, Magic = 1, etc.)
- `productName` - Card name
- `setName` - Set name

**Use Case:** Find card when user searches

#### 3. Get Market Prices

**Endpoint:** `GET /pricing/marketprices/{productId}`

**Response Includes:**
- Market price (current average)
- Low price (cheapest listing)
- Mid price
- High price
- Listing count (how many available)

#### 4. Get Price History

**Endpoint:** `GET /pricing/history/{productId}`

**Use Case:** Pro Market Agent trend analysis

### Authentication Flow

**Step 1: Obtain Access Token**
```swift
struct TCGPlayerAuth {
    let clientId: String
    let clientSecret: String

    func getAccessToken() async throws -> String {
        let url = URL(string: "https://api.tcgplayer.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=client_credentials&client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        return response.accessToken
    }
}
```

**Step 2: Use Token in Requests**
```swift
var request = URLRequest(url: apiURL)
request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
```

**Token Refresh:**
- Access tokens expire after 2 weeks
- Store token securely in Keychain
- Refresh before expiration

### Integration Priority

**V2 Release (Q3 2026):**
- Basic pricing lookup (replace PokemonTCG.io where available)
- Multi-game support (One Piece TCG, sports cards)

**V3 Release (Q4 2026):**
- Historical pricing for Pro Market Agent
- Graded card pricing
- Market trend analysis

### Partnership Requirements

**Needed from TCGPlayer:**
1. API access approval (apply for developer account)
2. Rate limit increases for production use
3. White-labeling permission (display TCGPlayer prices without forcing marketplace link)
4. Pricing data usage rights in mobile app

**Action Items:**
- [ ] Apply for TCGPlayer developer account (Target: Feb 2026)
- [ ] Negotiate partnership terms (Target: Mar 2026)
- [ ] Implement OAuth flow (Target: Apr 2026)
- [ ] Build TCGPlayer API client (Target: May 2026)

---

## eBay API (Planned)

### Overview

**Base URL:** `https://api.ebay.com/`
**Documentation:** https://developer.ebay.com/
**Authentication:** OAuth 2.0
**Rate Limit:** 5,000 calls/day (free tier)
**Cost:** Free tier available

### Why eBay?

1. **Sold Listings Data** - Real market prices (what cards actually sold for, not just asking prices)
2. **Market Validation** - Confirm TCGPlayer/PokemonTCG.io pricing accuracy
3. **Trending Insights** - Identify hot cards based on recent sales
4. **Platform Fee Calculator** - Official eBay fee structure for Sales Calculator feature

### Planned Endpoints

#### 1. Search Sold Listings

**Endpoint:** `GET /buy/browse/v1/item_summary/search`

**Query Parameters:**
- `q` - Search query (card name)
- `filter=buyingOptions:{AUCTION|FIXED_PRICE},conditionIds:{1000|3000}` - Filters
- `fieldgroups=EXTENDED` - Include pricing details
- `limit=50` - Results per page

**Use Case:** Pro Market Agent - analyze recent sold prices to determine market trends

**Example Response:**
```json
{
  "itemSummaries": [
    {
      "itemId": "1234567890",
      "title": "Pokemon Charizard Base Set 4/102 Holo PSA 9",
      "price": {
        "value": "350.00",
        "currency": "USD"
      },
      "condition": "Used",
      "itemWebUrl": "https://ebay.com/itm/1234567890",
      "image": {
        "imageUrl": "https://..."
      },
      "seller": {
        "username": "card_seller123",
        "feedbackPercentage": "99.5"
      },
      "lastSoldDate": "2026-01-10T15:30:00Z"
    }
  ]
}
```

#### 2. Get Fee Structure

**Endpoint:** `GET /sell/account/v1/policy/seller_policies`

**Use Case:** Sales Calculator - accurate eBay fee calculations

**Fee Types:**
- Insertion fee (listing fee)
- Final value fee (percentage of sale)
- Payment processing fee
- Optional upgrade fees (bold listing, featured, etc.)

### Authentication Flow

Similar to TCGPlayer OAuth flow.

### Integration Priority

**V3 Release (Q4 2026):**
- Sold listings search for Pro Market Agent
- Fee structure for Sales Calculator

**Future:**
- Auto-listing integration (post listings directly from CardShow Pro)

---

## OpenAI API (Planned - AI Features)

### Overview

**Base URL:** `https://api.openai.com/v1/`
**Documentation:** https://platform.openai.com/docs/
**Authentication:** API Key
**Rate Limit:** Varies by tier (60 requests/minute on free tier)
**Cost:** Pay-per-token (~$0.002 per request for GPT-4o-mini)

### Why OpenAI?

1. **Card Analyzer** - Image analysis for grading suggestions
2. **Pro Market Agent** - Natural language market insights
3. **Listing Generator** - SEO-optimized listing copywriting

### Planned Use Cases

#### 1. Card Analyzer (Grading Assistant)

**Endpoint:** `POST /chat/completions` (with vision)

**Request:**
```swift
struct CardAnalysisRequest {
    let model = "gpt-4o"
    let messages: [Message]

    struct Message {
        let role: String // "user"
        let content: [Content]

        struct Content {
            let type: String // "text" or "image_url"
            let text: String?
            let imageUrl: ImageURL?

            struct ImageURL {
                let url: String // base64 encoded image
            }
        }
    }
}
```

**Prompt Example:**
```
You are a professional card grader. Analyze this Pokemon card image and provide:
1. Centering score (0-100, where 100 is perfectly centered)
2. Edge condition (Mint/Near Mint/Excellent/Good/Poor)
3. Corner condition (Sharp/Slightly Worn/Worn/Damaged)
4. Surface condition (Clean/Minor Scratches/Scratches/Heavy Wear)
5. Estimated PSA grade (1-10)
6. Confidence level (0-100%)

Be conservative in your estimate. Only suggest PSA 10 if the card appears flawless.
```

**Response Parsing:**
```json
{
  "centering": 95,
  "edges": "Near Mint",
  "corners": "Sharp",
  "surface": "Clean",
  "estimatedGrade": 9,
  "confidence": 75,
  "notes": "Card shows excellent centering (95/100). Edges and corners appear sharp. Minor surface imperfection visible in top-right. Conservative estimate: PSA 9."
}
```

**Cost Estimate:**
- Image analysis: ~1,000 tokens per request
- GPT-4o: $0.0025 per 1K tokens = $0.0025 per card analysis
- If 1,000 users analyze 10 cards/month = 10,000 analyses/month = $25/month

#### 2. Listing Generator

**Endpoint:** `POST /chat/completions`

**Prompt Example:**
```
Generate an eBay listing for this card:
- Card: Charizard VMAX 020/189
- Set: Darkness Ablaze
- Condition: Near Mint
- Platform: eBay

Requirements:
- Title: 80 characters max, SEO-optimized, include key search terms
- Description: 3-5 sentences, highlight card features, mention condition, shipping details
- Tone: Professional but friendly, builds buyer confidence

Output as JSON: {"title": "...", "description": "..."}
```

**Response:**
```json
{
  "title": "Pokemon Charizard VMAX 020/189 Darkness Ablaze Holo Rare NM - Fast Ship!",
  "description": "Stunning Charizard VMAX from the Darkness Ablaze set in Near Mint condition. This highly sought-after holo rare features vibrant colors and sharp corners. Perfect for collectors or competitive players looking to power up their deck. Card ships securely in a penny sleeve and top loader within 24 hours. Buy with confidence from a trusted seller!"
}
```

**Cost Estimate:**
- ~500 tokens per generation
- GPT-4o-mini: $0.00015 per 1K tokens = $0.000075 per listing
- Negligible cost (<$10/month even with heavy use)

#### 3. Pro Market Agent (Market Insights)

**Endpoint:** `POST /chat/completions`

**Prompt Example:**
```
Analyze this pricing data for Charizard Base Set Holo:
- Current market price: $180
- 30-day average: $170
- 90-day average: $150
- Recent sold listings: $175, $185, $190, $178, $182

Provide:
1. Trend direction (Rising/Falling/Stable)
2. Percentage change (30-day)
3. Recommendation (Buy/Sell/Hold)
4. Confidence level
5. Brief explanation (2-3 sentences)

Output as JSON.
```

**Response:**
```json
{
  "trend": "Rising",
  "percentageChange": 5.9,
  "recommendation": "Sell",
  "confidence": 80,
  "explanation": "Charizard Base Set Holo has increased 5.9% over the past 30 days with consistent upward momentum. Recent sold listings show strong demand at $180+ range. Good opportunity to capitalize on current peak pricing before potential market correction."
}
```

### Rate Limit Management

**Strategy:**
- Cache AI responses for 24 hours (same card + same request = cached result)
- Queue requests during high load
- Show loading indicators for AI features (acceptable 2-5 second latency)

**Fallback:**
- If rate limit hit → show "AI temporarily unavailable, try again in 1 minute"
- If API down → disable AI features gracefully

### Cost Management

**Monthly Budget Estimate (1,000 paid users):**
- Card Analyzer: 10 analyses/user/month = 10,000 requests = $25
- Listing Generator: 5 listings/user/month = 5,000 requests = $0.38
- Pro Market Agent: 20 insights/user/month = 20,000 requests = $3
- **Total: ~$30/month** (affordable at $9,990 MRR)

**Scaling Strategy:**
- Monitor usage per user
- Consider usage caps on free tier (e.g., 5 AI analyses per month)
- Unlimited AI on paid tier

---

## API Client Architecture

### Design Pattern: Protocol-Based Abstraction

**Why:**
- Decouple business logic from specific API implementations
- Easy to swap providers (e.g., PokemonTCG.io → TCGPlayer)
- Mockable for testing

**Example:**
```swift
// Protocol defining card data API contract
protocol CardDataAPI {
    func searchCards(query: String) async throws -> [Card]
    func getCard(id: String) async throws -> Card
    func getPricing(cardId: String) async throws -> CardPricing
}

// PokemonTCG.io implementation
actor PokemonTCGClient: CardDataAPI {
    func searchCards(query: String) async throws -> [Card] {
        // Implementation
    }

    func getCard(id: String) async throws -> Card {
        // Implementation
    }

    func getPricing(cardId: String) async throws -> CardPricing {
        // Implementation
    }
}

// TCGPlayer implementation (future)
actor TCGPlayerClient: CardDataAPI {
    func searchCards(query: String) async throws -> [Card] {
        // Different implementation, same interface
    }

    // ...
}
```

### Service Layer Pattern

**Location:** `CardShowProPackage/Sources/CardShowProFeature/Services/`

**Services:**
```
Services/
├── PricingService.swift        - Orchestrates pricing from multiple sources
├── PokemonTCGService.swift     - PokemonTCG.io client
├── TCGPlayerService.swift      - TCGPlayer client (future)
├── EbayService.swift           - eBay client (future)
├── AIService.swift             - OpenAI client (future)
└── NetworkClient.swift         - Shared networking utilities
```

**Example: PricingService (Multi-Source Pricing)**
```swift
@Observable
final class PricingService {
    static let shared = PricingService()

    private let pokemonAPI: CardDataAPI
    private let tcgplayerAPI: CardDataAPI?

    init(pokemonAPI: CardDataAPI = PokemonTCGService.shared,
         tcgplayerAPI: CardDataAPI? = nil) {
        self.pokemonAPI = pokemonAPI
        self.tcgplayerAPI = tcgplayerAPI
    }

    func getPricing(cardId: String, game: CardGame) async throws -> CardPricing {
        // Try TCGPlayer first (more accurate)
        if let tcgplayerAPI = tcgplayerAPI {
            do {
                return try await tcgplayerAPI.getPricing(cardId: cardId)
            } catch {
                // Fall back to PokemonTCG.io
                print("TCGPlayer failed, falling back to PokemonTCG.io")
            }
        }

        // Use PokemonTCG.io as fallback
        return try await pokemonAPI.getPricing(cardId: cardId)
    }
}
```

### Shared Network Client

**Purpose:** Centralize common networking logic

**Features:**
- Request building
- Response parsing
- Error handling
- Logging

**Implementation:**
```swift
actor NetworkClient {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        // Add headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse JSON
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
```

---

## Error Handling Strategy

### Error Types

```swift
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case rateLimitExceeded
    case unauthorized
    case notFound
    case serverError
    case networkUnavailable
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .invalidResponse:
            return "Received invalid response from server"
        case .httpError(let code):
            return "Server returned error: \(code)"
        case .decodingError(let error):
            return "Failed to parse server response: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Too many requests. Please try again in a moment."
        case .unauthorized:
            return "Authentication failed. Please check your API credentials."
        case .notFound:
            return "Requested resource not found"
        case .serverError:
            return "Server is experiencing issues. Please try again later."
        case .networkUnavailable:
            return "No internet connection. Please check your network."
        case .timeout:
            return "Request timed out. Please try again."
        }
    }

    var userFriendlyMessage: String {
        switch self {
        case .networkUnavailable:
            return "You're offline. Some features may be limited."
        case .rateLimitExceeded:
            return "You're making requests too quickly. Please wait a moment."
        case .notFound:
            return "Card not found. Try a different search term."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
```

### Retry Logic

**Exponential Backoff:**
```swift
func fetchWithRetry<T>(
    maxAttempts: Int = 3,
    operation: @escaping () async throws -> T
) async throws -> T {
    var attempt = 0

    while attempt < maxAttempts {
        do {
            return try await operation()
        } catch {
            attempt += 1

            guard attempt < maxAttempts else {
                throw error
            }

            // Exponential backoff: 1s, 2s, 4s
            let delay = pow(2.0, Double(attempt))
            try await Task.sleep(for: .seconds(delay))
        }
    }

    fatalError("Should not reach here")
}
```

**Usage:**
```swift
let pricing = try await fetchWithRetry {
    try await pokemonAPI.getPricing(cardId: cardId)
}
```

### User-Facing Error Messages

**Design Principles:**
1. **Clear & Actionable** - Tell user what went wrong and what they can do
2. **Non-Technical** - Avoid jargon like "HTTP 500" or "JSON parsing failed"
3. **Consistent Tone** - Friendly but professional

**Example Error UI:**
```swift
struct ErrorView: View {
    let error: APIError
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text("Oops!")
                .font(.headline)

            Text(error.userFriendlyMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

---

## Rate Limiting & Throttling

### API Rate Limits Summary

| API | Limit | Window | Strategy |
|-----|-------|--------|----------|
| PokemonTCG.io | 20,000 requests | Per day | No throttling needed (generous limit) |
| TCGPlayer | TBD | TBD | Implement token bucket algorithm |
| eBay | 5,000 calls | Per day | Queue non-urgent requests |
| OpenAI | 60 requests | Per minute | Queue + cache aggressively |

### Token Bucket Algorithm

**Concept:** Maintain a "bucket" of tokens that refills over time. Each API call consumes one token.

**Implementation:**
```swift
actor TokenBucket {
    let capacity: Int
    let refillRate: TimeInterval // seconds per token

    private var tokens: Int
    private var lastRefill: Date

    init(capacity: Int, refillRate: TimeInterval) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.tokens = capacity
        self.lastRefill = Date()
    }

    func acquire() async throws {
        await refill()

        guard tokens > 0 else {
            throw APIError.rateLimitExceeded
        }

        tokens -= 1
    }

    private func refill() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefill)
        let newTokens = Int(elapsed / refillRate)

        if newTokens > 0 {
            tokens = min(capacity, tokens + newTokens)
            lastRefill = now
        }
    }
}
```

**Usage:**
```swift
actor TCGPlayerClient {
    private let rateLimiter = TokenBucket(capacity: 100, refillRate: 1.0) // 100 req/min

    func searchCards(query: String) async throws -> [Card] {
        try await rateLimiter.acquire()

        // Proceed with API call
        // ...
    }
}
```

### Request Queuing

**For non-urgent requests (e.g., background price updates):**

```swift
actor RequestQueue {
    private var queue: [() async throws -> Void] = []
    private var isProcessing = false

    func enqueue(_ request: @escaping () async throws -> Void) {
        queue.append(request)
        Task { await processQueue() }
    }

    private func processQueue() async {
        guard !isProcessing, !queue.isEmpty else { return }

        isProcessing = true

        while let request = queue.first {
            do {
                try await request()
                queue.removeFirst()

                // Delay between requests to respect rate limits
                try await Task.sleep(for: .seconds(1))
            } catch {
                print("Request failed: \(error)")
                queue.removeFirst()
            }
        }

        isProcessing = false
    }
}
```

---

## Caching Strategy

### Caching Layers

**1. Memory Cache (Short-Term)**
- Store recent searches in memory
- TTL: 5 minutes
- Use: Instant results for repeated searches

**2. Disk Cache (Medium-Term)**
- Store card data and pricing locally
- TTL: 24 hours for pricing, 7 days for card data
- Use: Offline mode, reduce API calls

**3. User Defaults (Long-Term)**
- Store user preferences (fee settings, custom percentages)
- Persistent across app sessions

### Implementation

**Memory Cache:**
```swift
actor MemoryCache<Key: Hashable, Value> {
    private struct CacheEntry {
        let value: Value
        let expirationDate: Date
    }

    private var cache: [Key: CacheEntry] = [:]
    private let ttl: TimeInterval

    init(ttl: TimeInterval = 300) { // 5 minutes default
        self.ttl = ttl
    }

    func get(_ key: Key) -> Value? {
        guard let entry = cache[key] else { return nil }

        // Check expiration
        guard Date() < entry.expirationDate else {
            cache[key] = nil
            return nil
        }

        return entry.value
    }

    func set(_ key: Key, value: Value) {
        let expirationDate = Date().addingTimeInterval(ttl)
        cache[key] = CacheEntry(value: value, expirationDate: expirationDate)
    }

    func clear() {
        cache.removeAll()
    }
}
```

**Disk Cache (using SwiftData):**
```swift
@Model
final class CachedPrice {
    @Attribute(.unique) var cardId: String
    var marketPrice: Double
    var lowPrice: Double
    var midPrice: Double
    var highPrice: Double
    var timestamp: Date

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 86400 // 24 hours
    }
}
```

**Cache-First Fetching:**
```swift
func getPricing(cardId: String) async throws -> CardPricing {
    // 1. Check memory cache
    if let cached = await memoryCache.get(cardId) {
        return cached
    }

    // 2. Check disk cache
    let diskCached = try await fetchFromDisk(cardId: cardId)
    if let pricing = diskCached, !pricing.isExpired {
        await memoryCache.set(cardId, value: pricing)
        return pricing
    }

    // 3. Fetch from API
    let pricing = try await fetchFromAPI(cardId: cardId)

    // 4. Update caches
    await memoryCache.set(cardId, value: pricing)
    try await saveToDisk(pricing)

    return pricing
}
```

### Cache Invalidation

**Triggers:**
- User manually refreshes pricing
- Cache expiration (TTL exceeded)
- App receives background notification (future: server-side price updates)

**Clearing Strategy:**
```swift
// Clear all caches
func clearAllCaches() async {
    await memoryCache.clear()
    // Delete all CachedPrice records from SwiftData
}

// Clear specific card
func clearCache(for cardId: String) async {
    await memoryCache.set(cardId, value: nil)
    // Delete specific CachedPrice from SwiftData
}
```

---

## Offline Mode & Fallback Behavior

### Feature Availability Matrix

| Feature | Online Required | Offline Behavior |
|---------|----------------|------------------|
| **Price Lookup** | Yes (first time) | Shows cached prices with "Last updated X hours ago" |
| **Inventory Browsing** | No | Full functionality (SwiftData) |
| **Vendor Mode Sales** | No | Records locally, syncs later (future) |
| **Trade Analyzer** | Partial | Works with cached prices |
| **Analytics** | No | Shows cached data |
| **AI Features** | Yes | "Offline - AI unavailable" message |

### Offline Detection

```swift
import Network

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
```

**Usage in Views:**
```swift
struct PriceLookupView: View {
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        VStack {
            if !networkMonitor.isConnected {
                Banner(message: "You're offline. Showing cached prices.", style: .warning)
            }

            // Rest of UI
        }
    }
}
```

### Graceful Degradation

**Example: Price Lookup Offline**
```swift
func lookupPrice(cardName: String) async throws -> CardPricing {
    // Try API call
    if networkMonitor.isConnected {
        do {
            return try await apiClient.getPricing(cardName: cardName)
        } catch APIError.networkUnavailable {
            // Fall through to cache
        }
    }

    // Fallback to cache
    if let cached = try await cacheRepository.getPricing(cardName: cardName) {
        return cached.toPricing() // Include timestamp for "last updated" display
    }

    // No cache available
    throw APIError.networkUnavailable
}
```

**User Messaging:**
```swift
struct PricingResultView: View {
    let pricing: CardPricing
    let isCached: Bool

    var body: some View {
        VStack {
            // Display prices
            PricingCard(pricing: pricing)

            if isCached {
                Text("Last updated \(pricing.timestamp, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

---

## API Key Management & Security

### Security Principles

1. **Never hardcode API keys in source code**
2. **Store keys in Keychain** (encrypted on-device storage)
3. **Use environment variables for development** (not committed to Git)
4. **Rotate keys regularly** (every 90 days)
5. **Monitor for unauthorized usage**

### Keychain Storage

```swift
import Security

final class KeychainManager {
    static let shared = KeychainManager()

    func save(key: String, value: String) throws {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }

    func get(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.unableToRetrieve
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToRetrieve
    case unableToDelete
    case invalidData
}
```

### API Key Setup Flow

**First Launch:**
```swift
struct APISetupView: View {
    @State private var tcgplayerKey = ""
    @State private var ebayKey = ""

    var body: some View {
        Form {
            Section("TCGPlayer API") {
                SecureField("API Key", text: $tcgplayerKey)
                Button("Save") {
                    try? KeychainManager.shared.save(key: "tcgplayer_api_key", value: tcgplayerKey)
                }
            }

            Section("eBay API") {
                SecureField("API Key", text: $ebayKey)
                Button("Save") {
                    try? KeychainManager.shared.save(key: "ebay_api_key", value: ebayKey)
                }
            }
        }
        .navigationTitle("API Setup")
    }
}
```

**Usage in Services:**
```swift
actor TCGPlayerClient {
    private func getAPIKey() throws -> String {
        guard let key = try KeychainManager.shared.get(key: "tcgplayer_api_key") else {
            throw APIError.unauthorized
        }
        return key
    }

    func makeRequest() async throws {
        let apiKey = try getAPIKey()
        // Use apiKey in request headers
    }
}
```

### Development vs. Production Keys

**XCConfig Environment Variables:**
```
// Config/Debug.xcconfig
TCGPLAYER_API_KEY = dev_key_12345

// Config/Release.xcconfig
TCGPLAYER_API_KEY = prod_key_67890
```

**Access in Code:**
```swift
let apiKey = Bundle.main.infoDictionary?["TCGPLAYER_API_KEY"] as? String
```

**Important:** Add `.xcconfig` files to `.gitignore` if they contain real keys.

---

## Testing Strategy

### Unit Tests for API Clients

**Mock API Responses:**
```swift
final class MockCardDataAPI: CardDataAPI {
    var searchCardsResult: Result<[Card], Error> = .success([])

    func searchCards(query: String) async throws -> [Card] {
        try searchCardsResult.get()
    }

    // Other methods...
}
```

**Test Example:**
```swift
import Testing

@Test func pricingServiceFallsBackToPokemonAPI() async throws {
    let mockTCGPlayer = MockCardDataAPI()
    mockTCGPlayer.searchCardsResult = .failure(APIError.serverError)

    let mockPokemon = MockCardDataAPI()
    mockPokemon.searchCardsResult = .success([Card(id: "1", name: "Charizard")])

    let service = PricingService(pokemonAPI: mockPokemon, tcgplayerAPI: mockTCGPlayer)

    let cards = try await service.searchCards(query: "Charizard")

    #expect(cards.count == 1)
    #expect(cards.first?.name == "Charizard")
}
```

### Integration Tests (Real API Calls)

**Test with Rate Limiting:**
```swift
@Test func pokemonAPISearchReturnsResults() async throws {
    let client = PokemonTCGService.shared

    let results = try await client.searchCards(query: "Pikachu")

    #expect(!results.isEmpty)
    #expect(results.first?.name.contains("Pikachu") == true)
}
```

**Note:** Integration tests should run sparingly to avoid hitting rate limits during CI/CD.

### Manual Testing Checklist

- [ ] Search for common card (e.g., "Charizard") - returns results
- [ ] Search for obscure card - handles "no results"
- [ ] Search with poor spelling - API handles gracefully or suggests corrections
- [ ] Fetch pricing for card with multiple variants - all variants returned
- [ ] Trigger rate limit (make 100 requests rapidly) - app handles gracefully
- [ ] Disconnect internet - app shows cached data and offline message
- [ ] Reconnect internet - app resumes API calls
- [ ] Invalid API key (future) - shows authentication error

---

## Monitoring & Analytics

### Metrics to Track

**API Health:**
- Success rate (% of requests that succeed)
- Average response time
- Error rate by type (4xx, 5xx, timeout)
- Rate limit hits

**Business Metrics:**
- Most searched cards (identify popular inventory)
- Average searches per user per session
- Cache hit rate (% of requests served from cache)

### Logging

**Structured Logging:**
```swift
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

struct APILogger {
    static func log(_ message: String, level: LogLevel = .info, file: String = #file, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        print("[\(level.rawValue)] [\(filename):\(line)] \(message)")
    }
}
```

**Usage:**
```swift
func searchCards(query: String) async throws -> [Card] {
    APILogger.log("Searching cards: \(query)", level: .info)

    do {
        let results = try await performSearch(query)
        APILogger.log("Search returned \(results.count) results", level: .info)
        return results
    } catch {
        APILogger.log("Search failed: \(error)", level: .error)
        throw error
    }
}
```

### Future: Server-Side Monitoring

**When CardShow Pro has a backend (V2+):**
- Track API usage per user (identify abuse)
- Aggregate error rates
- Send alerts when API is down
- Dashboard for API health metrics

---

## Summary & Quick Reference

### Current State (V1)

| API | Status | Features |
|-----|--------|----------|
| PokemonTCG.io | ✅ Active | Price lookup, card search |
| TCGPlayer | ❌ Not Started | - |
| eBay | ❌ Not Started | - |
| OpenAI | ❌ Not Started | - |

### Implementation Checklist

**V1 (Current):**
- [x] PokemonTCG.io basic integration
- [x] Card search functionality
- [x] Price lookup with variants
- [ ] Memory caching
- [ ] Disk caching (SwiftData)
- [ ] Offline mode with cached data

**V2 (Q3 2026):**
- [ ] TCGPlayer API integration
- [ ] Multi-game support
- [ ] Rate limiting with token bucket
- [ ] Request queuing for background tasks

**V3 (Q4 2026):**
- [ ] OpenAI API integration
- [ ] Card Analyzer (image analysis)
- [ ] Listing Generator (copywriting)
- [ ] Pro Market Agent (insights)
- [ ] eBay API (sold listings)

### Contact & Resources

**API Partnerships:**
- TCGPlayer Developer: https://developer.tcgplayer.com/
- eBay Developer: https://developer.ebay.com/
- OpenAI Platform: https://platform.openai.com/

**Internal Documentation:**
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [PRD.md](./PRD.md) - Product requirements
- [FEATURES.json](./ai/FEATURES.json) - Feature roadmap

---

*This document is maintained by the Engineering Team. Last reviewed: January 13, 2026.*
