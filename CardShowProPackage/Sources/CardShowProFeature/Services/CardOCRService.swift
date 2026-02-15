import Foundation
import UIKit
import Vision

/// Service for OCR text recognition on card images
@MainActor
@Observable
final class CardOCRService {
    static let shared = CardOCRService()

    private init() {}

    /// Detected language from OCR
    enum DetectedLanguage: String, Sendable {
        case english
        case japanese
        case chineseTraditional
    }

    /// Rejected candidate with reason
    struct RejectedCandidate: Sendable {
        let text: String
        let reason: String
    }

    /// OCR scan result
    struct OCRResult: Sendable {
        let cardName: String?
        let cardNumber: String?
        let setCode: String?
        let confidence: Double
        let allText: [String]
        let detectedLanguage: DetectedLanguage
        let rejectedCandidates: [RejectedCandidate]

        var hasValidData: Bool {
            cardName != nil || cardNumber != nil
        }

        var diagnosticMessage: String? {
            guard cardName == nil else { return nil }
            if allText.isEmpty {
                return "No text detected in image. Try better lighting or a clearer photo."
            }
            return "Could not identify a card name from detected text. Try manual entry."
        }
    }

    /// Perform OCR on a card image
    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            return OCRResult(cardName: nil, cardNumber: nil, setCode: nil, confidence: 0, allText: [], detectedLanguage: .english, rejectedCandidates: [])
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(cardName: nil, cardNumber: nil, setCode: nil, confidence: 0, allText: [], detectedLanguage: .english, rejectedCandidates: []))
                    return
                }

                var allTexts: [String] = []
                var bestName: String?
                var bestNumber: String?
                var maxConfidence: Double = 0

                for observation in observations {
                    if let candidate = observation.topCandidates(1).first {
                        allTexts.append(candidate.string)
                        maxConfidence = max(maxConfidence, Double(candidate.confidence))

                        // Simple heuristic: longest text is likely the card name
                        if candidate.string.count > (bestName?.count ?? 0) && candidate.string.count > 3 {
                            bestName = candidate.string
                        }

                        // Look for number patterns like "025/198" or "#025"
                        if let numberPattern = candidate.string.range(of: #"\d{1,3}(/\d{1,3})?"#, options: .regularExpression), bestNumber == nil {
                            bestNumber = String(candidate.string[numberPattern])
                        }
                    }
                }

                continuation.resume(returning: OCRResult(
                    cardName: bestName,
                    cardNumber: bestNumber,
                    setCode: nil,
                    confidence: maxConfidence,
                    allText: allTexts,
                    detectedLanguage: .english,
                    rejectedCandidates: []
                ))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
