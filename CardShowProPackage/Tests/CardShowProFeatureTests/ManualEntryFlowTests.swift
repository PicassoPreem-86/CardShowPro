import Testing
@testable import CardShowProFeature
import Foundation

// MARK: - ScanFlowState Tests

@Test @MainActor func scanFlowStateInitialStateIsSearch() async throws {
    let state = ScanFlowState()

    #expect(state.currentStep == .search)
}

@Test @MainActor func scanFlowStateResetFlowResetsAllProperties() async throws {
    let state = ScanFlowState()

    // Set various properties to non-default values
    state.currentStep = .setSelection(pokemonName: "Pikachu")
    state.searchQuery = "test query"
    state.searchResults = [
        PokemonSearchResult(id: "1", name: "Pikachu", availableSets: [])
    ]
    state.cardNumber = "025"
    state.selectedVariant = .holo
    state.selectedCondition = .played
    state.fetchedPrice = 100.0
    state.cardImageURL = URL(string: "https://example.com/image.png")
    state.selectedSet = CardSet(id: "base1", name: "Base Set", releaseDate: "1999-01-09")
    state.errorMessage = "Some error"

    // Reset flow
    state.resetFlow()

    // Verify all properties reset to defaults
    #expect(state.currentStep == .search)
    #expect(state.searchQuery == "")
    #expect(state.searchResults.isEmpty)
    #expect(state.cardNumber == "")
    #expect(state.selectedVariant == .standard)
    #expect(state.selectedCondition == .nearMint)
    #expect(state.fetchedPrice == nil)
    #expect(state.cardImageURL == nil)
    #expect(state.selectedSet == nil)
    #expect(state.errorMessage == nil)
}

@Test @MainActor func scanFlowStateAddToRecentSearchesAddsToFront() async throws {
    let state = ScanFlowState()

    // Clear any existing recent searches
    state.recentSearches = []

    // Add first search
    state.addToRecentSearches("Pikachu")
    #expect(state.recentSearches == ["Pikachu"])

    // Add second search
    state.addToRecentSearches("Charizard")
    #expect(state.recentSearches == ["Charizard", "Pikachu"])

    // Add duplicate - should move to front and remove old position
    state.addToRecentSearches("Pikachu")
    #expect(state.recentSearches == ["Pikachu", "Charizard"])
}

@Test @MainActor func scanFlowStateRecentSearchesLimitedToFive() async throws {
    let state = ScanFlowState()

    // Clear any existing recent searches
    state.recentSearches = []

    // Add 6 searches
    state.addToRecentSearches("Pokemon1")
    state.addToRecentSearches("Pokemon2")
    state.addToRecentSearches("Pokemon3")
    state.addToRecentSearches("Pokemon4")
    state.addToRecentSearches("Pokemon5")
    state.addToRecentSearches("Pokemon6")

    // Should only keep last 5
    #expect(state.recentSearches.count == 5)
    #expect(state.recentSearches == ["Pokemon6", "Pokemon5", "Pokemon4", "Pokemon3", "Pokemon2"])
}

@Test @MainActor func scanFlowStateNavigatesThroughSteps() async throws {
    let state = ScanFlowState()

    // Start at search
    #expect(state.currentStep == .search)

    // Move to set selection
    state.currentStep = .setSelection(pokemonName: "Pikachu")
    if case .setSelection(let pokemonName) = state.currentStep {
        #expect(pokemonName == "Pikachu")
    } else {
        Issue.record("Expected setSelection step")
    }

    // Move to card entry
    state.currentStep = .cardEntry(pokemonName: "Pikachu", setName: "Base Set", setID: "base1")
    if case .cardEntry(let pokemonName, let setName, let setID) = state.currentStep {
        #expect(pokemonName == "Pikachu")
        #expect(setName == "Base Set")
        #expect(setID == "base1")
    } else {
        Issue.record("Expected cardEntry step")
    }
}

// MARK: - CardVariant Tests

@Test func cardVariantStandardHasMultiplierOfOne() async throws {
    let variant = CardVariant.standard
    #expect(variant.priceMultiplier == 1.0)
}

@Test func cardVariantGoldStarHasMultiplierOfTen() async throws {
    let variant = CardVariant.goldStar
    #expect(variant.priceMultiplier == 10.0)
}

@Test func cardVariantAllNineVariantsExist() async throws {
    let allVariants = CardVariant.allCases

    #expect(allVariants.count == 9)
    #expect(allVariants.contains(.standard))
    #expect(allVariants.contains(.holo))
    #expect(allVariants.contains(.reverseHolo))
    #expect(allVariants.contains(.firstEdition))
    #expect(allVariants.contains(.shadowless))
    #expect(allVariants.contains(.pokemonCenter))
    #expect(allVariants.contains(.pokeball))
    #expect(allVariants.contains(.masterball))
    #expect(allVariants.contains(.goldStar))
}

@Test func cardVariantPriceMultipliersAreCorrect() async throws {
    #expect(CardVariant.standard.priceMultiplier == 1.0)
    #expect(CardVariant.holo.priceMultiplier == 1.5)
    #expect(CardVariant.reverseHolo.priceMultiplier == 1.3)
    #expect(CardVariant.firstEdition.priceMultiplier == 3.0)
    #expect(CardVariant.shadowless.priceMultiplier == 4.0)
    #expect(CardVariant.pokemonCenter.priceMultiplier == 2.0)
    #expect(CardVariant.pokeball.priceMultiplier == 1.8)
    #expect(CardVariant.masterball.priceMultiplier == 2.5)
    #expect(CardVariant.goldStar.priceMultiplier == 10.0)
}

@Test func cardVariantDisplayNameMatchesRawValue() async throws {
    for variant in CardVariant.allCases {
        #expect(variant.displayName == variant.rawValue)
    }
}

