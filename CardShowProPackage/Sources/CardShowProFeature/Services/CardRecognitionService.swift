import Foundation
import UIKit

/// Service for recognizing trading cards from images using Ximilar API
/// Supports multiple TCG games including Pokemon, One Piece, and more
@MainActor
@Observable
final class CardRecognitionService {
    static let shared = CardRecognitionService()

    private let networkService = NetworkService.shared

    // MARK: - Configuration
    // TODO: Move API key to secure storage (Keychain)
    // To configure:
    // 1. Sign up at https://app.ximilar.com/
    // 2. Get your API token from the dashboard
    // 3. Replace the empty string below with your token
    // 4. Set useRealAPI to true
    private let ximilarAPIKey = "cefead39dcded9fbabc0fce72bd588594d70d308" // Add your Ximilar API token here (e.g., "your-api-token-here")
    private let useRealAPI = true // Set to true when API token is configured

    // MARK: - State
    var isProcessing = false
    var lastError: RecognitionError?

    private init() {}

    // MARK: - Public API

    /// Recognize a trading card from an image
    /// - Parameters:
    ///   - image: The image containing the card to recognize
    ///   - game: The trading card game type (defaults to Pokemon)
    /// - Returns: Recognition result with card details
    func recognizeCard(from image: UIImage, game: CardGame = .pokemon) async throws -> RecognitionResult {
        isProcessing = true
        defer { isProcessing = false }

        // Compress image for upload
        guard let imageData = compressImage(image, maxSizeKB: 500) else {
            throw RecognitionError.invalidResponse
        }

        if useRealAPI && !ximilarAPIKey.isEmpty {
            return try await recognizeWithXimilar(imageData: imageData, game: game)
        } else {
            // Use mock recognition for development/testing
            return try await mockRecognition(imageData: imageData, game: game)
        }
    }

    // MARK: - Ximilar API Integration

    private func recognizeWithXimilar(imageData: Data, game: CardGame) async throws -> RecognitionResult {
        // Ximilar Collectibles Recognition API endpoint for TCG identification
        // Note: The same endpoint supports multiple TCG games
        guard let url = URL(string: "https://api.ximilar.com/collectibles/v2/tcg_id") else {
            throw NetworkError.invalidURL
        }

        // Setup headers with Token authentication
        let headers = [
            "Authorization": "Token \(ximilarAPIKey)"
        ]

        do {
            // Use base64 image encoding (Ximilar's preferred format)
            let response: XimilarRecognitionResponse = try await networkService.postBase64Image(
                url: url,
                imageData: imageData,
                headers: headers,
                retryCount: 2
            )

            // Convert Ximilar response to our internal format
            guard let result = response.toRecognitionResult(game: game) else {
                throw RecognitionError.noCardDetected
            }

            // Check confidence threshold (60% minimum for reliability)
            guard result.confidence >= 0.60 else {
                throw RecognitionError.lowConfidence(score: result.confidence)
            }

            return result
        } catch let error as NetworkError {
            // Handle specific network errors
            switch error {
            case .httpError(let statusCode, let message):
                if statusCode == 401 {
                    throw RecognitionError.apiError("Invalid API token. Please check your Ximilar configuration.")
                } else if statusCode == 429 {
                    throw RecognitionError.apiError("API rate limit exceeded. Please try again later.")
                } else if statusCode >= 500 {
                    throw RecognitionError.apiError("Ximilar service unavailable. Please try again later.")
                } else {
                    throw RecognitionError.apiError(message ?? "HTTP Error \(statusCode)")
                }
            case .decodingError:
                throw RecognitionError.invalidResponse
            default:
                throw RecognitionError.networkError(error)
            }
        } catch let error as RecognitionError {
            // Re-throw recognition errors as-is
            throw error
        } catch {
            // Handle any other errors
            throw RecognitionError.apiError(error.localizedDescription)
        }
    }

    // MARK: - Mock Recognition (for development)

    private func mockRecognition(imageData: Data, game: CardGame) async throws -> RecognitionResult {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(800))

        // Game-specific mock card data
        let randomCard: (name: String, set: String, number: String, confidence: Double, rarity: String, type: String, subtype: String?, supertype: String)

