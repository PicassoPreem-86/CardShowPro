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

    struct OCRResult: Sendable {
        var cardName: String?
        var cardNumber: String?
        var setName: String?
        var allText: [String]
        var confidence: Double

        var hasValidData: Bool {
            cardName != nil || cardNumber != nil
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
        logger.info("Starting OCR recognition...")

        guard let cgImage = image.cgImage else {
            logger.error("Failed to get CGImage from UIImage")
            throw OCRError.invalidImage
        }

        let textBlocks = try await performTextRecognition(on: cgImage)

        logger.info("Found \(textBlocks.count) text blocks")

        // Analyze text blocks to extract card info
        let result = analyzeTextBlocks(textBlocks)

        logger.info("OCR Result - Name: \(result.cardName ?? "nil"), Number: \(result.cardNumber ?? "nil"), Confidence: \(result.confidence)")

        return result
    }

    // MARK: - Vision Framework Integration

    private func performTextRecognition(on image: CGImage) async throws -> [TextBlock] {
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
            request.recognitionLanguages = ["en-US"]

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
        var totalConfidence: Float = 0
        var confidenceCount = 0

        // Extract all text for debugging/display
        let allText = blocks.map { $0.text }

        // Look for card name in top 40% of image (large text, centered)
        let topBlocks = sortedBlocks.filter { $0.boundingBox.midY > 0.6 }
        for block in topBlocks {
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip very short text (likely noise) or very long text (likely flavor text)
            guard text.count >= 3 && text.count <= 30 else { continue }

            // Skip if it looks like a number or contains mostly numbers
            let letterCount = text.filter { $0.isLetter }.count
            guard letterCount > text.count / 2 else { continue }

            // Check if it looks like a Pokemon name (starts with capital, mostly letters)
            if text.first?.isUppercase == true && isPokemonNameCandidate(text) {
                cardName = cleanCardName(text)
                totalConfidence += block.confidence
                confidenceCount += 1
                break
            }
        }

        // Look for card number in bottom 30% of image
        let bottomBlocks = sortedBlocks.filter { $0.boundingBox.midY < 0.3 }
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
            allText: allText,
            confidence: avgConfidence
        )
    }

    // MARK: - Helper Methods

    private func isPokemonNameCandidate(_ text: String) -> Bool {
        // Pokemon names are typically:
        // - 1-2 words
        // - Start with capital letter
        // - Don't contain numbers (except for some forms like "Porygon2")
        // - Don't contain special characters except hyphen and apostrophe

        let words = text.split(separator: " ")
        guard words.count <= 3 else { return false }

        // Check for common non-name patterns
        let lowercased = text.lowercased()
        let skipPatterns = ["hp", "weakness", "resistance", "retreat", "basic", "stage", "illustrator", "pokemon"]
        for pattern in skipPatterns {
            if lowercased.contains(pattern) { return false }
        }

        return true
    }

    private func cleanCardName(_ text: String) -> String {
        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common suffixes that might be captured
        let suffixesToRemove = [" HP", " hp", " Hp", " GX", " gx", " EX", " ex", " V", " VMAX", " VSTAR"]
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