// MARK: - PokemonTCGService Tests

@Test @MainActor func pokemonTCGServiceSingletonExists() async throws {
    let service = PokemonTCGService.shared
    #expect(service != nil)
}

@Test @MainActor func pokemonTCGServiceGetPopularPokemonReturnsMinimumEight() async throws {
    let service = PokemonTCGService.shared
    let popularPokemon = service.getPopularPokemon()

    #expect(popularPokemon.count >= 8)
}

@Test @MainActor func pokemonTCGServiceGetPopularPokemonReturnsValidNames() async throws {
    let service = PokemonTCGService.shared
    let popularPokemon = service.getPopularPokemon()

    // Verify some expected Pokemon are in the list
    #expect(popularPokemon.contains("Pikachu"))
    #expect(popularPokemon.contains("Charizard"))
    #expect(popularPokemon.contains("Mewtwo"))
}

@Test @MainActor func pokemonTCGServiceInitialStateIsNotLoading() async throws {
    let service = PokemonTCGService.shared
    #expect(service.isLoading == false)
}

// MARK: - Model Tests

@Test func pokemonSearchResultCreation() async throws {
    let result = PokemonSearchResult(
        id: "test-id",
        name: "Pikachu",
        imageURL: URL(string: "https://example.com/image.png"),
        availableSets: ["Base Set", "Jungle"]
    )

    #expect(result.id == "test-id")
    #expect(result.name == "Pikachu")
    #expect(result.imageURL?.absoluteString == "https://example.com/image.png")
    #expect(result.availableSets.count == 2)
    #expect(result.availableSets.contains("Base Set"))
}

@Test func pokemonSearchResultCreationWithDefaults() async throws {
    let result = PokemonSearchResult(id: "test-id", name: "Charizard")

    #expect(result.id == "test-id")
    #expect(result.name == "Charizard")
    #expect(result.imageURL == nil)
    #expect(result.availableSets.isEmpty)
}

@Test func cardSetCreation() async throws {
    let set = CardSet(
        id: "base1",
        name: "Base Set",
        releaseDate: "1999-01-09",
        logoURL: URL(string: "https://example.com/logo.png"),
        total: 102
    )

    #expect(set.id == "base1")
    #expect(set.name == "Base Set")
    #expect(set.releaseDate == "1999-01-09")
    #expect(set.logoURL?.absoluteString == "https://example.com/logo.png")
    #expect(set.total == 102)
}

@Test func cardSetCreationWithDefaults() async throws {
    let set = CardSet(id: "base1", name: "Base Set", releaseDate: "1999-01-09")

    #expect(set.id == "base1")
    #expect(set.name == "Base Set")
    #expect(set.releaseDate == "1999-01-09")
    #expect(set.logoURL == nil)
    #expect(set.total == 0)
}

// MARK: - Step Equatable Tests

@Test func scanFlowStateStepSearchEquality() async throws {
    let step1: ScanFlowState.Step = .search
    let step2: ScanFlowState.Step = .search

    #expect(step1 == step2)
}

@Test func scanFlowStateStepSetSelectionEquality() async throws {
    let step1: ScanFlowState.Step = .setSelection(pokemonName: "Pikachu")
    let step2: ScanFlowState.Step = .setSelection(pokemonName: "Pikachu")
    let step3: ScanFlowState.Step = .setSelection(pokemonName: "Charizard")

    #expect(step1 == step2)
    #expect(step1 != step3)
}

@Test func scanFlowStateStepCardEntryEquality() async throws {
    let step1: ScanFlowState.Step = .cardEntry(pokemonName: "Pikachu", setName: "Base Set", setID: "base1")
    let step2: ScanFlowState.Step = .cardEntry(pokemonName: "Pikachu", setName: "Base Set", setID: "base1")
    let step3: ScanFlowState.Step = .cardEntry(pokemonName: "Charizard", setName: "Base Set", setID: "base1")

    #expect(step1 == step2)
    #expect(step1 != step3)
}

// MARK: - Integration Tests

@Test @MainActor func scanFlowStateCompleteFlowSimulation() async throws {
    let state = ScanFlowState()

    // Step 1: User searches for Pokemon
    state.searchQuery = "Pikachu"
    state.searchResults = [
        PokemonSearchResult(id: "1", name: "Pikachu", availableSets: [])
    ]

    // Step 2: User selects Pokemon
    state.selectedPokemon = "Pikachu"
    state.addToRecentSearches("Pikachu")
    state.currentStep = .setSelection(pokemonName: "Pikachu")

    #expect(state.recentSearches.contains("Pikachu"))

    // Step 3: User selects set
    let set = CardSet(id: "base1", name: "Base Set", releaseDate: "1999-01-09")
    state.selectedSet = set
    state.currentStep = .cardEntry(pokemonName: "Pikachu", setName: "Base Set", setID: "base1")

    // Step 4: User enters card details
    state.cardNumber = "025"
    state.selectedVariant = .holo
    state.selectedCondition = .nearMint
    state.fetchedPrice = 25.0

    #expect(state.cardNumber == "025")
    #expect(state.selectedVariant == .holo)
    #expect(state.fetchedPrice == 25.0)

    // Step 5: User resets to search again
    state.resetFlow()

    #expect(state.currentStep == .search)
    #expect(state.cardNumber == "")
}

@Test func cardVariantPriceCalculation() async throws {
    let basePrice = 100.0

    let standardPrice = basePrice * CardVariant.standard.priceMultiplier
    let goldStarPrice = basePrice * CardVariant.goldStar.priceMultiplier

    #expect(standardPrice == 100.0)
    #expect(goldStarPrice == 1000.0)
}
