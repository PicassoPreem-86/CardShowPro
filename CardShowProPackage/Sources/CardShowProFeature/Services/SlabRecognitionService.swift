import Foundation
import UIKit

/// Service for recognizing graded card slabs using Ximilar Visual AI
@MainActor
final class SlabRecognitionService: Sendable {
    static let shared = SlabRecognitionService()
    
    // MARK: - Configuration

    /// Ximilar API endpoint for slab recognition
    private let slabEndpoint = "https://api.ximilar.com/v2/slab_id"

    /// API token - replace with your actual token from https://dashboard.ximilar.com
    private let apiToken = "cefead39dcded9fbabc0fce72bd588594d70d308"

    /// Toggle between real API and mock data for testing
    private let useRealAPI = true
    
    /// Network service for API calls
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // MARK: - Public API
    
    /// Recognizes a graded card slab from an image
    /// - Parameters:
    ///   - image: UIImage of the graded slab
    ///   - game: The card game type (Pokemon, One Piece, etc.)
    /// - Returns: SlabRecognitionResult with card info and grading details
    /// - Throws: SlabRecognitionError if recognition fails
    func recognizeSlab(from image: UIImage, game: CardGame = .pokemon) async throws -> SlabRecognitionResult {
        // Use mock data for testing if real API is disabled
        if !useRealAPI {
            return try await mockSlabRecognition(game: game)
        }
        
        // Prepare image data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SlabRecognitionError.invalidImage
        }
        
        // Create multipart form data request
        var request = URLRequest(url: URL(string: slabEndpoint)!)
        request.httpMethod = "POST"
        request.setValue(apiToken, forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build request body
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"slab.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add game type metadata
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"game\"\r\n\r\n".data(using: .utf8)!)
        body.append(game.code.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Make API request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SlabRecognitionError.networkError(URLError(.badServerResponse))
        }
        
        guard httpResponse.statusCode == 200 else {
            throw SlabRecognitionError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse response
        let decoder = JSONDecoder()
        let ximilarResponse = try decoder.decode(XimilarSlabResponse.self, from: data)
        
        guard let result = ximilarResponse.toSlabResult(game: game) else {
            throw SlabRecognitionError.noSlabDetected
        }
        
        // Validate confidence threshold
        if result.cardInfo.confidence < 0.70 {
            throw SlabRecognitionError.lowConfidence(score: result.cardInfo.confidence)
        }
        
        return result
    }
    
    // MARK: - Mock Data
    
    /// Mock slab recognition for testing without API calls
    private func mockSlabRecognition(game: CardGame) async throws -> SlabRecognitionResult {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(800))
        
        // Mock graded slabs by game type
        let mockSlabs: [(cardName: String, setName: String, cardNumber: String, confidence: Double, company: GradingCompany, grade: String, certNumber: String, subGrades: SubGrades?)]
        
        switch game {
        case .pokemon:
            mockSlabs = [
                ("Charizard", "Base Set", "4/102", 0.96, .psa, "10", "12345678", nil),
                ("Pikachu VMAX", "Vivid Voltage", "044/185", 0.94, .bgs, "9.5", "0012345678", SubGrades(centering: 9.5, corners: 9.5, edges: 10.0, surface: 9.5)),
                ("Lugia", "Neo Genesis", "9/111", 0.95, .cgc, "9", "CGC-123456", nil),
                ("Mewtwo GX", "Shining Legends", "76/73", 0.93, .psa, "9", "87654321", nil),
                ("Umbreon VMAX", "Evolving Skies", "215/203", 0.97, .bgs, "10", "0098765432", SubGrades(centering: 10.0, corners: 10.0, edges: 10.0, surface: 10.0)),
                ("Rayquaza", "Dragon Frontiers", "4/101", 0.92, .cgc, "9.5", "CGC-789012", nil),
                ("Gyarados", "Team Rocket", "13/82", 0.91, .psa, "8", "56781234", nil),
                ("Blastoise", "Base Set", "2/102", 0.96, .cgc, "9.5", "CGC-234567", nil)
            ]
        case .onePiece:
            mockSlabs = [
                ("Monkey D. Luffy", "Romance Dawn", "OP01-001", 0.95, .psa, "10", "23456789", nil),
                ("Roronoa Zoro", "Romance Dawn", "OP01-025", 0.93, .bgs, "9.5", "0023456789", SubGrades(centering: 9.5, corners: 9.5, edges: 9.5, surface: 10.0)),
                ("Nami", "Paramount War", "OP02-036", 0.94, .cgc, "9", "CGC-345678", nil),
                ("Portgas D. Ace", "Romance Dawn", "OP01-013", 0.96, .psa, "10", "34567890", nil),
                ("Shanks", "Romance Dawn", "OP01-120", 0.97, .bgs, "10", "0034567890", SubGrades(centering: 10.0, corners: 10.0, edges: 10.0, surface: 10.0)),
                ("Trafalgar Law", "Paramount War", "OP02-121", 0.92, .psa, "9", "45678901", nil)
            ]
        default:
            mockSlabs = []
        }
        
        guard let mockData = mockSlabs.randomElement() else {
            throw SlabRecognitionError.noSlabDetected
        }
        
        // Create recognition result for the card inside the slab
        let cardInfo = RecognitionResult(
            cardName: mockData.cardName,
            setName: mockData.setName,
            cardNumber: mockData.cardNumber,
            confidence: mockData.confidence,
            game: game,
            rarity: "Rare",
            cardType: nil,
            subtype: nil,
            supertype: nil
        )
        
        return SlabRecognitionResult(
            cardInfo: cardInfo,
            isGraded: true,
            gradingCompany: mockData.company,
            grade: mockData.grade,
            certificationNumber: mockData.certNumber,
            subGrades: mockData.subGrades
        )
    }
}

// MARK: - Helper Extensions

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
