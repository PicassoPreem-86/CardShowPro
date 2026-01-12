import SwiftUI

/// Step 2 of the card entry flow - Select a set for the chosen Pokemon
struct SetSelectionView: View {
    let pokemonName: String
    @Bindable var state: ScanFlowState

    @State private var service = PokemonTCGService.shared
    @State private var filteredSets: [CardSet] = []
    @State private var searchQuery = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Content
                if isLoading {
                    loadingState
                } else if let error = errorMessage {
                    errorState(error)
                } else if filteredSets.isEmpty && !searchQuery.isEmpty {
                    emptySearchState
                } else if filteredSets.isEmpty {
                    emptyState
                } else {
                    setGrid
                }
            }
        }
        .navigationTitle(pokemonName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadSets()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .font(DesignSystem.Typography.body)

            // Search field
            TextField("Search sets...", text: $searchQuery)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .tint(DesignSystem.Colors.electricBlue)
                .autocorrectionDisabled()
                .onChange(of: searchQuery) { oldValue, newValue in
                    filterSets()
                }
                .accessibilityLabel("Filter sets")

            // Clear button
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    filterSets()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .font(DesignSystem.Typography.body)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    // MARK: - Set Grid

    private var setGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
                ],
                spacing: DesignSystem.Spacing.sm
            ) {
                ForEach(filteredSets) { set in
                    SetCard(set: set) {
                        selectSet(set)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xl)
            .animation(.spring(response: 0.3), value: filteredSets.count)
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .tint(DesignSystem.Colors.electricBlue)
                .scaleEffect(1.5)

            Text("Loading sets...")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No sets found for \(pokemonName)")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Try searching for a different Pokemon")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty Search State

    private var emptySearchState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No sets match \"\(searchQuery)\"")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Try a different search term")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.error)

            Text("Error Loading Sets")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await loadSets()
                }
            } label: {
                Text("Try Again")
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.thunderYellow)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
            .padding(.top, DesignSystem.Spacing.sm)
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadSets() async {
        isLoading = true
        errorMessage = nil

        do {
            let sets = try await service.getSetsForPokemon(pokemonName)
            state.availableSets = sets
            filteredSets = sets
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func filterSets() {
        if searchQuery.isEmpty {
            filteredSets = state.availableSets
        } else {
            filteredSets = state.availableSets.filter { set in
                set.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    private func selectSet(_ set: CardSet) {
        // Haptic feedback
        HapticManager.shared.medium()

        // Navigate to card entry with animation
        withAnimation(.spring(response: 0.3)) {
            state.selectedSet = set
            state.currentStep = .cardEntry(
                pokemonName: pokemonName,
                setName: set.name,
                setID: set.id
            )
        }
    }
}

// MARK: - Set Card Component

private struct SetCard: View {
    let set: CardSet
    let onTap: () -> Void

    @State private var isPressed = false

    private var accessibilityText: String {
        var parts: [String] = [set.name]
        if !set.releaseDate.isEmpty {
            parts.append("released \(set.releaseDate)")
        }
        if set.total > 0 {
            parts.append("\(set.total) cards")
        }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Set logo
                if let logoURL = set.logoURL {
                    AsyncImage(url: logoURL) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 60)
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }

                // Set name
                Text(set.name)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Set info
                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    if !set.releaseDate.isEmpty {
                        Text(set.releaseDate)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }

                    if !set.releaseDate.isEmpty && set.total > 0 {
                        Text("•")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }

                    if set.total > 0 {
                        Text("\(set.total) cards")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        isPressed ? DesignSystem.Colors.electricBlue : DesignSystem.Colors.borderPrimary,
                        lineWidth: isPressed ? 2 : 1
                    )
            )
            .shadow(
                color: DesignSystem.Shadows.level2.color,
                radius: DesignSystem.Shadows.level2.radius,
                x: DesignSystem.Shadows.level2.x,
                y: DesignSystem.Shadows.level2.y
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.backgroundTertiary)
                .frame(height: 60)

            Image(systemName: "photo")
                .font(.system(size: 30))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
    }
}

// MARK: - Previews

#Preview("With Sets") {
    NavigationStack {
        SetSelectionView(
            pokemonName: "Pikachu",
            state: {
                let state = ScanFlowState()
                state.availableSets = [
                    CardSet(
                        id: "base1",
                        name: "Base Set",
                        releaseDate: "1999-01-09",
                        logoURL: nil,
                        total: 102
                    ),
                    CardSet(
                        id: "xy1",
                        name: "XY",
                        releaseDate: "2014-02-05",
                        logoURL: nil,
                        total: 146
                    ),
                    CardSet(
                        id: "swsh1",
                        name: "Sword & Shield",
                        releaseDate: "2020-02-07",
                        logoURL: nil,
                        total: 202
                    ),
                    CardSet(
                        id: "base2",
                        name: "Jungle",
                        releaseDate: "1999-06-16",
                        logoURL: nil,
                        total: 64
                    )
                ]
                return state
            }()
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    NavigationStack {
        SetSelectionView(
            pokemonName: "Pikachu",
            state: ScanFlowState()
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Loading State") {
    NavigationStack {
        SetSelectionView(
            pokemonName: "Pikachu",
            state: {
                let state = ScanFlowState()
                return state
            }()
        )
    }
    .preferredColorScheme(.dark)
}
