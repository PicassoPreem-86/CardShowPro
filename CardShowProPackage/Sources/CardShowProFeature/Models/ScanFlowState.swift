import Foundation
import SwiftUI

/// Manages state for the manual card entry flow
@MainActor
@Observable
final class ScanFlowState {
    // MARK: - Flow Steps
    enum Step: Equatable {
        case entry  // Single entry screen
        case success(card: InventoryCard)
    }

    var currentStep: Step = .entry
    var isLoading = false
    var errorMessage: String?

    // MARK: - Entry State (Card Name, Number, Variant)
    var cardName = ""
    var cardNumber = ""
    var selectedVariant: CardVariant = .standard
    var selectedCondition: CardCondition = .nearMint
    var fetchedPrice: Double?
    var cardImageURL: URL?

    // Recent card names for quick entry
    var recentCardNames: [String] {
        get { UserDefaults.standard.stringArray(forKey: "recentCardNames") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "recentCardNames") }
    }

    // Bulk entry mode state
    var isBulkMode = false
    var bulkModeSessionCount = 0

    // MARK: - Disambiguation (when multiple sets match)
    var availableMatches: [CardMatch] = []
    var selectedSet: CardSet?

    // MARK: - Actions
    func resetFlow() {
        currentStep = .entry
        cardName = ""
        cardNumber = ""
        selectedVariant = .standard
        selectedCondition = .nearMint
        fetchedPrice = nil
        cardImageURL = nil
        selectedSet = nil
        errorMessage = nil
        availableMatches = []
    }

    func resetForBulkEntry() {
        // Keep variant and condition for bulk mode
        cardName = ""
        cardNumber = ""
        fetchedPrice = nil
        cardImageURL = nil
        selectedSet = nil
        errorMessage = nil
        availableMatches = []
    }

    func addToRecentCardNames(_ name: String) {
        var recent = recentCardNames
        recent.removeAll { $0 == name }
        recent.insert(name, at: 0)
        recentCardNames = Array(recent.prefix(10)) // Keep last 10
    }
}

/// Represents a card match from search (includes set info)
public struct CardMatch: Identifiable, Sendable {
    public let id: String  // Card ID
    public let cardName: String
    public let setName: String
    public let setID: String
    public let cardNumber: String
    public let imageURL: URL?

    public init(id: String, cardName: String, setName: String, setID: String, cardNumber: String, imageURL: URL?) {
        self.id = id
        self.cardName = cardName
        self.setName = setName
        self.setID = setID
        self.cardNumber = cardNumber
        self.imageURL = imageURL
    }
}

/// Represents a Pokemon card set
struct CardSet: Identifiable, Sendable {
    let id: String
    let name: String
    let releaseDate: String
    let logoURL: URL?
    let total: Int

    init(id: String, name: String, releaseDate: String, logoURL: URL? = nil, total: Int = 0) {
        self.id = id
        self.name = name
        self.releaseDate = releaseDate
        self.logoURL = logoURL
        self.total = total
    }
}
