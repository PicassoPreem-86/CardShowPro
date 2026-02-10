import Foundation

/// Service for performing card price lookups
/// Extracted from CardPriceLookupView to separate business logic from UI
@MainActor
struct PriceLookupService {
    private let pokemonService = PokemonTCGService.shared
    private let justTCGService = JustTCGService.shared
    private let localDatabase = LocalCardDatabase.shared

    // MARK: - Cache Key Generation

    func generateCacheKey(_ cardName: String, _ cardNumber: String?) -> String {
        let normalized = cardName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let number = cardNumber {
            return "\(normalized)_\(number)"
        }
        return normalized
    }

    // MARK: - Main Lookup

    func performLookup(
        state: PriceLookupState,
        cache: PriceCacheRepository,
        onShowMatches: @escaping () -> Void
    ) async {
        let startTime = Date()
        state.isLoading = true
        state.errorMessage = nil
        state.isFromCache = false
        state.cacheAgeHours = nil

        // Generate cache key for lookup
        let cacheKey = generateCacheKey(state.cardName, state.parsedCardNumber)

        do {
            // CACHE FIRST: Check cache before any search
            if let cachedPrice = try? cache.getPrice(cardID: cacheKey) {
                // Check if fresh (< 24 hours)
                if !cachedPrice.isStale {
                    let duration = Date().timeIntervalSince(startTime)
                    print("✅ CACHE HIT: \(cacheKey) (age: \(cachedPrice.ageInHours)h, duration: \(String(format: "%.2f", duration))s)")
                    displayCachedResult(cachedPrice, state: state)
                    state.isLoading = false
                    return
                } else {
                    print("⚠️ STALE CACHE: \(cacheKey) (age: \(cachedPrice.ageInHours)h) - Refreshing...")
                }
            }

            print("❌ CACHE MISS: \(cacheKey) - Searching local database...")

            // LOCAL DATABASE SEARCH FIRST (fast <50ms)
            // Ensure database is initialized
            if await !localDatabase.isReady {
                try await localDatabase.initialize()
            }

            let localSearchStart = CFAbsoluteTimeGetCurrent()
            let localMatches = try await localDatabase.search(
                name: state.cardName,
                number: state.parsedCardNumber,
                limit: 50
            )
            let localSearchTime = (CFAbsoluteTimeGetCurrent() - localSearchStart) * 1000
            print("🗄️ LOCAL DB: Found \(localMatches.count) matches in \(String(format: "%.1f", localSearchTime))ms")

            // Convert LocalCardMatch to CardMatch for UI
            let matches = localMatches.map { $0.toCardMatch() }

            guard !matches.isEmpty else {
                state.errorMessage = "No cards found matching '\(state.cardName)'"
                state.isLoading = false
                return
            }

            // If multiple matches, show selection sheet
            if matches.count > 1 {
                state.availableMatches = matches
                onShowMatches()
                state.isLoading = false
                return
            }

            // Single match - fetch pricing from API
            let match = matches[0]
            state.selectedMatch = match

            let (detailedPricing, tcgplayerId) = try await pokemonService.getDetailedPricing(cardID: match.id)
            state.tcgPlayerPrices = detailedPricing
            state.tcgplayerId = tcgplayerId

            // SAVE TO CACHE
            savePriceToCache(match: match, pricing: detailedPricing, cache: cache)

            let duration = Date().timeIntervalSince(startTime)
            print("⏱️ TOTAL LOOKUP: \(cacheKey) took \(String(format: "%.2f", duration))s (local: \(String(format: "%.0f", localSearchTime))ms)")

            state.addToRecentSearches(state.cardName)
            state.isLoading = false

            // Attempt to fetch JustTCG pricing in background
            if let fetchedTcgplayerId = tcgplayerId {
                print("🔗 Found TCGPlayer ID: \(fetchedTcgplayerId) - fetching JustTCG pricing")
                Task {
                    await fetchJustTCGPricing(tcgplayerId: fetchedTcgplayerId, cardID: match.id, state: state, cache: cache)
                }
            } else {
                print("⚠️ No TCGPlayer ID available - JustTCG pricing unavailable")
            }

        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("❌ LOOKUP FAILED: \(cacheKey) after \(String(format: "%.2f", duration))s - \(error)")
            state.errorMessage = errorMessage(for: error)
            state.isLoading = false
        }
    }

    // MARK: - Select Match

