import Foundation

/// Represents a Pokemon search result from the PokemonTCG API
struct PokemonSearchResult: Identifiable, Sendable {
    let id: String
    let name: String
    let imageURL: URL?
    let availableSets: [String]

    init(id: String, name: String, imageURL: URL? = nil, availableSets: [String] = []) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.availableSets = availableSets
    }
}
