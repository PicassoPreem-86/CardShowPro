# AI Features Implementation Guide
**CardShowPro V3 - Card Analyzer, Listing Generator, Pro Market Agent**

---

## Recommended Launch Stack

### Selected APIs
```swift
// Primary: Google Gemini 2.5 Flash (Free Tier)
// - Card Analyzer (Vision + Analysis)
// - Listing Generator (Text Generation)
// - Market Agent (Trend Analysis)

// Fallback: OpenAI GPT-4o-mini (Paid)
// - Activate if Gemini rate limits hit
// - Higher quality text generation

// Cost: $0-20/month depending on usage
```

---

## Architecture Overview

### Swift Package Structure
```
CardShowProPackage/
├── Sources/
│   └── CardShowProFeature/
│       ├── Services/
│       │   ├── AIService/
│       │   │   ├── AIServiceProtocol.swift
│       │   │   ├── GeminiService.swift
│       │   │   ├── OpenAIService.swift (fallback)
│       │   │   ├── AIServiceFactory.swift
│       │   │   └── Models/
│       │   │       ├── AIRequest.swift
│       │   │       ├── AIResponse.swift
│       │   │       └── AIError.swift
│       │   ├── CardAnalyzerService.swift
│       │   ├── ListingGeneratorService.swift
│       │   └── MarketAgentService.swift
│       ├── Models/
│       │   ├── CardGrade.swift
│       │   ├── CardListing.swift
│       │   ├── MarketInsight.swift
│       │   └── AICache.swift (SwiftData)
│       └── Views/
│           ├── CardAnalyzerView.swift
│           ├── ListingGeneratorView.swift
│           └── MarketAgentView.swift
└── Tests/
    └── CardShowProFeatureTests/
        ├── CardAnalyzerServiceTests.swift
        ├── ListingGeneratorServiceTests.swift
        └── MarketAgentServiceTests.swift
```

---

## Service Layer Design

### 1. AIServiceProtocol (Provider Abstraction)

```swift
import Foundation
import UIKit

/// Protocol for AI service providers (Gemini, OpenAI, etc.)
protocol AIServiceProtocol: Sendable {
    /// Analyze images and return structured response
    func analyzeImages(
        _ images: [UIImage],
        prompt: String
    ) async throws -> AIResponse

    /// Generate text from prompt
    func generateText(
        prompt: String,
        systemPrompt: String?
    ) async throws -> String

    /// Check if service is available (rate limit checks)
    func isAvailable() async -> Bool

    /// Get estimated cost for request
    func estimateCost(inputTokens: Int, outputTokens: Int) -> Decimal
}

/// Standard AI response format
struct AIResponse: Codable, Sendable {
    let content: String
    let tokensUsed: TokenUsage
    let provider: String
    let timestamp: Date
}

struct TokenUsage: Codable, Sendable {
    let input: Int
    let output: Int
    let cached: Int?
}

enum AIError: Error, LocalizedError {
    case rateLimitExceeded
    case invalidAPIKey
    case networkError(Error)
    case parseError
    case providerUnavailable

    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again in a moment."
        case .invalidAPIKey:
            return "Invalid API key. Please check configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parseError:
            return "Failed to parse AI response."
        case .providerUnavailable:
            return "AI service temporarily unavailable."
        }
    }
}
```

---

### 2. GeminiService Implementation

