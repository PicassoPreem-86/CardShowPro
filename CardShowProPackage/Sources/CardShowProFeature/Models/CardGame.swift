import Foundation

/// Supported trading card games
public enum CardGame: String, Codable, Sendable, CaseIterable, Identifiable {
    case pokemon = "Pokemon"
    case onePiece = "One Piece"
    case magicTheGathering = "Magic: The Gathering"
    case yuGiOh = "Yu-Gi-Oh!"
    case digimon = "Digimon"
    case dragonBall = "Dragon Ball"
    case lorcana = "Disney Lorcana"
    case fleshAndBlood = "Flesh and Blood"

    public var id: String { rawValue }

    /// Display name for UI
    public var displayName: String {
        rawValue
    }

    /// Short code for API requests
    public var code: String {
        switch self {
        case .pokemon: return "pokemon"
        case .onePiece: return "onepiece"
        case .magicTheGathering: return "mtg"
        case .yuGiOh: return "yugioh"
        case .digimon: return "digimon"
        case .dragonBall: return "dragonball"
        case .lorcana: return "lorcana"
        case .fleshAndBlood: return "fab"
        }
    }

    /// SF Symbol icon for the game
    public var icon: String {
        switch self {
        case .pokemon: return "star.fill"
        case .onePiece: return "tropicalstorm"
        case .magicTheGathering: return "wand.and.stars"
        case .yuGiOh: return "diamond.fill"
        case .digimon: return "cpu"
        case .dragonBall: return "circle.hexagongrid.fill"
        case .lorcana: return "sparkles"
        case .fleshAndBlood: return "flame.fill"
        }
    }

    /// Primary brand color
    public var brandColor: String {
        switch self {
        case .pokemon: return "#FFD700" // Thunder Yellow
        case .onePiece: return "#FF4444" // Red
        case .magicTheGathering: return "#FF8C00" // Orange
        case .yuGiOh: return "#8B00FF" // Purple
        case .digimon: return "#00D9FF" // Cyan
        case .dragonBall: return "#FF9500" // Orange
        case .lorcana: return "#4A90E2" // Blue
        case .fleshAndBlood: return "#DC143C" // Crimson
        }
    }

    /// Whether this game is currently supported for scanning
    public var isSupported: Bool {
        switch self {
        case .pokemon, .onePiece:
            return true
        case .magicTheGathering, .yuGiOh, .digimon, .dragonBall, .lorcana, .fleshAndBlood:
            return false // Coming soon
        }
    }

    /// Supported games for scanner
    public static var supported: [CardGame] {
        allCases.filter { $0.isSupported }
    }
}
