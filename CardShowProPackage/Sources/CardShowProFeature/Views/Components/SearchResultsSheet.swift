import SwiftUI

/// Sheet displayed when searching for cards by name
/// Shows all matching cards in a scrollable grid for easy browsing
struct SearchResultsSheet: View {
    let searchQuery: String
    let results: [LocalCardMatch]
    let onSelect: (LocalCardMatch) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var filterText = ""

    /// Filter results by set name or card number
    private var filteredResults: [LocalCardMatch] {
        if filterText.isEmpty {
            return results
        }
        return results.filter {
            $0.setName.localizedCaseInsensitiveContains(filterText) ||
            $0.cardNumber.localizedCaseInsensitiveContains(filterText)
        }
    }

    /// Group results by set for better organization
    private var groupedResults: [(setName: String, cards: [LocalCardMatch])] {
        let grouped = Dictionary(grouping: filteredResults) { $0.setName }
        return grouped.map { (setName: $0.key, cards: $0.value.sorted { $0.cardNumber < $1.cardNumber }) }
            .sorted { $0.setName > $1.setName }  // Newest sets first (reverse alphabetical usually works)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Found \(results.count) Cards")
                                .font(.title3)
                                .fontWeight(.bold)

                            Text("Showing results for \"\(searchQuery)\"")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Filter field
                    if results.count > 10 {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundStyle(.secondary)
                            TextField("Filter by set or number...", text: $filterText)
                                .textFieldStyle(.plain)

                            if !filterText.isEmpty {
                                Button {
                                    filterText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 12)
                .background(Color(.systemBackground))

                Divider()

                // Results
                if filteredResults.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24, pinnedViews: .sectionHeaders) {
                            ForEach(groupedResults, id: \.setName) { group in
                                Section {
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12)
                                    ], spacing: 16) {
                                        ForEach(group.cards, id: \.id) { card in
                                            CardResultTile(
                                                card: card,
                                                onTap: {
                                                    onSelect(card)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                } header: {
                                    HStack {
                                        Text(group.setName)
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer()

                                        Text("\(group.cards.count) card\(group.cards.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemBackground))
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Search Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No matching cards")
                .font(.headline)

            Text("Try adjusting your filter")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Tile for displaying a single card in the search results
private struct CardResultTile: View {
    let card: LocalCardMatch
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Card image
            AsyncImage(url: card.imageURLSmall.flatMap { URL(string: $0) }) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color(.systemGray6))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                case .failure:
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("No Image")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color(.systemGray6))
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Card info
            VStack(spacing: 4) {
                Text(card.cardName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    Text("#\(card.cardNumber)")
                        .font(.caption2)

                    if let rarity = card.rarity {
                        Text("•")
                            .font(.caption2)
                        Text(rarity)
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .onTapGesture(count: 2) {
            onTap()
        }
    }
}

// MARK: - Preview

#Preview {
    SearchResultsSheet(
        searchQuery: "Pikachu",
        results: [
            LocalCardMatch(
                id: "swsh1-56",
                cardName: "Pikachu",
                setName: "Sword & Shield",
                setID: "swsh1",
                cardNumber: "056",
                imageURLSmall: nil,
                rarity: "Common",
                language: .english,
                source: .pokemontcg
            ),
            LocalCardMatch(
                id: "base1-58",
                cardName: "Pikachu",
                setName: "Base Set",
                setID: "base1",
                cardNumber: "058",
                imageURLSmall: nil,
                rarity: "Common",
                language: .english,
                source: .pokemontcg
            )
        ],
        onSelect: { card in
            print("Selected: \(card.cardName)")
        }
    )
}