```swift
import Foundation
import UIKit

/// Google Gemini AI service implementation
final class GeminiService: AIServiceProtocol {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let model = "gemini-2.5-flash-latest"

    // Rate limiting (Free tier: 15 RPM)
    private let rateLimiter = RateLimiter(requestsPerMinute: 15)

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func analyzeImages(
        _ images: [UIImage],
        prompt: String
    ) async throws -> AIResponse {
        // Check rate limit
        guard await rateLimiter.canProceed() else {
            throw AIError.rateLimitExceeded
        }

        // Convert images to base64
        let imageParts = try images.map { image in
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                throw AIError.parseError
            }
            return [
                "inlineData": [
                    "mimeType": "image/jpeg",
                    "data": data.base64EncodedString()
                ]
            ]
        }

        // Build request
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": imageParts + [["text": prompt]]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "maxOutputTokens": 1024
            ]
        ]

        let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 429 {
                throw AIError.rateLimitExceeded
            }
            throw AIError.networkError(URLError(.badServerResponse))
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw AIError.parseError
        }

        // Extract token usage
        let usage = json["usageMetadata"] as? [String: Any]
        let inputTokens = usage?["promptTokenCount"] as? Int ?? 0
        let outputTokens = usage?["candidatesTokenCount"] as? Int ?? 0

        return AIResponse(
            content: text,
            tokensUsed: TokenUsage(input: inputTokens, output: outputTokens, cached: nil),
            provider: "gemini",
            timestamp: Date()
        )
    }

    func generateText(
        prompt: String,
        systemPrompt: String? = nil
    ) async throws -> String {
        // Similar to analyzeImages but text-only
        // Implementation details...
        ""
    }

    func isAvailable() async -> Bool {
        await rateLimiter.canProceed()
    }

    func estimateCost(inputTokens: Int, outputTokens: Int) -> Decimal {
        // Free tier
        return 0.00
    }
}

/// Simple rate limiter
actor RateLimiter {
    private var requests: [Date] = []
    private let maxRequests: Int
    private let timeWindow: TimeInterval = 60 // 1 minute

    init(requestsPerMinute: Int) {
        self.maxRequests = requestsPerMinute
    }

    func canProceed() -> Bool {
        let now = Date()
        let windowStart = now.addingTimeInterval(-timeWindow)

        // Remove old requests
        requests.removeAll { $0 < windowStart }

        if requests.count < maxRequests {
            requests.append(now)
            return true
        }

        return false
    }
}
```

---

### 3. CardAnalyzerService (Business Logic)

```swift
import Foundation
import SwiftData
import UIKit

/// Card analysis service with caching
@Observable
final class CardAnalyzerService: Sendable {
    private let aiService: AIServiceProtocol
    private let cacheRepository: CacheRepository

    init(
        aiService: AIServiceProtocol,
        cacheRepository: CacheRepository
    ) {
        self.aiService = aiService
        self.cacheRepository = cacheRepository
    }

    /// Analyze card condition and estimate PSA grade
    func analyzeCard(
        frontImage: UIImage,
        backImage: UIImage
    ) async throws -> CardGrade {
        // Check cache first
        let cacheKey = generateCacheKey(front: frontImage, back: backImage)
        if let cached = try? await cacheRepository.getCachedGrade(key: cacheKey) {
            return cached
        }

        // Build analysis prompt
        let prompt = """
        Analyze this trading card and provide a detailed condition assessment.

        Evaluate the following aspects on a scale of 1-10:
        1. Centering (front and back): Measure border ratios
        2. Corners: Check for wear, fraying, or rounding
        3. Edges: Look for chips, wear, or whitening
        4. Surface: Detect scratches, print lines, or stains

        Return your analysis in JSON format:
        {
            "overall_grade": <number 1-10>,
            "centering": {
                "front": { "left_right": <ratio>, "top_bottom": <ratio>, "score": <1-10> },
                "back": { "left_right": <ratio>, "top_bottom": <ratio>, "score": <1-10> }
            },
            "corners": {
                "score": <1-10>,
                "details": "<description>"
            },
            "edges": {
                "score": <1-10>,
                "details": "<description>"
            },
            "surface": {
                "score": <1-10>,
                "details": "<description>"
            },
            "confidence": <0.0-1.0>,
            "summary": "<brief assessment>"
        }

        Be objective and consistent with PSA grading standards.
        """

        // Call AI service
        let response = try await aiService.analyzeImages(
            [frontImage, backImage],
            prompt: prompt
        )

        // Parse response
        let grade = try parseGradeResponse(response.content)

        // Cache result (7 day TTL)
        try? await cacheRepository.cacheGrade(grade, key: cacheKey)

        return grade
    }

    private func parseGradeResponse(_ json: String) throws -> CardGrade {
        // Remove markdown code blocks if present
        let cleaned = json
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw AIError.parseError
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CardGrade.self, from: data)
    }

    private func generateCacheKey(front: UIImage, back: UIImage) -> String {
        // Simple hash of image data
        let frontData = front.jpegData(compressionQuality: 0.5) ?? Data()
        let backData = back.jpegData(compressionQuality: 0.5) ?? Data()
        let combined = frontData + backData
        return combined.sha256Hash()
    }
}

/// Card grade model
struct CardGrade: Codable, Sendable {
    let overallGrade: Double
    let centering: CenteringAnalysis
    let corners: ComponentAnalysis
    let edges: ComponentAnalysis
    let surface: ComponentAnalysis
    let confidence: Double
    let summary: String
}

struct CenteringAnalysis: Codable, Sendable {
    let front: CenteringMeasurement
    let back: CenteringMeasurement
}

struct CenteringMeasurement: Codable, Sendable {
    let leftRight: String
    let topBottom: String
    let score: Double
}

struct ComponentAnalysis: Codable, Sendable {
    let score: Double
    let details: String
}
```

