import Foundation

/// Trading card variants (foil types, special editions)
enum CardVariant: String, CaseIterable, Sendable {
    case standard = "Standard"
    case holo = "Holo"
    case reverseHolo = "Reverse Holo"
    case firstEdition = "1st Edition"
    case shadowless = "Shadowless"
    case pokemonCenter = "Pokemon Center"
    case pokeball = "Pokeball"
    case masterball = "Master Ball"
    case goldStar = "Gold Star"

    var displayName: String { rawValue }

    var priceMultiplier: Double {
        switch self {
        case .standard: return 1.0
        case .holo: return 1.5
        case .reverseHolo: return 1.3
        case .firstEdition: return 3.0
        case .shadowless: return 4.0
        case .pokemonCenter: return 2.0
        case .pokeball: return 1.8
        case .masterball: return 2.5
        case .goldStar: return 10.0
        }
    }
}
