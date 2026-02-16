import Foundation
import Observation

/// Phase of the listing generation flow (kept for backward compatibility)
public enum ListingGenerationPhase: Sendable {
    case input
    case generating
    case output
}