---

### 4. ListingGeneratorService

```swift
import Foundation

/// Listing generation service
@Observable
final class ListingGeneratorService: Sendable {
    private let aiService: AIServiceProtocol

    enum Platform: String, CaseIterable {
        case ebay = "eBay"
        case tcgPlayer = "TCGPlayer"
        case facebook = "Facebook Marketplace"
        case mercari = "Mercari"
    }

    init(aiService: AIServiceProtocol) {
        self.aiService = aiService
    }

    /// Generate optimized listing for platform
    func generateListing(
        cardName: String,
        set: String,
        year: String?,
        condition: String,
        grade: CardGrade?,
        platform: Platform,
        additionalNotes: String? = nil
    ) async throws -> CardListing {
        let systemPrompt = """
        You are an expert at writing compelling trading card listings for \(platform.rawValue).
        Write SEO-optimized titles and descriptions that convert browsers into buyers.
        Use proper keywords, highlight condition and scarcity, and follow \(platform.rawValue) best practices.
        """

        let prompt = """
        Create a listing for:
        - Card: \(cardName)
        - Set: \(set)
        \(year.map { "- Year: \($0)" } ?? "")
        - Condition: \(condition)
        \(grade.map { "- AI Grade: \($0.overallGrade)/10" } ?? "")
        \(additionalNotes.map { "- Notes: \($0)" } ?? "")

        Platform: \(platform.rawValue)

        Return JSON:
        {
            "title": "<SEO-optimized title, max 80 chars>",
            "description": "<compelling description with keywords>",
            "keywords": ["keyword1", "keyword2", ...],
            "pricing_suggestion": {
                "min": <number>,
                "max": <number>,
                "reasoning": "<why this range>"
            }
        }
        """

        let response = try await aiService.generateText(
            prompt: prompt,
            systemPrompt: systemPrompt
        )

        return try parseListing(response)
    }

    private func parseListing(_ json: String) throws -> CardListing {
        let cleaned = json
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw AIError.parseError
        }

        return try JSONDecoder().decode(CardListing.self, from: data)
    }
}

struct CardListing: Codable, Sendable {
    let title: String
    let description: String
    let keywords: [String]
    let pricingSuggestion: PricingSuggestion
}

struct PricingSuggestion: Codable, Sendable {
    let min: Decimal
    let max: Decimal
    let reasoning: String
}
```

---

### 5. MarketAgentService

```swift
import Foundation

/// Market intelligence service
@Observable
final class MarketAgentService: Sendable {
    private let aiService: AIServiceProtocol

    enum Recommendation: String, Codable {
        case buy = "BUY"
        case sell = "SELL"
        case hold = "HOLD"
    }

    init(aiService: AIServiceProtocol) {
        self.aiService = aiService
    }

    /// Get market insight for card
    func analyzeMarket(
        cardName: String,
        currentPrice: Decimal,
        priceHistory: [PricePoint],
        marketTrends: String? = nil
    ) async throws -> MarketInsight {
        let systemPrompt = """
        You are an expert trading card market analyst.
        Provide actionable investment recommendations based on pricing data and trends.
        Be conservative and data-driven in your analysis.
        """

        // Format price history
        let priceData = priceHistory.map { point in
            "\(point.date.formatted()): $\(point.price)"
        }.joined(separator: "\n")

        let prompt = """
        Analyze the market for: \(cardName)
        Current Price: $\(currentPrice)

        Price History (last 30 days):
        \(priceData)

        \(marketTrends.map { "Market Context:\n\($0)" } ?? "")

        Provide investment recommendation in JSON:
        {
            "recommendation": "BUY|SELL|HOLD",
            "confidence": <0.0-1.0>,
            "reasoning": [
                "<reason 1>",
                "<reason 2>",
                "<reason 3>"
            ],
            "price_target": {
                "timeframe": "<e.g. 30 days, 6 months>",
                "target": <number>,
                "upside_percent": <number>
            },
            "risks": ["<risk 1>", "<risk 2>"]
        }

        Be honest about uncertainty. If data is insufficient, say so.
        """

        let response = try await aiService.generateText(
            prompt: prompt,
            systemPrompt: systemPrompt
        )

        return try parseInsight(response)
    }

    private func parseInsight(_ json: String) throws -> MarketInsight {
        let cleaned = json
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw AIError.parseError
        }

        return try JSONDecoder().decode(MarketInsight.self, from: data)
    }
}

struct MarketInsight: Codable, Sendable {
    let recommendation: MarketAgentService.Recommendation
    let confidence: Double
    let reasoning: [String]
    let priceTarget: PriceTarget
    let risks: [String]
}

struct PriceTarget: Codable, Sendable {
    let timeframe: String
    let target: Decimal
    let upsidePercent: Double
}

struct PricePoint: Codable, Sendable {
    let date: Date
    let price: Decimal
}
```

