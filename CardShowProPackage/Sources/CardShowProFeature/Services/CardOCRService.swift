import Vision
import UIKit
import OSLog

/// Service for recognizing card text using Apple Vision framework
/// Extracts card name and number from Pokemon card images
@MainActor
@Observable
final class CardOCRService {
    static let shared = CardOCRService()

    private let logger = Logger(subsystem: "com.cardshowpro", category: "CardOCRService")

    // MARK: - OCR Result

    /// Detected language of the card
    enum DetectedLanguage: String, Sendable {
        case english = "en"
        case japanese = "ja"
        case chineseTraditional = "zh-tw"
    }

    struct OCRResult: Sendable {
        var cardName: String?
        var cardNumber: String?
        var setName: String?
        var setCode: String?          // NEW: Set code extracted from bottom region (e.g., "SV9", "base1")
        var allText: [String]
        var confidence: Double
        var detectedLanguage: DetectedLanguage

        // Diagnostics for failed OCR
        var rejectedCandidates: [(text: String, reason: String)]

        var hasValidData: Bool {
            cardName != nil || cardNumber != nil
        }

        /// Human-readable message explaining why OCR might have failed
        var diagnosticMessage: String? {
            guard cardName == nil else { return nil }
            if allText.isEmpty { return "No text detected in image" }
            if rejectedCandidates.isEmpty { return "No text found in card name region (top 40%)" }
            return "Found \(rejectedCandidates.count) candidates, all rejected"
        }

        /// Summary of rejected candidates for debugging
        var diagnosticDetails: String {
            guard !rejectedCandidates.isEmpty else { return "No candidates" }
            return rejectedCandidates
                .prefix(5)
                .map { "\"\($0.text)\" - \($0.reason)" }
                .joined(separator: "\n")
        }

        init(cardName: String? = nil, cardNumber: String? = nil, setName: String? = nil, setCode: String? = nil,
             allText: [String] = [], confidence: Double = 0, detectedLanguage: DetectedLanguage = .english,
             rejectedCandidates: [(text: String, reason: String)] = []) {
            self.cardName = cardName
            self.cardNumber = cardNumber
            self.setName = setName
            self.setCode = setCode
            self.allText = allText
            self.confidence = confidence
            self.detectedLanguage = detectedLanguage
            self.rejectedCandidates = rejectedCandidates
        }
    }

    // MARK: - Text Block for analysis

    private struct TextBlock {
        let text: String
        let boundingBox: CGRect  // Normalized coordinates (0-1)
        let confidence: Float
    }

    // MARK: - Public API

    /// Recognize text from a card image
    /// - Parameter image: The captured card image
    /// - Returns: OCR result containing card name, number, and confidence
    func recognizeText(from image: UIImage) async throws -> OCRResult {
        print("🔤 DEBUG [OCR]: Starting recognizeText, image size: \(image.size)")
        logger.info("Starting OCR recognition...")

        guard let cgImage = image.cgImage else {
            print("🔤 DEBUG [OCR]: Failed to get CGImage from UIImage!")
            logger.error("Failed to get CGImage from UIImage")
            throw OCRError.invalidImage
        }
        print("🔤 DEBUG [OCR]: CGImage obtained, dimensions: \(cgImage.width)x\(cgImage.height)")

        let textBlocks = try await performTextRecognition(on: cgImage)

        print("🔤 DEBUG [OCR]: Vision returned \(textBlocks.count) text blocks")
        logger.info("Found \(textBlocks.count) text blocks")

        // Analyze text blocks to extract card info
        let result = analyzeTextBlocks(textBlocks)

        print("🔤 DEBUG [OCR]: Analysis complete - Name: '\(result.cardName ?? "nil")', Number: '\(result.cardNumber ?? "nil")', SetCode: '\(result.setCode ?? "nil")'")
        if result.cardName == nil {
            print("🔤 DEBUG [OCR]: Diagnostic: \(result.diagnosticMessage ?? "No diagnostic")")
            print("🔤 DEBUG [OCR]: All text found: \(result.allText)")
            print("🔤 DEBUG [OCR]: Rejected candidates:\n\(result.diagnosticDetails)")
        }
        logger.info("OCR Result - Name: \(result.cardName ?? "nil"), Number: \(result.cardNumber ?? "nil"), SetCode: \(result.setCode ?? "nil"), Confidence: \(result.confidence)")

        return result
    }

