import Foundation

// MARK: - CardLanguage

/// Language of a card for search/filter purposes
enum CardLanguage: String, Sendable, CaseIterable {
    case english = "en"
    case japanese = "ja"
    case chineseTraditional = "zh-TW"
}

// MARK: - CardMatchSource

/// Source database for a local card match
enum CardMatchSource: String, Sendable {
    case pokemontcg = "pokemontcg"
    case local = "local"
}

// MARK: - LocalCardMatch

/// A card match from the local SQLite database
struct LocalCardMatch: Identifiable, Sendable {
    let id: String
    let cardName: String
    let setName: String
    let setID: String
    let cardNumber: String
    let imageURLSmall: String?
    let rarity: String?
    let language: CardLanguage?
    let source: CardMatchSource

    /// Convert to CardMatch for use with pricing APIs
    func toCardMatch() -> CardMatch {
        CardMatch(
            id: id,
            cardName: cardName,
            setName: setName,
            setID: setID,
            cardNumber: cardNumber,
            imageURL: imageURLSmall.flatMap { URL(string: $0) }
        )
    }
}