---

## SwiftData Caching Layer

```swift
import SwiftData
import Foundation

/// Cache model for AI results
@Model
final class AICache {
    @Attribute(.unique) var key: String
    var responseData: Data
    var provider: String
    var createdAt: Date
    var expiresAt: Date

    init(key: String, responseData: Data, provider: String, ttl: TimeInterval = 604800) {
        self.key = key
        self.responseData = responseData
        self.provider = provider
        self.createdAt = Date()
        self.expiresAt = Date().addingTimeInterval(ttl) // 7 days default
    }
}

/// Cache repository
actor CacheRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getCachedGrade(key: String) throws -> CardGrade? {
        let descriptor = FetchDescriptor<AICache>(
            predicate: #Predicate { $0.key == key }
        )

        guard let cache = try modelContext.fetch(descriptor).first else {
            return nil
        }

        // Check expiration
        if cache.expiresAt < Date() {
            modelContext.delete(cache)
            try modelContext.save()
            return nil
        }

        return try JSONDecoder().decode(CardGrade.self, from: cache.responseData)
    }

    func cacheGrade(_ grade: CardGrade, key: String) throws {
        let data = try JSONEncoder().encode(grade)
        let cache = AICache(key: key, responseData: data, provider: "gemini")
        modelContext.insert(cache)
        try modelContext.save()
    }

    func cleanExpiredCache() throws {
        let descriptor = FetchDescriptor<AICache>(
            predicate: #Predicate { $0.expiresAt < Date() }
        )

        let expired = try modelContext.fetch(descriptor)
        for cache in expired {
            modelContext.delete(cache)
        }
        try modelContext.save()
    }
}
```

---

## UI Implementation Examples

### CardAnalyzerView

