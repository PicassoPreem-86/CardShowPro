import Foundation

/// Feature flags for controlling experimental features
@MainActor
@Observable
final class FeatureFlags {
    static let shared = FeatureFlags()

    private init() {}

    /// Whether to use local SQLite database for card search
    var shouldUseLocalSearch: Bool = false

    /// Whether to rectify card images before OCR
    var shouldRectifyImages: Bool = false

    /// Whether to enable live video mode
    var shouldUseLiveVideo: Bool = false
}
