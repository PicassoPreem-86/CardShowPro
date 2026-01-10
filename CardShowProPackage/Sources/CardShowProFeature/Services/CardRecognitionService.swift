import Foundation
import UIKit

/// Service for recognizing Pokemon cards from images
@MainActor
@Observable
final class CardRecognitionService {
    static let shared = CardRecognitionService()

    private let networkService = NetworkService.shared

    // MARK: - Configuration
    // TODO: Move API key to secure storage (Keychain)
    private let ximilarAPIKey = "" // Add your Ximilar API key here
    private let ximilarTaskID = "" // Add your Ximilar task ID here
    private let useRealAPI = false // Set to true when API keys are configured

    // MARK: - State
    var isProcessing = false
    var lastError: RecognitionError?

    private init() {}

    // MARK: - Public API

    /// Recognize a Pokemon card from an image
    func recognizeCard(from image: UIImage) async throws -> RecognitionResult {
        isProcessing = true
        defer { isProcessing = false }

        // Compress image for upload
        guard let imageData = compressImage(image, maxSizeKB: 500) else {
            throw RecognitionError.invalidResponse
        }

        if useRealAPI && !ximilarAPIKey.isEmpty {
            return try await recognizeWithXimilar(imageData: imageData)
        } else {
            // Use mock recognition for development/testing
            return try await mockRecognition(imageData: imageData)
        }
    }

    // MARK: - Ximilar API Integration

    private func recognizeWithXimilar(imageData: Data) async throws -> RecognitionResult {
        guard let url = URL(string: "https://api.ximilar.com/recognition/v2/classify") else {
            throw NetworkError.invalidURL
        }

        let headers = [
            "Authorization": "Token \(ximilarAPIKey)"
        ]

        let fields = [
            "task_id": ximilarTaskID
        ]

        do {
            let response: XimilarRecognitionResponse = try await networkService.postMultipart(
                url: url,
                image: imageData,
                fileName: "card.jpg",
                additionalFields: fields,
                headers: headers,
                retryCount: 2
            )

            guard let result = response.toRecognitionResult() else {
                throw RecognitionError.noCardDetected
            }

            // Check confidence threshold
            guard result.confidence >= 0.60 else {
                throw RecognitionError.lowConfidence(score: result.confidence)
            }

            return result
        } catch let error as NetworkError {
            throw RecognitionError.networkError(error)
        } catch {
            throw RecognitionError.apiError(error.localizedDescription)
        }
    }

    // MARK: - Mock Recognition (for development)

    private func mockRecognition(imageData: Data) async throws -> RecognitionResult {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(800))

        // Random selection from common Pokemon cards
        let mockCards = [
            ("Charizard VMAX", "Darkness Ablaze", "020", 0.94, "Rare Holo VMAX"),
            ("Pikachu VMAX", "Vivid Voltage", "044", 0.92, "Rare Holo VMAX"),
            ("Mewtwo V", "Pokemon GO", "030", 0.89, "Rare Holo V"),
            ("Rayquaza VMAX", "Evolving Skies", "111", 0.91, "Rare Holo VMAX"),
            ("Umbreon VMAX", "Evolving Skies", "095", 0.93, "Rare Holo VMAX"),
            ("Lugia V", "Silver Tempest", "138", 0.88, "Rare Holo V"),
            ("Giratina VSTAR", "Lost Origin", "131", 0.90, "Rare Holo VSTAR"),
            ("Mew VMAX", "Fusion Strike", "114", 0.87, "Rare Holo VMAX"),
            ("Greninja ex", "Paldea Evolved", "112", 0.95, "Double Rare"),
            ("Iono", "Paldea Evolved", "185", 0.86, "Ultra Rare")
        ]

        let randomCard = mockCards.randomElement()!

        return RecognitionResult(
            cardName: randomCard.0,
            setName: randomCard.1,
            cardNumber: randomCard.2,
            confidence: randomCard.3,
            rarity: randomCard.4,
            cardType: "Pokemon",
            subtype: nil,
            supertype: "Pokemon"
        )
    }

    // MARK: - Image Processing

    /// Compress image to reduce upload size and processing time
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data? {
        let maxSizeBytes = maxSizeKB * 1024
        var compression: CGFloat = 0.9
        var imageData = image.jpegData(compressionQuality: compression)

        // Iteratively reduce quality until size is acceptable
        while let data = imageData, data.count > maxSizeBytes, compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        // If still too large, resize image
        if let data = imageData, data.count > maxSizeBytes {
            let scaleFactor = sqrt(Double(maxSizeBytes) / Double(data.count))
            let newSize = CGSize(
                width: image.size.width * scaleFactor,
                height: image.size.height * scaleFactor
            )

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            imageData = resizedImage?.jpegData(compressionQuality: 0.8)
        }

        return imageData
    }
}

// MARK: - Configuration Helper

extension CardRecognitionService {
    /// Check if API is properly configured
    var isConfigured: Bool {
        !ximilarAPIKey.isEmpty && !ximilarTaskID.isEmpty
    }

    /// Get configuration status message
    var configurationStatus: String {
        if useRealAPI && isConfigured {
            return "Using Ximilar API"
        } else if useRealAPI && !isConfigured {
            return "API key not configured - using mock data"
        } else {
            return "Using mock recognition for testing"
        }
    }
}