    /// Detect set code from bottom region of card image
    /// Set codes appear in the bottom-left region (e.g., "SV9", "SM11b", "base1")
    func detectSetCode(from image: CGImage) async throws -> (setCode: String?, confidence: Float) {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"] // Set codes are alphanumeric
        request.usesLanguageCorrection = false

        // Bottom-left region where set codes appear (Y: 0.0-0.15, X: 0.0-0.3)
        request.regionOfInterest = CGRect(x: 0.0, y: 0.0, width: 0.3, height: 0.15)

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return (nil, 0.0)
        }

        // Look for set code patterns: SV9, SM11b, base1, etc.
        let setCodePattern = try NSRegularExpression(pattern: "^([A-Z]{1,4}\\d{1,3}[a-z]?)$")

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string.trimmingCharacters(in: .whitespaces)
            let range = NSRange(text.startIndex..., in: text)

            if setCodePattern.firstMatch(in: text, range: range) != nil {
                print("🔤 DEBUG [OCR]: Found set code '\(text)' with confidence \(candidate.confidence)")
                return (text, candidate.confidence)
            }
        }

        return (nil, 0.0)
    }

    // MARK: - Vision Framework Integration

    /// Two-phase OCR: Fast English first, multilingual only if CJK detected or suspected
    private func performTextRecognition(on image: CGImage) async throws -> [TextBlock] {
        // Phase 1: Fast English-only OCR (keeps English cards fast)
        let englishBlocks = try await performOCR(on: image, languages: ["en-US"])

        // Check if any text contains CJK characters
        let hasCJK = englishBlocks.contains { containsCJK($0.text) }

        // Check specifically if top 40% blocks (card name region) have ANY suspicious characters
        // This is more targeted than checking all text, and catches misrecognized CJK card names
        let topBlocks = englishBlocks.filter { $0.boundingBox.midY > 0.6 }
        let hasSuspiciousInTop = topBlocks.contains { block in
            containsAnySuspiciousCharacters(block.text)
        }

        if hasCJK || hasSuspiciousInTop {
            // Phase 2: Re-run with Japanese/Chinese for better accuracy
            let reason = hasCJK ? "CJK detected" : "suspicious non-Latin in name region"
            print("🔤 DEBUG [OCR]: \(reason), re-running with multilingual support")
            // Include both Traditional (zh-Hant) and Simplified (zh-Hans) Chinese
            // Pokemon cards are printed in both variants depending on region
            return try await performOCR(on: image, languages: ["ja-JP", "zh-Hant", "zh-Hans", "en-US"])
        }

        return englishBlocks
    }

    /// Perform OCR with specified languages
    private func performOCR(on image: CGImage, languages: [String]) async throws -> [TextBlock] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let blocks = observations.compactMap { observation -> TextBlock? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return TextBlock(
                        text: candidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: candidate.confidence
                    )
                }

                continuation.resume(returning: blocks)
            }

            // Configure for accurate recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = languages

            let handler = VNImageRequestHandler(cgImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Text Analysis

    private func analyzeTextBlocks(_ blocks: [TextBlock]) -> OCRResult {
        // Sort blocks by vertical position (top to bottom in image coordinates)
        // Note: Vision uses bottom-left origin, so higher Y = higher on screen
        let sortedBlocks = blocks.sorted { $0.boundingBox.midY > $1.boundingBox.midY }

        var cardName: String?
        var cardNumber: String?
        var setName: String?
        var setCode: String?
        var totalConfidence: Float = 0
        var confidenceCount = 0
        var rejectedCandidates: [(text: String, reason: String)] = []
        var detectedLanguage: DetectedLanguage = .english

        // Extract all text for debugging/display
        let allText = blocks.map { $0.text }

        // Detect language from all text blocks
        let combinedText = allText.joined(separator: " ")
        if containsCJK(combinedText) {
            // Check if Japanese (has kana) or Chinese (only CJK ideographs)
            var hasKana = false
            for scalar in combinedText.unicodeScalars {
                // Hiragana or Katakana = definitely Japanese
                if (scalar.value >= 0x3040 && scalar.value <= 0x309F) ||
                   (scalar.value >= 0x30A0 && scalar.value <= 0x30FF) {
                    hasKana = true
                    break
                }
            }
            detectedLanguage = hasKana ? .japanese : .chineseTraditional
        }

        // Look for card name in top 40% of image (large text, centered)
        // Prioritize very top region (Y > 0.75) for card name, but fall back to Y > 0.6 if nothing found
        let veryTopBlocks = sortedBlocks.filter { $0.boundingBox.midY > 0.75 }
        var topBlocks = veryTopBlocks.isEmpty ? sortedBlocks.filter { $0.boundingBox.midY > 0.6 } : veryTopBlocks

        // Sort by bounding box height (larger text first) - card names are typically larger than attack names
        topBlocks = topBlocks.sorted { $0.boundingBox.height > $1.boundingBox.height }

        print("🔤 DEBUG [OCR]: Found \(topBlocks.count) blocks in top region (prioritized Y>0.75, sorted by size):")
        for (index, block) in topBlocks.enumerated() {
            print("🔤 DEBUG [OCR]:   Block \(index + 1): '\(block.text)' (Y: \(String(format: "%.2f", block.boundingBox.midY)), height: \(String(format: "%.3f", block.boundingBox.height)), confidence: \(String(format: "%.2f", block.confidence)))")
        }
        for block in topBlocks {
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let isCJK = containsCJK(text)

            // Skip very short text (likely noise) or very long text (likely flavor text)
            // Japanese/Chinese names are typically shorter (1-10 chars)
            let minLength = isCJK ? 1 : 3
            let maxLength = isCJK ? 15 : 30

            if text.count < minLength {
                rejectedCandidates.append((text: text, reason: "Too short (<\(minLength) chars)"))
                continue
            }
            if text.count > maxLength {
                rejectedCandidates.append((text: text, reason: "Too long (>\(maxLength) chars)"))
                continue
            }

            // Skip if it looks like a number or contains too many digits
            let digitCount = text.filter { $0.isNumber }.count

            // Reject if >40% digits (allows "Porygon2", rejects "25/102")
            if digitCount >= text.count * 4 / 10 {
                rejectedCandidates.append((text: text, reason: "Too many digits (\(digitCount)/\(text.count))"))
                continue
            }

            if isCJK {
                // For CJK text, count CJK characters as valid
                var cjkCount = 0
                for scalar in text.unicodeScalars {
                    // Hiragana, Katakana, CJK Ideographs
                    if (scalar.value >= 0x3040 && scalar.value <= 0x309F) ||
                       (scalar.value >= 0x30A0 && scalar.value <= 0x30FF) ||
                       (scalar.value >= 0x4E00 && scalar.value <= 0x9FFF) {
                        cjkCount += 1
                    }
                }
                print("🔤 DEBUG [OCR]: CJK candidate '\(text)': \(cjkCount) CJK chars out of \(text.count) total (\(String(format: "%.0f%%", Double(cjkCount) / Double(text.count) * 100)))")

                // Reject if <30% CJK characters (relaxed from 50% to handle misrecognized text)
                // Vision often adds garbage Latin characters to CJK text
                if cjkCount < max(1, text.count * 3 / 10) {
                    rejectedCandidates.append((text: text, reason: "Not enough CJK chars (\(cjkCount)/\(text.count))"))
                    continue
                }

                // CJK-specific skip patterns (Japanese card labels)
                let japaneseSkipPatterns = ["たね", "1進化", "2進化", "ポケモン", "トレーナーズ", "エネルギー",
                                            "弱点", "抵抗力", "にげる", "ワザ"]
                // Chinese skip patterns
                let chineseSkipPatterns = ["基礎", "一階進化", "二階進化", "寶可夢", "訓練家", "能量",
                                          "弱點", "抵抗力", "撤退"]
                let skipPatterns = japaneseSkipPatterns + chineseSkipPatterns

                var shouldSkip = false
                for pattern in skipPatterns {
                    if text.contains(pattern) {
                        rejectedCandidates.append((text: text, reason: "Matches CJK skip pattern (\(pattern))"))
                        shouldSkip = true
                        break
                    }
                }
                if shouldSkip { continue }
            } else {
                // For Latin text, count valid name characters (letters + allowed punctuation)
                let validNameChars = CharacterSet.letters.union(CharacterSet(charactersIn: "'-.:"))
                let validCount = text.unicodeScalars.filter { validNameChars.contains($0) }.count

                // Reject if <50% valid name characters
                if validCount <= text.count / 2 {
                    rejectedCandidates.append((text: text, reason: "Not enough letters (\(validCount)/\(text.count))"))
                    continue
                }

                // Check if it looks like a Pokemon name (starts with capital, mostly letters)
                if text.first?.isUppercase != true {
                    rejectedCandidates.append((text: text, reason: "Doesn't start with capital"))
                    continue
                }

                if !isPokemonNameCandidate(text) {
                    rejectedCandidates.append((text: text, reason: "Matches skip pattern (HP/weakness/etc)"))
                    continue
                }
            }

            // Found a valid card name!
            cardName = cleanCardName(text)
            totalConfidence += block.confidence
            confidenceCount += 1
            break
        }

        // Look for card number and set code in bottom 30% of image
        let bottomBlocks = sortedBlocks.filter { $0.boundingBox.midY < 0.3 }

        // Extract card number
        for block in bottomBlocks {
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Try to extract card number (formats: "25/102", "025", "25")
            if let extractedNumber = extractCardNumber(from: text) {
                cardNumber = extractedNumber
                totalConfidence += block.confidence
                confidenceCount += 1
                break
            }
        }

        // Extract set code (e.g., "SV9", "SM11b", "base1")
        // Set codes are typically in the bottom-left region
        let bottomLeftBlocks = bottomBlocks.filter { $0.boundingBox.midX < 0.4 }
        for block in bottomLeftBlocks {
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Set code pattern: 1-4 uppercase letters followed by 1-3 digits, optionally followed by lowercase letter
            // Examples: SV9, SM11b, S8, base1
            let setCodePattern = try? NSRegularExpression(pattern: "^([A-Z]{1,4}\\d{1,3}[a-z]?)$")
            if let regex = setCodePattern,
               regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                setCode = text
                print("🔤 DEBUG [OCR]: Found set code '\(text)' in bottom-left region")
                break
            }
        }

        // Look for set name near the card number area
        for block in bottomBlocks {
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Set names are typically 2-4 words
            let words = text.split(separator: " ")
            if words.count >= 2 && words.count <= 5 && !text.contains("/") {
                // Check if it looks like a set name
                if isSetNameCandidate(text) {
                    setName = text
                    break
                }
            }
        }

        let avgConfidence = confidenceCount > 0 ? Double(totalConfidence / Float(confidenceCount)) : 0.0

        return OCRResult(
            cardName: cardName,
            cardNumber: cardNumber,
            setName: setName,
            setCode: setCode,
            allText: allText,
            confidence: avgConfidence,
            detectedLanguage: detectedLanguage,
            rejectedCandidates: rejectedCandidates
        )
    }

    // MARK: - Helper Methods

    /// Check if text contains CJK characters (Japanese or Chinese)
    private func containsCJK(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // Hiragana: U+3040-U+309F
            if scalar.value >= 0x3040 && scalar.value <= 0x309F { return true }
            // Katakana: U+30A0-U+30FF
            if scalar.value >= 0x30A0 && scalar.value <= 0x30FF { return true }
            // CJK Unified Ideographs: U+4E00-U+9FFF
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF { return true }
        }
        return false
    }

    /// Detect suspicious non-Latin characters that might indicate misrecognized CJK
    /// English OCR often misreads Chinese/Japanese as Cyrillic, Arabic, or other scripts
    private func containsSuspiciousNonLatin(_ text: String) -> Bool {
        var cyrillic = 0
        var arabic = 0
        var otherNonLatin = 0
        var total = 0

        for scalar in text.unicodeScalars {
            total += 1

            // Cyrillic: U+0400-U+04FF (Н, Р, С, etc.)
            if (0x0400...0x04FF).contains(scalar.value) {
                cyrillic += 1
            }
            // Arabic: U+0600-U+06FF
            else if (0x0600...0x06FF).contains(scalar.value) {
                arabic += 1
            }
            // Other suspicious ranges that shouldn't appear on Pokemon cards
            // Thai: U+0E00-U+0E7F
            // Hebrew: U+0590-U+05FF
            else if (0x0E00...0x0E7F).contains(scalar.value) ||
                    (0x0590...0x05FF).contains(scalar.value) {
                otherNonLatin += 1
            }
        }

        // If >5% of characters are Cyrillic/Arabic/etc., probably misrecognized CJK
        let suspiciousRatio = Double(cyrillic + arabic + otherNonLatin) / Double(max(total, 1))
        if suspiciousRatio > 0.05 {
            print("🔤 DEBUG [OCR]: Found \(cyrillic) Cyrillic, \(arabic) Arabic, \(otherNonLatin) other non-Latin chars (\(String(format: "%.1f%%", suspiciousRatio * 100)))")
            return true
        }

        return false
    }

    /// Check if text contains ANY Cyrillic or Arabic characters (aggressive check for card name region)
    /// Used to detect misrecognized CJK text in the top region where card names appear
    /// Returns true immediately on finding ANY suspicious character (no threshold)
    private func containsAnySuspiciousCharacters(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // Cyrillic: U+0400-U+04FF (Н, Р, С, etc.)
            // English OCR often misreads Chinese as Cyrillic
            if (0x0400...0x04FF).contains(scalar.value) {
                print("🔤 DEBUG [OCR]: Found Cyrillic character in top region: '\(Character(scalar))' - triggering multilingual OCR")
                return true
            }
            // Arabic: U+0600-U+06FF
            // Sometimes used for certain special characters in misrecognition
            if (0x0600...0x06FF).contains(scalar.value) {
                print("🔤 DEBUG [OCR]: Found Arabic character in top region: '\(Character(scalar))' - triggering multilingual OCR")
                return true
            }
            // Thai: U+0E00-U+0E7F
            // Hebrew: U+0590-U+05FF
            // These shouldn't appear on Pokemon cards
            if (0x0E00...0x0E7F).contains(scalar.value) || (0x0590...0x05FF).contains(scalar.value) {
                print("🔤 DEBUG [OCR]: Found other suspicious character in top region - triggering multilingual OCR")
                return true
            }
        }
        return false
    }

    private func isPokemonNameCandidate(_ text: String) -> Bool {
        // Pokemon names are typically:
        // - 1-3 words
        // - Start with capital letter
        // - Don't contain numbers (except for some forms like "Porygon2")
        // - Don't contain special characters except hyphen, apostrophe, period, colon

        let words = text.split(separator: " ")
        guard words.count <= 3 else { return false }

        let lowercased = text.lowercased()

        // Strip common punctuation for matching
        let stripped = lowercased.filter { $0.isLetter || $0.isNumber || $0 == " " }

        // Exact match patterns (complete phrases to skip)
        let exactSkipPatterns = [
            // Card type labels (often misread by OCR - "BASIC" → "BASIG", "BASIS", etc.)
            "basic", "basis", "basig", "basie", "basio", "basi", "basc",
            "stage", "stage1", "stage2", "stage 1", "stage 2",
            // Card categories
            "pokémon", "pokemon", "trainer", "energy", "item", "supporter",
            // Other non-name text
            "weakness", "resistance", "illustrator", "retreat cost", "retreat",
            // Evolution labels
            "evolves", "evolves from", "put", "put onto",
            // Common OCR misreads
            "pokemon v", "pokémon v", "pokemon ex", "pokémon ex"
        ]
        for pattern in exactSkipPatterns {
            if lowercased == pattern || stripped == pattern { return false }
        }

        // Prefix patterns (text that starts with these - skip card type labels)
        // IMPORTANT: "stage" prefix catches ALL stage variations (Stage 1, Stage V, etc.)
        // "basi" prefix catches "BASIC" and common OCR misreads like "BASIG", "BASIS"
        let prefixSkipPatterns = [
            "basic", "basi", "basig", "basis",  // "BASIC" and all its OCR misreads
            "stage ", "stage1", "stage2",
            "hp ", "hp:", "evolves from", "put onto"
        ]
        for pattern in prefixSkipPatterns {
            if lowercased.hasPrefix(pattern) || stripped.hasPrefix(pattern) { return false }
        }

        // Also reject if text is ONLY "stage" with anything after it
        if stripped.hasPrefix("stage") {
            return false
        }

        // Contains patterns (these are definitely not card names)
        let containsSkipPatterns = ["weakness:", "resistance:", "retreat:", "illustrator:"]
        for pattern in containsSkipPatterns {
            if lowercased.contains(pattern) { return false }
        }

        // Skip if it's JUST "hp" followed by a number (like "HP 120")
        if lowercased.hasPrefix("hp ") || lowercased.hasPrefix("hp") && lowercased.count <= 6 {
            return false
        }

        return true
    }

    private func cleanCardName(_ text: String) -> String {
        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove "Pokemon " prefix (common in modern ex cards like "Pokemon Charizard ex")
        if cleaned.lowercased().hasPrefix("pokemon ") {
            cleaned = String(cleaned.dropFirst(8))
        }

        // Remove common suffixes that might be captured
        let suffixesToRemove = [
            // HP markers
            " HP", " hp", " Hp",
            // Modern (Scarlet/Violet, Sword/Shield)
            " ex", " EX", " V", " VMAX", " VSTAR", " VUNION", " GX", " gx", " Tera",
            // Classic (Diamond/Pearl, HeartGold/SoulSilver)
            " LV.X", " Lv.X", " PRIME", " Prime", " LEGEND", " Legend",
            // Special formats
            " Star", " STAR", " delta", " SP", " FB", " GL", " C", " G"
        ]
        for suffix in suffixesToRemove {
            if cleaned.hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count))
            }
        }

        return cleaned
    }

    private func extractCardNumber(from text: String) -> String? {
        // Pattern 1: "25/102" format
        let slashPattern = #"(\d{1,3})/(\d{1,3})"#
        if let regex = try? NSRegularExpression(pattern: slashPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let numberRange = Range(match.range(at: 1), in: text) {
            return String(text[numberRange])
        }

        // Pattern 2: Standalone number (1-3 digits, possibly with leading zeros)
        let standalonePattern = #"^0*(\d{1,3})$"#
        if let regex = try? NSRegularExpression(pattern: standalonePattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let _ = Range(match.range, in: text) {
            // Return without leading zeros for normalization
            let number = text.trimmingCharacters(in: CharacterSet(charactersIn: "0").union(.whitespaces))
            return number.isEmpty ? "0" : number
        }

        return nil
    }

    private func isSetNameCandidate(_ text: String) -> Bool {
        // Set names typically:
        // - Are 2-4 words
        // - Don't contain numbers (except years like "2023")
        // - Start with capital letters

        let words = text.split(separator: " ")
        guard words.count >= 1 && words.count <= 5 else { return false }

        // Check that most words start with capitals
        let capitalWords = words.filter { $0.first?.isUppercase == true }
        return capitalWords.count >= words.count / 2
    }

    // MARK: - Errors

    enum OCRError: LocalizedError {
        case invalidImage
        case recognitionFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not process the image"
            case .recognitionFailed(let reason):
                return "Text recognition failed: \(reason)"
            }
        }
    }
}
