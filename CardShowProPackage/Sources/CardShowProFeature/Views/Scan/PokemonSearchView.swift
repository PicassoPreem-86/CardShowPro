import SwiftUI

/// Step 1 of card entry flow - Pokemon search with autocomplete
@MainActor
struct PokemonSearchView: View {
    @Bindable var state: ScanFlowState
    @State private var service = PokemonTCGService.shared
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearchFocused = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Search Bar
                searchBarSection

                // Content based on state
                if state.searchQuery.isEmpty {
                    // Empty state or popular Pokemon
                    if state.recentSearches.isEmpty {
                        emptyStateSection
                    } else {
                        recentSearchesSection
                    }
                    popularPokemonSection
                } else if state.isLoading {
                    // Loading state
                    loadingStateSection
                } else if state.searchResults.isEmpty {
                    // No results
                    noResultsSection
                } else {
                    // Search results
                    searchResultsSection
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Search Pokemon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    state.resetFlow()
                }
            }
        }
    }

    // MARK: - Search Bar Section

    private var searchBarSection: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            // Text field
            TextField("Search for a Pokemon...", text: $state.searchQuery)
                .font(DesignSystem.ComponentStyles.InputStyle.font)
                .foregroundStyle(DesignSystem.ComponentStyles.InputStyle.foregroundColor)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: state.searchQuery) { _, newValue in
                    performSearch(newValue)
                }
                .onAppear {
                    // Auto-focus on appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isSearchFocused = true
                    }
                }
                .accessibilityLabel("Search Pokemon")

            // Clear button
            if !state.searchQuery.isEmpty {
                Button {
                    HapticManager.shared.light()
                    withAnimation(DesignSystem.Animation.springSnappy) {
                        state.searchQuery = ""
                        state.searchResults = []
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(DesignSystem.ComponentStyles.InputStyle.padding)
        .background(DesignSystem.ComponentStyles.InputStyle.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.InputStyle.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.InputStyle.cornerRadius)
                .stroke(
                    isSearchFocused ? DesignSystem.ComponentStyles.InputStyle.focusedBorderColor : DesignSystem.ComponentStyles.InputStyle.borderColor,
                    lineWidth: DesignSystem.ComponentStyles.InputStyle.borderWidth
                )
        )
    }

    // MARK: - Empty State Section

    private var emptyStateSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.thunderYellow)

            Text("Start typing to search for Pokemon")
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }

    // MARK: - Recent Searches Section

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Recent Searches")
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(state.recentSearches, id: \.self) { pokemon in
                    recentSearchRow(pokemon)
                }
            }
        }
    }

    private func recentSearchRow(_ pokemon: String) -> some View {
        Button {
            HapticManager.shared.light()
            selectPokemon(pokemon)
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(pokemon)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Recent: \(pokemon)")
    }

    // MARK: - Popular Pokemon Section

    private var popularPokemonSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Popular Pokemon")
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                ForEach(service.getPopularPokemon(), id: \.self) { pokemon in
                    popularPokemonCard(pokemon)
                }
            }
        }
    }

    private func popularPokemonCard(_ pokemon: String) -> some View {
        Button {
            HapticManager.shared.medium()
            selectPokemon(pokemon)
        } label: {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "star.fill")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)

                Text(pokemon)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Popular: \(pokemon)")
    }

    // MARK: - Loading State Section

    private var loadingStateSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(0..<5, id: \.self) { _ in
                skeletonRow
            }
        }
    }

    private var skeletonRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Image placeholder
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.backgroundTertiary)
                .frame(width: 60, height: 84)
                .skeletonLoader(isLoading: true)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Name placeholder
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                    .fill(DesignSystem.Colors.backgroundTertiary)
                    .frame(height: 20)
                    .skeletonLoader(isLoading: true)

                // Sets placeholder
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                    .fill(DesignSystem.Colors.backgroundTertiary)
                    .frame(height: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .skeletonLoader(isLoading: true)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }

    // MARK: - No Results Section

    private var noResultsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text("No Pokemon found")
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Try a different search term")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(state.searchResults) { result in
                searchResultRow(result)
            }
        }
    }

    private func searchResultRow(_ result: PokemonSearchResult) -> some View {
        Button {
            HapticManager.shared.light()
            selectPokemon(result.name)
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Pokemon card image
                if let imageURL = result.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .fill(DesignSystem.Colors.backgroundTertiary)
                                .frame(width: 60, height: 84)
                                .overlay {
                                    ProgressView()
                                        .tint(DesignSystem.Colors.thunderYellow)
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 84)
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                        case .failure:
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .fill(DesignSystem.Colors.backgroundTertiary)
                                .frame(width: 60, height: 84)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Fallback icon
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.backgroundTertiary)
                        .frame(width: 60, height: 84)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                        }
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(result.name)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Tap to view sets")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(result.name), tap to select")
    }

    // MARK: - Helper Methods

    private func performSearch(_ query: String) {
        // Cancel previous search task
        searchTask?.cancel()

        // Debounce: wait 300ms before searching
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else { return }

            if query.isEmpty {
                state.searchResults = []
                state.isLoading = false
            } else {
                do {
                    state.isLoading = true
                    let results = try await service.searchPokemon(query)

                    guard !Task.isCancelled else { return }

                    withAnimation(DesignSystem.Animation.springSnappy) {
                        state.searchResults = results
                        state.isLoading = false
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    // Ignore cancellation errors (user is still typing)
                    if (error as? CancellationError) != nil {
                        return
                    }

                    // Only show real network errors
                    state.searchResults = []
                    state.isLoading = false
                    state.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func selectPokemon(_ name: String) {
        // Add to recent searches
        state.addToRecentSearches(name)

        // Navigate to set selection
        withAnimation(DesignSystem.Animation.springSmooth) {
            state.currentStep = .setSelection(pokemonName: name)
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    NavigationStack {
        PokemonSearchView(state: ScanFlowState())
    }
}

#Preview("With Recent Searches") {
    let state = ScanFlowState()
    state.recentSearches = ["Pikachu", "Charizard", "Mewtwo"]
    return NavigationStack {
        PokemonSearchView(state: state)
    }
}

#Preview("Loading State") {
    let state = ScanFlowState()
    state.searchQuery = "Pika"
    state.isLoading = true
    return NavigationStack {
        PokemonSearchView(state: state)
    }
}

#Preview("With Results") {
    let state = ScanFlowState()
    state.searchQuery = "Pika"
    state.searchResults = [
        PokemonSearchResult(id: "1", name: "Pikachu", imageURL: URL(string: "https://images.pokemontcg.io/base1/58.png")),
        PokemonSearchResult(id: "2", name: "Pikachu VMAX", imageURL: URL(string: "https://images.pokemontcg.io/swsh4/44.png")),
        PokemonSearchResult(id: "3", name: "Pikachu V", imageURL: URL(string: "https://images.pokemontcg.io/swsh4/43.png"))
    ]
    return NavigationStack {
        PokemonSearchView(state: state)
    }
}
