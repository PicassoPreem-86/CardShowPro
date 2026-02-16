import Foundation

/// Network errors that can occur during API calls
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message ?? "Unknown error")"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noData:
            return "No data received from server"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .httpError(let statusCode, _):
            if statusCode == 429 {
                return "Too many requests. Please wait a moment."
            } else if statusCode >= 500 {
                return "Server error. Please try again later."
            } else {
                return "Please try again"
            }
        case .decodingError:
            return "The server response format has changed. Please update the app."
        default:
            return "Please try again"
        }
    }
}

/// Base network service for making HTTP requests
@MainActor
final class NetworkService: Sendable {
    static let shared = NetworkService()

    private let session: URLSession
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    /// Perform a GET request
    func get<T: Decodable>(
        url: URL,
        headers: [String: String] = [:],
        retryCount: Int = 3
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try await performRequest(request, retryCount: retryCount)
    }

    /// Perform a POST request with JSON body
    func post<T: Decodable, Body: Encodable>(
        url: URL,
        body: Body,
        headers: [String: String] = [:],
        retryCount: Int = 3
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)

        return try await performRequest(request, retryCount: retryCount)
    }

    /// Perform a POST request with multipart form data (for image upload)
    func postMultipart<T: Decodable>(
        url: URL,
        image: Data,
        fileName: String = "card.jpg",
        additionalFields: [String: String] = [:],
        headers: [String: String] = [:],
        retryCount: Int = 2
    ) async throws -> T {
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Build multipart body
        var body = Data()

        // Add additional fields
        for (key, value) in additionalFields {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
            body.append(Data("\(value)\r\n".utf8))
        }

        // Add image
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
        body.append(image)
        body.append(Data("\r\n".utf8))
        body.append(Data("--\(boundary)--\r\n".utf8))

        request.httpBody = body

        return try await performRequest(request, retryCount: retryCount)
    }

    /// Perform a POST request with base64-encoded image (for Ximilar API)
    func postBase64Image<T: Decodable>(
        url: URL,
        imageData: Data,
        headers: [String: String] = [:],
        retryCount: Int = 2
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode image to base64
        let base64String = imageData.base64EncodedString()

        // Build request body with records array
        let requestBody: [String: Any] = [
            "records": [
                [
                    "_base64": base64String
                ]
            ]
        ]

        // Convert to JSON
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        return try await performRequest(request, retryCount: retryCount)
    }

    /// Core request performer with retry logic
    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        retryCount: Int
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<retryCount {
            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                // Handle HTTP errors
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = String(data: data, encoding: .utf8)
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
                }

                // Decode response
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw NetworkError.decodingError(error)
                }
            } catch {
                lastError = error

                // Don't retry client errors (4xx)
                if case NetworkError.httpError(let statusCode, _) = error,
                   (400...499).contains(statusCode) {
                    throw error
                }

                // Wait before retry (exponential backoff)
                if attempt < retryCount - 1 {
                    let delay = retryDelay * pow(2.0, Double(attempt))
                    try? await Task.sleep(for: .seconds(delay))
                }
            }
        }

        // All retries failed
        throw NetworkError.networkError(lastError ?? NetworkError.invalidResponse)
    }
}