        switch game {
        case .pokemon:
            let pokemonCards = [
                ("Charizard VMAX", "Darkness Ablaze", "020", 0.94, "Rare Holo VMAX", "Fire", "VMAX", "Pokemon"),
                ("Pikachu VMAX", "Vivid Voltage", "044", 0.92, "Rare Holo VMAX", "Lightning", "VMAX", "Pokemon"),
                ("Mewtwo V", "Pokemon GO", "030", 0.89, "Rare Holo V", "Psychic", "V", "Pokemon"),
                ("Rayquaza VMAX", "Evolving Skies", "111", 0.91, "Rare Holo VMAX", "Dragon", "VMAX", "Pokemon"),
                ("Umbreon VMAX", "Evolving Skies", "095", 0.93, "Rare Holo VMAX", "Darkness", "VMAX", "Pokemon"),
                ("Lugia V", "Silver Tempest", "138", 0.88, "Rare Holo V", "Colorless", "V", "Pokemon"),
                ("Giratina VSTAR", "Lost Origin", "131", 0.90, "Rare Holo VSTAR", "Dragon", "VSTAR", "Pokemon"),
                ("Mew VMAX", "Fusion Strike", "114", 0.87, "Rare Holo VMAX", "Psychic", "VMAX", "Pokemon"),
                ("Greninja ex", "Paldea Evolved", "112", 0.95, "Double Rare", "Water", "ex", "Pokemon"),
                ("Iono", "Paldea Evolved", "185", 0.86, "Ultra Rare", "Supporter", nil, "Trainer")
            ]
            randomCard = pokemonCards.randomElement()!

        case .onePiece:
            let onePieceCards = [
                ("Monkey D. Luffy", "Romance Dawn", "OP01-001", 0.95, "Leader", "DON!! Card", "Leader", "Character"),
                ("Roronoa Zoro", "Romance Dawn", "OP01-025", 0.93, "Rare", "Straw Hat Crew", "Rare", "Character"),
                ("Nami", "Paramount War", "OP02-036", 0.91, "Uncommon", "Straw Hat Crew", "Uncommon", "Character"),
                ("Portgas D. Ace", "Memorial Collection", "OP03-001", 0.94, "Secret Rare", "Whitebeard Pirates", "Secret Rare", "Character"),
                ("Shanks", "Romance Dawn", "OP01-120", 0.92, "Super Rare", "Red Hair Pirates", "Super Rare", "Character"),
                ("Trafalgar Law", "Paramount War", "OP02-042", 0.90, "Super Rare", "Heart Pirates", "Super Rare", "Character"),
                ("Boa Hancock", "Romance Dawn", "OP01-078", 0.88, "Rare", "Kuja Pirates", "Rare", "Character"),
                ("Kaido", "Kingdoms of Intrigue", "OP04-044", 0.89, "Secret Rare", "Animal Kingdom Pirates", "Secret Rare", "Character"),
                ("Nico Robin", "Paramount War", "OP02-062", 0.87, "Uncommon", "Straw Hat Crew", "Uncommon", "Character"),
                ("Gum-Gum Red Roc", "Romance Dawn", "OP01-095", 0.86, "Common", "Event", "Common", "Event")
            ]
            randomCard = onePieceCards.randomElement()!

        default:
            // Fallback for unsupported games (shouldn't happen with current logic)
            randomCard = ("Unknown Card", "Unknown Set", "???", 0.50, "Unknown", "Unknown", nil, "Unknown")
        }

        return RecognitionResult(
            cardName: randomCard.name,
            setName: randomCard.set,
            cardNumber: randomCard.number,
            confidence: randomCard.confidence,
            game: game,
            rarity: randomCard.rarity,
            cardType: randomCard.type,
            subtype: randomCard.subtype,
            supertype: randomCard.supertype
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
        !ximilarAPIKey.isEmpty
    }

    /// Get configuration status message
    var configurationStatus: String {
        if useRealAPI && isConfigured {
            return "Using Ximilar API"
        } else if useRealAPI && !isConfigured {
            return "API token not configured - using mock data"
        } else {
            return "Using mock recognition for testing"
        }
    }
}
