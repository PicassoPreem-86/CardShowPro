import Foundation

/// Result from card recognition API
struct RecognitionResult: Codable, Sendable {
    let cardName: String
    let setName: String
    let cardNumber: String
    let setCode: String?
    let confidence: Double
    let game: CardGame
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
struct XimilarRecognitionResponse: Codable, Sendable {
    let records: [XimilarRecord]
    let status: XimilarStatus?

    struct XimilarRecord: Codable, Sendable {
        let status: XimilarStatus?
        let objects: [XimilarObject]?

        private enum CodingKeys: String, CodingKey {
            case status = "_status"
            case objects
        }
    }

    struct XimilarObject: Codable, Sendable {
        let name: String?
        let prob: Double?
        let tags: [XimilarTag]?

        // Additional metadata fields
        let setName: String?
        let number: String?
        let rarity: String?
        let type: String?
        let subtype: String?
        let supertype: String?

        private enum CodingKeys: String, CodingKey {
            case name, prob, tags
            case setName = "set_name"
            case number, rarity, type, subtype, supertype
        }
    }

    struct XimilarTag: Codable, Sendable {
        let name: String
        let prob: Double?
    }

    struct XimilarStatus: Codable, Sendable {
        let code: Int
        let text: String?
    }

    /// Convert Ximilar response to our RecognitionResult
    func toRecognitionResult(game: CardGame) -> RecognitionResult? {
        // Check overall response status
        guard status?.code == 200 else {
            return nil
        }

        guard let record = records.first,
              record.status?.code == 200,
              let objects = record.objects,
              let firstObject = objects.first else {
            return nil
        }

        // Extract card information from the object
        let cardName = firstObject.name ?? "Unknown Card"
        let confidence = firstObject.prob ?? 0.0

        // Extract set information - try from direct fields first, then from tags
        var setName = firstObject.setName ?? "Unknown Set"
        var cardNumber = firstObject.number ?? "???"
        var rarity = firstObject.rarity
        var cardType = firstObject.type
        var subtype = firstObject.subtype
        var supertype = firstObject.supertype

        // Parse tags for additional information if available
        if let tags = firstObject.tags {
            for tag in tags {
                let tagName = tag.name
                if tagName.starts(with: "set:") {
                    setName = String(tagName.dropFirst(4))
                } else if tagName.starts(with: "number:") {
                    cardNumber = String(tagName.dropFirst(7))
                } else if tagName.starts(with: "rarity:") {
                    rarity = String(tagName.dropFirst(7))
                } else if tagName.starts(with: "type:") {
                    cardType = String(tagName.dropFirst(5))
                }
            }
        }

        // Alternative: Parse from name if it contains " | " separator
        // Format: "CardName | SetName #Number"
        if cardName.contains(" | ") {
            let parts = cardName.components(separatedBy: " | ")
            let actualCardName = parts.first ?? cardName

            if parts.count > 1 {
                let setInfo = parts[1].components(separatedBy: " #")
                setName = setInfo.first ?? setName
                if setInfo.count > 1 {
                    cardNumber = setInfo[1]
                }
            }

            return RecognitionResult(
                cardName: actualCardName,
                setName: setName,
                cardNumber: cardNumber,
                setCode: nil,
                confidence: confidence,
                game: game,
                rarity: rarity,
                cardType: cardType,
                subtype: subtype,
                supertype: supertype
            )
        }

        return RecognitionResult(
            cardName: cardName,
            setName: setName,
            cardNumber: cardNumber,
            setCode: nil,
            confidence: confidence,
            game: game,
            rarity: rarity,
            cardType: cardType,
            subtype: subtype,
            supertype: supertype
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
