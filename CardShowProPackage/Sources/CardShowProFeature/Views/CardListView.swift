import SwiftUI
import SwiftData

struct CardListView: View {
    @Query(sort: \InventoryCard.timestamp, order: .reverse) private var inventoryCards: [InventoryCard]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var filterMode: FilterMode = .all

    enum FilterMode: String, CaseIterable {
        case all = "All Cards"
        case highValue = "High Value"
        case recent = "Recent"

        var icon: String {
            switch self {
            case .all: return "square.stack.3d.up.fill"
            case .highValue: return "dollarsign.circle.fill"
            case .recent: return "clock.fill"
            }
        }
    }

    var filteredCards: [InventoryCard] {
        var cards = inventoryCards

        // Apply filter
        switch filterMode {
        case .all:
            break
        case .highValue:
            cards = cards.filter { $0.estimatedValue > 100 }
        case .recent:
            // Already sorted by timestamp (most recent first)
            break
        }

        // Apply search
        if !searchText.isEmpty {
            cards = cards.filter { card in
                card.cardName.localizedCaseInsensitiveContains(searchText) ||
                card.setName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return cards
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(FilterMode.allCases, id: \.self) { mode in
                            FilterPill(
                                title: mode.rawValue,
                                icon: mode.icon,
                                isSelected: filterMode == mode
                            ) {
                                filterMode = mode
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemGroupedBackground))

                // Card List
                if filteredCards.isEmpty {
                    emptyState
                } else {
                    cardList
                }
            }
            .navigationTitle("Card Collection")
            .searchable(text: $searchText, prompt: "Search cards...")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Cards Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start scanning cards to build your collection")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }

    private var cardList: some View {
        List {
            ForEach(filteredCards) { card in
                InventoryCardRow(card: card)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            modelContext.delete(card)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct InventoryCardRow: View {
    let card: InventoryCard

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

                Text(card.setName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(card.cardNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Confidence Badge
                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .font(.caption2)
                        Text("\(Int(card.confidence * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                }
            }

            // Value
            VStack(alignment: .trailing) {
                Text("$\(String(format: "%.2f", card.estimatedValue))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
