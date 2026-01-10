import Foundation

/// Result from graded card slab recognition
struct SlabRecognitionResult: Codable, Sendable {
    let cardInfo: RecognitionResult  // The card inside the slab
    let isGraded: Bool
    let gradingCompany: GradingCompany?
    let grade: String?  // e.g. "10", "9.5", "BGS 9.5"
    let certificationNumber: String?
    let subGrades: SubGrades?  // For BGS

    /// Whether the slab recognition is reliable enough to use
    var isReliable: Bool {
        cardInfo.isReliable && (gradingCompany != nil || !isGraded)
    }

    /// Display grade with company prefix
    var displayGrade: String {
        guard let company = gradingCompany, let grade = grade else {
            return "Ungraded"
        }
        return "\(company.rawValue) \(grade)"
    }
}

/// BGS sub-grades
struct SubGrades: Codable, Sendable {
    let centering: Double?  // e.g. 10.0
    let corners: Double?    // e.g. 9.5
    let edges: Double?      // e.g. 10.0
    let surface: Double?    // e.g. 9.5

    /// Formatted display of sub-grades
    var formatted: String {
        var parts: [String] = []
        if let centering = centering {
            parts.append("Centering: \(centering)")
        }
        if let corners = corners {
            parts.append("Corners: \(corners)")
        }
        if let edges = edges {
            parts.append("Edges: \(edges)")
        }
        if let surface = surface {
            parts.append("Surface: \(surface)")
        }
        return parts.joined(separator: " | ")
    }

    /// Average of all sub-grades
    var average: Double? {
        let values = [centering, corners, edges, surface].compactMap { $0 }
        guard !values.isEmpty else { return nil }
        return values.reduce(0.0, +) / Double(values.count)
    }
}

/// Ximilar slab recognition response
struct XimilarSlabResponse: Codable, Sendable {
    let records: [SlabRecord]
    let status: XimilarStatus?

    struct SlabRecord: Codable, Sendable {
        let status: XimilarStatus?
        let slabInfo: SlabInfo?
        let cardInfo: XimilarCardInfo?

        private enum CodingKeys: String, CodingKey {
            case status = "_status"
            case slabInfo = "slab_info"
            case cardInfo = "card_info"
        }
    }

    struct SlabInfo: Codable, Sendable {
        let company: String?
        let grade: String?
        let certNumber: String?
        let subgrades: SubGradeInfo?

        private enum CodingKeys: String, CodingKey {
            case company, grade
            case certNumber = "cert_number"
            case subgrades
        }
    }

    struct SubGradeInfo: Codable, Sendable {
        let centering: Double?
        let corners: Double?
        let edges: Double?
        let surface: Double?
    }

    struct XimilarCardInfo: Codable, Sendable {
        let name: String?
        let setName: String?
        let number: String?
        let prob: Double?
        let rarity: String?
        let type: String?
        let subtype: String?
        let supertype: String?

        private enum CodingKeys: String, CodingKey {
            case name, number, prob, rarity, type, subtype, supertype
            case setName = "set_name"
        }
    }

    struct XimilarStatus: Codable, Sendable {
        let code: Int
        let text: String?
    }

    /// Convert to SlabRecognitionResult
    func toSlabResult(game: CardGame) -> SlabRecognitionResult? {
        guard let record = records.first,
              record.status?.code == 200 else {
            return nil
        }

        // Parse card info
        let cardInfo: RecognitionResult
        if let ximilarCard = record.cardInfo {
            cardInfo = RecognitionResult(
                cardName: ximilarCard.name ?? "Unknown",
                setName: ximilarCard.setName ?? "Unknown",
                cardNumber: ximilarCard.number ?? "???",
                confidence: ximilarCard.prob ?? 0.0,
                game: game,
                rarity: ximilarCard.rarity,
                cardType: ximilarCard.type,
                subtype: ximilarCard.subtype,
                supertype: ximilarCard.supertype
            )
        } else {
            // Fallback card info if API doesn't return card details
            cardInfo = RecognitionResult(
                cardName: "Unknown Card",
                setName: "Unknown Set",
                cardNumber: "???",
                confidence: 0.0,
                game: game,
                rarity: nil,
                cardType: nil,
                subtype: nil,
                supertype: nil
            )
        }

        // Parse slab info
        let slab = record.slabInfo
        let company = parseGradingCompany(slab?.company)

        // Parse sub-grades if available
        var subGrades: SubGrades?
        if let sub = slab?.subgrades {
            subGrades = SubGrades(
                centering: sub.centering,
                corners: sub.corners,
                edges: sub.edges,
                surface: sub.surface
            )
        }

        return SlabRecognitionResult(
            cardInfo: cardInfo,
            isGraded: slab != nil,
            gradingCompany: company,
            grade: slab?.grade,
            certificationNumber: slab?.certNumber,
            subGrades: subGrades
        )
    }

    /// Parse grading company name from API response
    private func parseGradingCompany(_ name: String?) -> GradingCompany? {
        guard let name = name?.uppercased() else { return nil }

        if name.contains("PSA") { return .psa }
        if name.contains("BGS") || name.contains("BECKETT") { return .bgs }
        if name.contains("CGC") { return .cgc }
        // Note: SGC and other companies not yet supported in GradingCompany enum

        return nil
    }
}

/// Slab recognition error types
enum SlabRecognitionError: LocalizedError {
    case noSlabDetected
    case invalidImage
    case lowConfidence(score: Double)
    case unrecognizedCompany(String)
    case invalidGrade(String)
    case apiError(String)
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noSlabDetected:
            return "No graded slab detected in image"
        case .invalidImage:
            return "Invalid image format"
        case .lowConfidence(let score):
            return "Recognition uncertain (\(Int(score * 100))%)"
        case .unrecognizedCompany(let company):
            return "Unrecognized grading company: \(company)"
        case .invalidGrade(let grade):
            return "Invalid grade format: \(grade)"
        case .apiError(let message):
            return "Slab recognition failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from slab recognition service"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noSlabDetected:
            return "Ensure the entire slab is visible with good lighting"
        case .invalidImage:
            return "Please try taking another photo"
        case .lowConfidence:
            return "Please verify the slab details manually"
        case .unrecognizedCompany, .invalidGrade:
            return "Please enter the grade information manually"
        case .apiError, .invalidResponse:
            return "Try manual entry or rescan the slab"
        case .networkError:
            return "Check your internet connection and retry"
        }
    }
}