    func selectMatch(
        _ match: CardMatch,
        state: PriceLookupState,
        cache: PriceCacheRepository
    ) async {
        let startTime = Date()
        state.isLoading = true
        state.isFromCache = false
        state.cacheAgeHours = nil

        // CACHE FIRST: Check cache for this specific match
        if let cachedPrice = try? cache.getPrice(cardID: match.id), !cachedPrice.isStale {
            let duration = Date().timeIntervalSince(startTime)
            print("✅ CACHE HIT (selectMatch): \(match.id) (age: \(cachedPrice.ageInHours)h, duration: \(String(format: "%.2f", duration))s)")
            displayCachedResult(cachedPrice, state: state)
            state.isLoading = false
            return
        }

        // CACHE MISS OR STALE: Fetch from API
        do {
            let (detailedPricing, tcgplayerId) = try await pokemonService.getDetailedPricing(cardID: match.id)
            state.tcgPlayerPrices = detailedPricing
            state.tcgplayerId = tcgplayerId

            // SAVE TO CACHE
            savePriceToCache(match: match, pricing: detailedPricing, cache: cache)

            let duration = Date().timeIntervalSince(startTime)
            print("⏱️ API LOOKUP (selectMatch): \(match.id) took \(String(format: "%.2f", duration))s")

            state.addToRecentSearches(state.cardName)
            state.isLoading = false

            // Attempt to fetch JustTCG pricing in background
            if let fetchedTcgplayerId = tcgplayerId {
                print("🔗 Found TCGPlayer ID: \(fetchedTcgplayerId) - fetching JustTCG pricing")
                Task {
                    await fetchJustTCGPricing(tcgplayerId: fetchedTcgplayerId, cardID: match.id, state: state, cache: cache)
                }
            } else {
                print("⚠️ No TCGPlayer ID available - JustTCG pricing unavailable")
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("❌ LOOKUP FAILED (selectMatch): \(match.id) after \(String(format: "%.2f", duration))s")
            state.errorMessage = errorMessage(for: error)
            state.isLoading = false
        }
    }

    // MARK: - JustTCG Integration

    func fetchJustTCGPricing(tcgplayerId: String, cardID: String, state: PriceLookupState, cache: PriceCacheRepository) async {
        guard justTCGService.isConfigured else {
            print("⚠️ JustTCG API not configured - skipping condition pricing")
            return
        }

        do {
            print("🔍 Fetching JustTCG pricing for TCGPlayer ID: \(tcgplayerId)")
            let justTCGCard = try await justTCGService.getCardPricing(
                tcgplayerId: tcgplayerId,
                includePriceHistory: true
            )

            // Update lookup state with JustTCG data
            let conditionPrices = ConditionPrices(from: justTCGCard.bestAvailableConditionPrices())
            state.conditionPrices = conditionPrices
            print("📊 JustTCG available printings: \(justTCGCard.availablePrintings), primary: \(justTCGCard.primaryPrinting)")
            state.priceChange7d = justTCGCard.priceChange7d
            state.priceChange30d = justTCGCard.priceChange30d
            state.priceHistory = justTCGCard.nearMintPriceHistory
            state.tcgplayerId = tcgplayerId

            print("✅ JustTCG pricing loaded: \(conditionPrices.availableConditions.count) conditions")

            // Update cache with JustTCG data
            if var cachedPrice = try? cache.getPrice(cardID: cardID) {
                cachedPrice.setConditionPrices(conditionPrices)
                cachedPrice.priceChange7d = justTCGCard.priceChange7d
                cachedPrice.priceChange30d = justTCGCard.priceChange30d
                cachedPrice.tcgplayerId = tcgplayerId
                cachedPrice.justTCGLastUpdated = Date()
                if let history = justTCGCard.nearMintPriceHistory {
                    cachedPrice.setPriceHistory(history)
                }
                try? cache.savePrice(cachedPrice)
                print("💾 JustTCG data cached for: \(cardID)")
            }
        } catch {
            print("⚠️ JustTCG fetch failed: \(error.localizedDescription)")
            // Non-critical - we still have TCGPlayer pricing
        }
    }

    // MARK: - Cache Helpers

    func displayCachedResult(_ cachedPrice: CachedPrice, state: PriceLookupState) {
        // Reconstruct CardMatch from cache
        state.selectedMatch = CardMatch(
            id: cachedPrice.cardID,
            cardName: cachedPrice.cardName,
            setName: cachedPrice.setName,
            setID: cachedPrice.setID,
            cardNumber: cachedPrice.cardNumber,
            imageURL: cachedPrice.imageURLLarge.flatMap { URL(string: $0) }
        )

        // Reconstruct DetailedTCGPlayerPricing from cache
        var pricing = DetailedTCGPlayerPricing(
            normal: nil,
            holofoil: nil,
            reverseHolofoil: nil,
            firstEdition: nil,
            unlimited: nil
        )

        // Try to load full variant pricing from JSON first
        if let variantData = cachedPrice.variantPricesJSON,
           let variantPricing = try? JSONDecoder().decode(VariantPricing.self, from: variantData) {
            pricing = DetailedTCGPlayerPricing(
                normal: variantPricing.normal.map { DetailedTCGPlayerPricing.PriceBreakdown(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
                holofoil: variantPricing.holofoil.map { DetailedTCGPlayerPricing.PriceBreakdown(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
                reverseHolofoil: variantPricing.reverseHolofoil.map { DetailedTCGPlayerPricing.PriceBreakdown(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
                firstEdition: variantPricing.firstEdition.map { DetailedTCGPlayerPricing.PriceBreakdown(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
                unlimited: variantPricing.unlimited.map { DetailedTCGPlayerPricing.PriceBreakdown(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) }
            )
        } else if cachedPrice.marketPrice != nil || cachedPrice.lowPrice != nil {
            // Fallback: If we have basic pricing but no variant JSON, create a "Normal" variant
            pricing = DetailedTCGPlayerPricing(
                normal: DetailedTCGPlayerPricing.PriceBreakdown(
                    low: cachedPrice.lowPrice,
                    mid: cachedPrice.midPrice,
                    high: cachedPrice.highPrice,
                    market: cachedPrice.marketPrice
                ),
                holofoil: nil,
                reverseHolofoil: nil,
                firstEdition: nil,
                unlimited: nil
            )
        }

        state.tcgPlayerPrices = pricing
        state.isFromCache = true
        state.cacheAgeHours = cachedPrice.ageInHours
        state.addToRecentSearches(cachedPrice.cardName)

        // Load JustTCG condition pricing from cache
        state.conditionPrices = cachedPrice.conditionPrices
        state.priceChange7d = cachedPrice.priceChange7d
        state.priceChange30d = cachedPrice.priceChange30d
        state.priceHistory = cachedPrice.priceHistory
        state.tcgplayerId = cachedPrice.tcgplayerId
    }

    func savePriceToCache(match: CardMatch, pricing: DetailedTCGPlayerPricing, cache: PriceCacheRepository) {
        // Extract BEST AVAILABLE variant pricing (not just normal)
        let bestVariant = pricing.normal ?? pricing.holofoil ?? pricing.reverseHolofoil ?? pricing.firstEdition ?? pricing.unlimited

        let cachedPrice = CachedPrice(
            cardID: match.id,
            cardName: match.cardName,
            setName: match.setName,
            setID: match.setID,
            cardNumber: match.cardNumber,
            marketPrice: bestVariant?.market,
            lowPrice: bestVariant?.low,
            midPrice: bestVariant?.mid,
            highPrice: bestVariant?.high,
            imageURLSmall: match.imageURL?.absoluteString,
            imageURLLarge: match.imageURL?.absoluteString
        )

        // Store full variant pricing as JSON for complete reconstruction
        let variantPricing = VariantPricing(
            normal: pricing.normal.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
            holofoil: pricing.holofoil.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
            reverseHolofoil: pricing.reverseHolofoil.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
            firstEdition: pricing.firstEdition.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) },
            unlimited: pricing.unlimited.map { VariantPrice(low: $0.low, mid: $0.mid, high: $0.high, market: $0.market) }
        )
        cachedPrice.variantPricesJSON = try? JSONEncoder().encode(variantPricing)

        do {
            try cache.savePrice(cachedPrice)
            print("💾 CACHED: \(match.id) (variants: \(pricing.availableVariants.map { $0.name }.joined(separator: ", ")))")
        } catch {
            print("⚠️ Failed to cache price: \(error)")
        }
    }

    // MARK: - Inventory Entry Preparation

    func prepareInventoryEntry(state: PriceLookupState) -> (pokemonName: String, setName: String, setID: String, cardNumber: String, price: Double, imageURL: URL?)? {
        guard let match = state.selectedMatch,
              let pricing = state.tcgPlayerPrices,
              let normalVariant = pricing.availableVariants.first(where: { $0.name == "Normal" }),
              let marketPrice = normalVariant.pricing.market
        else { return nil }

        return (
            pokemonName: match.cardName,
            setName: match.setName,
            setID: match.setID,
            cardNumber: match.cardNumber,
            price: marketPrice,
            imageURL: match.imageURL
        )
    }

    // MARK: - Error Messages

    private func errorMessage(for error: Error) -> String {
        if error is DatabaseError {
            return "Card database error. Please try again or reinstall the app."
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection. Please check your WiFi or cellular data."
            case .timedOut:
                return "Request timed out. The server took too long to respond. Please try again."
            case .cannotFindHost, .cannotConnectToHost:
                return "Cannot reach pricing servers. Please try again later."
            case .networkConnectionLost:
                return "Network connection lost. Please check your connection and try again."
            default:
                return "Network error: \(urlError.localizedDescription)"
            }
        } else {
            return "Failed to lookup pricing. Please try again."
        }
    }
}
