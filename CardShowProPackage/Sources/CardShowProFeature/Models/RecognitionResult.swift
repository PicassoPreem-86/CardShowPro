import Foundation

/// Result from card recognition API
struct RecognitionResult: Codable, Sendable {
    let cardName: String
    let setName: String
    let cardNumber: String
    let confidence: Double
    let rarity: String?
    let cardType: String?
    let subtype: String?
    let supertype: String?

    /// Whether the recognition is reliable enough to use
    var isReliable: Bool {
        confidence >= 0.80
    }

    /// Confidence level category
    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0.95...1.0:
            return .veryHigh
        case 0.85..<0.95:
            return .high
        case 0.70..<0.85:
            return .medium
        default:
            return .low
        }
    }

    enum ConfidenceLevel: String, Sendable {
        case veryHigh = "Very High"
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var color: String {
            switch self {
            case .veryHigh: return "green"
            case .high: return "blue"
            case .medium: return "yellow"
            case .low: return "red"
            }
        }
    }
}

/// Ximilar API specific response format
struct XimilarRecognitionResponse: Codable {
    let records: [XimilarRecord]

    struct XimilarRecord: Codable {
        let bestLabels: [XimilarLabel]?
        let customFields: [String: String]?
    }

    struct XimilarLabel: Codable {
        let name: String
        let prob: Double
    }

    /// Convert Ximilar response to our RecognitionResult
    func toRecognitionResult() -> RecognitionResult? {
        guard let record = records.first,
              let bestLabel = record.bestLabels?.first else {
            return nil
        }

        // Parse card name from label (format: "CardName | SetName #Number")
        let parts = bestLabel.name.components(separatedBy: " | ")
        let cardName = parts.first ?? bestLabel.name

        var setName = "Unknown Set"
        var cardNumber = "???"

        if parts.count > 1 {
            let setInfo = parts[1].components(separatedBy: " #")
            setName = setInfo.first ?? "Unknown Set"
            if setInfo.count > 1 {
                cardNumber = setInfo[1]
            }
        }

        return RecognitionResult(
            cardName: cardName,
            setName: setName,
            cardNumber: cardNumber,
            confidence: bestLabel.prob,
            rarity: record.customFields?["rarity"],
            cardType: record.customFields?["type"],
            subtype: record.customFields?["subtype"],
            supertype: record.customFields?["supertype"]
        )
    }
}

/// Generic recognition error
enum RecognitionError: LocalizedError {
    case noCardDetected
    case lowConfidence(score: Double)
    case apiError(String)
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noCardDetected:
            return "No card detected in image"
        case .lowConfidence(let score):
            return "Recognition uncertain (\(Int(score * 100))%)"
        case .apiError(let message):
            return "Recognition failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from recognition service"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noCardDetected:
            return "Try better lighting or a different angle"
        case .lowConfidence:
            return "Please verify the card details manually"
        case .apiError, .invalidResponse:
            return "Try manual entry or rescan the card"
        case .networkError:
            return "Check your internet connection and retry"
        }
    }
}
