import SwiftUI
import SwiftData

struct CardListView: View {
    @Query(sort: \InventoryCard.timestamp, order: .reverse) private var inventoryCards: [InventoryCard]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCategory: CardCategory = .allProduct
    @State private var showAddItemSheet = false
    @State private var viewMode: ViewMode = .list

    enum ViewMode {
        case list
        case grid
    }

    // Mock category assignment - will be real field in model later
    private func mockCategory(for card: InventoryCard) -> CardCategory {
        if card.confidence > 0.9 {
            return .graded
        } else if card.cardName.contains("Box") || card.cardName.contains("Pack") {
            return .sealed
        } else if card.estimatedValue > 200 {
            return .rawSingles
        } else if card.estimatedValue < 50 {
            return .misc
        } else {
            return .rawSingles
        }
    }

    var filteredCards: [InventoryCard] {
        var cards = inventoryCards

        // Apply category filter
        if selectedCategory != .allProduct {
            cards = cards.filter { mockCategory(for: $0) == selectedCategory }
        }

        // Apply search
        if !searchText.isEmpty {
            cards = cards.filter { card in
                card.cardName.localizedCaseInsensitiveContains(searchText) ||
                card.setName.localizedCaseInsensitiveContains(searchText) ||
                card.cardNumber.localizedCaseInsensitiveContains(searchText)
            }
        }

        return cards
    }

    var totalValue: Double {
        filteredCards.reduce(0) { $0 + $1.estimatedValue }
    }

    var emptyStateMessage: String {
        if selectedCategory == .allProduct {
            return "Start scanning or manually add cards to build your collection"
        } else {
            return "No \(selectedCategory.rawValue.lowercased()) in your collection yet"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats Header (when not searching)
                if searchText.isEmpty {
                    statsHeader
                }

                // Category Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CardCategory.allCases, id: \.self) { category in
                            CategoryPill(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemGroupedBackground))

                // Card List or Grid
                if filteredCards.isEmpty {
                    emptyState
                } else {
                    if viewMode == .list {
                        cardListView
                    } else {
                        cardGridView
                    }
                }
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search cards...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // View Mode Toggle
                        Button {
                            withAnimation {
                                viewMode = viewMode == .list ? .grid : .list
                            }
                        } label: {
                            Image(systemName: viewMode == .list ? "square.grid.2x2.fill" : "list.bullet")
                                .foregroundStyle(.cyan)
                        }

                        // Add Button
                        Button {
                            showAddItemSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                                .foregroundStyle(.cyan)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddItemSheet) {
                AddEditItemView(cardToEdit: nil)
            }
        }
    }

    // MARK: - Stats Header
    private var statsHeader: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(filteredCards.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            Divider()
                .frame(height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("Total Value")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("$\(String(format: "%.2f", totalValue))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedCategory.icon)
                .font(.system(size: 60))
                .foregroundStyle(selectedCategory.color.opacity(0.5))

            Text("No Cards Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showAddItemSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Manually")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.cyan)
                .clipShape(Capsule())
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - List View
    private var cardListView: some View {
        List {
            ForEach(filteredCards) { card in
                NavigationLink {
                    CardDetailView(card: card)
                } label: {
                    InventoryCardRow(card: card, category: mockCategory(for: card))
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(card)
                        try? modelContext.save()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        // TODO: Edit action
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.cyan)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Grid View
    private var cardGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(filteredCards) { card in
                    NavigationLink {
                        CardDetailView(card: card)
                    } label: {
                        InventoryCardGridItem(card: card, category: mockCategory(for: card))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let category: CardCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? category.color : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Inventory Card Row (List View)
struct InventoryCardRow: View {
    let card: InventoryCard
    let category: CardCategory

    var body: some View {
        HStack(spacing: 16) {
            // Card Image
            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 80)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            // Card Info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.cardName)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(card.setName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    // Category Badge
                    HStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.caption2)
                        Text(category.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(category.color.opacity(0.15))
                    .foregroundStyle(category.color)
                    .clipShape(Capsule())

                    Text(card.cardNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            // Value
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", card.estimatedValue))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)

                // Confidence
                HStack(spacing: 2) {
                    Image(systemName: "sparkle")
                        .font(.caption2)
                    Text("\(Int(card.confidence * 100))%")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Inventory Card Grid Item
struct InventoryCardGridItem: View {
    let card: InventoryCard
    let category: CardCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Card Image
            ZStack(alignment: .topTrailing) {
                if let image = card.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 180)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }

                // Category Badge
                HStack(spacing: 4) {
                    Image(systemName: category.icon)
                        .font(.caption2)
                }
                .padding(8)
                .background(category.color)
                .foregroundStyle(.white)
                .clipShape(Circle())
                .padding(8)
            }

            // Card Info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.cardName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(card.setName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack {
                    Text("$\(String(format: "%.2f", card.estimatedValue))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.cyan)

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "sparkle")
                            .font(.caption2)
                        Text("\(Int(card.confidence * 100))%")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - CardCategory Extension for Identifiable
extension CardCategory: Identifiable {
    var id: String { rawValue }
}