```swift
import SwiftUI
import PhotosUI

struct CardAnalyzerView: View {
    @State private var frontImage: PhotosPickerItem?
    @State private var backImage: PhotosPickerItem?
    @State private var frontUIImage: UIImage?
    @State private var backUIImage: UIImage?

    @State private var isAnalyzing = false
    @State private var grade: CardGrade?
    @State private var error: String?

    private let service: CardAnalyzerService

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Image pickers
                HStack(spacing: 16) {
                    imagePickerCard(
                        title: "Front",
                        image: frontUIImage,
                        selection: $frontImage
                    )

                    imagePickerCard(
                        title: "Back",
                        image: backUIImage,
                        selection: $backImage
                    )
                }

                // Analyze button
                Button {
                    Task { await analyzeCard() }
                } label: {
                    if isAnalyzing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Analyze Card")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(frontUIImage == nil || backUIImage == nil || isAnalyzing)

                // Results
                if let grade {
                    gradeResultCard(grade)
                }

                // Error
                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .navigationTitle("Card Analyzer")
        .onChange(of: frontImage) { loadImage($0, into: $frontUIImage) }
        .onChange(of: backImage) { loadImage($0, into: $backUIImage) }
    }

    @ViewBuilder
    private func imagePickerCard(
        title: String,
        image: UIImage?,
        selection: Binding<PhotosPickerItem?>
    ) -> some View {
        VStack {
            Text(title)
                .font(.headline)

            PhotosPicker(selection: selection, matching: .images) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func gradeResultCard(_ grade: CardGrade) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overall grade
            HStack {
                Text("Estimated PSA Grade")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f", grade.overallGrade))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(gradeColor(grade.overallGrade))
            }

            // Breakdown
            VStack(alignment: .leading, spacing: 12) {
                componentRow("Centering", score: (grade.centering.front.score + grade.centering.back.score) / 2)
                componentRow("Corners", score: grade.corners.score)
                componentRow("Edges", score: grade.edges.score)
                componentRow("Surface", score: grade.surface.score)
            }

            // Summary
            Text(grade.summary)
                .font(.body)
                .foregroundStyle(.secondary)

            // Confidence
            HStack {
                Text("Confidence:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(Int(grade.confidence * 100))%")
                    .font(.caption.weight(.semibold))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func componentRow(_ title: String, score: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(String(format: "%.1f", score))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(gradeColor(score))
        }
    }

    private func gradeColor(_ score: Double) -> Color {
        switch score {
        case 9...10: return .green
        case 7..<9: return .blue
        case 5..<7: return .orange
        default: return .red
        }
    }

    private func loadImage(_ item: PhotosPickerItem?, into binding: Binding<UIImage?>) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    binding.wrappedValue = image
                }
            }
        }
    }

    private func analyzeCard() async {
        guard let front = frontUIImage, let back = backUIImage else { return }

        isAnalyzing = true
        error = nil

        do {
            let result = try await service.analyzeCard(
                frontImage: front,
                backImage: back
            )
            grade = result
        } catch {
            self.error = error.localizedDescription
        }

        isAnalyzing = false
    }
}
```

---

## Configuration & Secrets Management

### 1. Store API Keys Securely

```swift
import Foundation

/// Secure storage for API keys
enum SecureStorage {
    private static let keychain = KeychainWrapper.standard

    enum Key: String {
        case geminiAPIKey = "com.cardshowpro.gemini.apikey"
        case openAIAPIKey = "com.cardshowpro.openai.apikey"
    }

    static func store(_ value: String, for key: Key) {
        keychain.set(value, forKey: key.rawValue)
    }

    static func retrieve(_ key: Key) -> String? {
        keychain.string(forKey: key.rawValue)
    }

    static func delete(_ key: Key) {
        keychain.removeObject(forKey: key.rawValue)
    }
}

// Usage in settings:
// SecureStorage.store("AIzaSy...", for: .geminiAPIKey)
```

### 2. Configuration File (Gitignored)

```swift
// Config/AIConfig.swift
import Foundation

struct AIConfig {
    static let geminiAPIKey: String = {
        // Priority: Keychain > Environment Variable > Empty
        if let stored = SecureStorage.retrieve(.geminiAPIKey) {
            return stored
        }
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            return envKey
        }
        return ""
    }()

    static let openAIAPIKey: String = {
        if let stored = SecureStorage.retrieve(.openAIAPIKey) {
            return stored
        }
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }
        return ""
    }()

    static let useFallback = true
    static let cacheEnabled = true
    static let cacheTTL: TimeInterval = 604800 // 7 days
}
```

---

## Testing Strategy

### 1. Unit Tests

```swift
import Testing
@testable import CardShowProFeature

@Test func cardAnalyzerParsesValidResponse() async throws {
    let mockJSON = """
    {
        "overall_grade": 8.5,
        "centering": {
            "front": { "left_right": "55/45", "top_bottom": "50/50", "score": 9.0 },
            "back": { "left_right": "52/48", "top_bottom": "51/49", "score": 9.5 }
        },
        "corners": { "score": 8.0, "details": "Slight wear on top right" },
        "edges": { "score": 8.5, "details": "Clean edges, minor whitening" },
        "surface": { "score": 9.0, "details": "Excellent surface quality" },
        "confidence": 0.85,
        "summary": "Near mint condition card"
    }
    """

    let service = CardAnalyzerService(
        aiService: MockAIService(response: mockJSON),
        cacheRepository: MockCacheRepository()
    )

    let grade = try await service.analyzeCard(
        frontImage: UIImage(),
        backImage: UIImage()
    )

    #expect(grade.overallGrade == 8.5)
    #expect(grade.confidence == 0.85)
    #expect(grade.corners.score == 8.0)
}

@Test func rateLimiterEnforcesLimits() async {
    let limiter = RateLimiter(requestsPerMinute: 2)

    #expect(await limiter.canProceed()) // Request 1
    #expect(await limiter.canProceed()) // Request 2
    #expect(await limiter.canProceed() == false) // Should fail
}
```

### 2. Integration Tests

```swift
@Test func geminiServiceAnalyzesImages() async throws {
    // Requires valid API key in environment
    guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] else {
        return // Skip if no API key
    }

    let service = GeminiService(apiKey: apiKey)
    let testImage = UIImage(systemName: "photo")!

    let response = try await service.analyzeImages(
        [testImage],
        prompt: "Describe this image"
    )

    #expect(response.content.isEmpty == false)
    #expect(response.provider == "gemini")
}
```

---

## Deployment Checklist

### Pre-Launch
- [ ] Create Google AI Studio account
- [ ] Get Gemini API key
- [ ] Store API key in Keychain (not hardcoded!)
- [ ] Implement rate limiting (15 RPM for free tier)
- [ ] Add caching layer with SwiftData
- [ ] Test with 50+ sample cards
- [ ] Verify token usage estimates
- [ ] Set up error logging (CloudKit or analytics)

### Launch
- [ ] Deploy with free tier initially
- [ ] Monitor usage in Google AI Studio dashboard
- [ ] Track user feedback on accuracy
- [ ] Measure average tokens per request
- [ ] Set up billing alerts ($50, $100 thresholds)

### Post-Launch (30 days)
- [ ] Analyze cost vs. usage
- [ ] Evaluate accuracy from user feedback
- [ ] Decide on premium upgrades (Ximilar, OpenAI)
- [ ] Optimize prompts to reduce token usage
- [ ] Consider paid tier if rate limits hit

---

## Cost Monitoring Dashboard (Future)

```swift
/// Track AI usage and costs
@Model
final class AIUsageLog {
    var timestamp: Date
    var provider: String
    var feature: String // "analyzer", "listing", "market"
    var tokensInput: Int
    var tokensOutput: Int
    var cost: Decimal
    var cacheHit: Bool

    init(provider: String, feature: String, tokensInput: Int, tokensOutput: Int, cost: Decimal, cacheHit: Bool) {
        self.timestamp = Date()
        self.provider = provider
        self.feature = feature
        self.tokensInput = tokensInput
        self.tokensOutput = tokensOutput
        self.cost = cost
        self.cacheHit = cacheHit
    }
}

// Admin view to monitor costs
struct AIUsageStatsView: View {
    @Query private var logs: [AIUsageLog]

    var totalCost: Decimal {
        logs.reduce(0) { $0 + $1.cost }
    }

    var cacheHitRate: Double {
        let hits = logs.filter(\.cacheHit).count
        return Double(hits) / Double(logs.count)
    }

    var body: some View {
        List {
            Section("This Month") {
                LabeledContent("Total Cost", value: "$\(totalCost)")
                LabeledContent("Requests", value: "\(logs.count)")
                LabeledContent("Cache Hit Rate", value: "\(Int(cacheHitRate * 100))%")
            }

            Section("By Feature") {
                ForEach(["analyzer", "listing", "market"], id: \.self) { feature in
                    let featureLogs = logs.filter { $0.feature == feature }
                    let featureCost = featureLogs.reduce(Decimal(0)) { $0 + $1.cost }
                    LabeledContent(feature.capitalized, value: "$\(featureCost)")
                }
            }
        }
        .navigationTitle("AI Usage Stats")
    }
}
```

---

## Next Steps

1. **Week 1:** Implement GeminiService and basic AIServiceProtocol
2. **Week 2:** Build CardAnalyzerService with caching
3. **Week 3:** Add ListingGeneratorService and MarketAgentService
4. **Week 4:** Polish UI and test with real cards
5. **Week 5:** Beta test with 10-20 users
6. **Week 6:** Launch V3 AI features

---

## Questions?

- Prompt engineering help: See [Gemini Docs](https://ai.google.dev/gemini-api/docs/prompting)
- Rate limiting: See [Gemini Rate Limits](https://ai.google.dev/gemini-api/docs/rate-limits)
- Swift best practices: See project CLAUDE.md

**Ready to build AI-powered CardShowPro V3!**
