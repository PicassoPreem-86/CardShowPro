import SwiftUI
import SwiftData

struct CardListView: View {
    @Query(sort: \InventoryCard.timestamp, order: .reverse) private var inventoryCards: [InventoryCard]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCategory: CardCategory = .allProduct
    @State private var showAddItemSheet = false
    @State private var viewMode: ViewMode = .list
    @State private var isSelectionMode = false
    @State private var selectedCards: Set<InventoryCard.ID> = []
    @State private var showBulkDeleteAlert = false

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
            ZStack {
                // Nebula background layer
                NebulaBackgroundView()

                // Content layer
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
                .background(Color.clear)

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
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search cards...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !filteredCards.isEmpty {
                        Button(isSelectionMode ? "Cancel" : "Select") {
                            withAnimation {
                                isSelectionMode.toggle()
                                if !isSelectionMode {
                                    selectedCards.removeAll()
                                }
                            }
                        }
                        .foregroundStyle(DesignSystem.Colors.cyan)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // View Mode Toggle (hide in selection mode)
                        if !isSelectionMode {
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
            }
            .sheet(isPresented: $showAddItemSheet) {
                AddEditItemView(cardToEdit: nil)
            }
            .alert("Delete \(selectedCards.count) card(s)?", isPresented: $showBulkDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    performBulkDelete()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .overlay(alignment: .bottom) {
                if isSelectionMode && !selectedCards.isEmpty {
                    bulkActionBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Bulk Action Bar
    private var bulkActionBar: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Select All Button
            Button {
                withAnimation {
                    if selectedCards.count == filteredCards.count {
                        selectedCards.removeAll()
                    } else {
                        selectedCards = Set(filteredCards.map(\.id))
                    }
                }
            } label: {
                Text(selectedCards.count == filteredCards.count ? "Deselect All" : "Select All")
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.cyan)
            }

            Spacer()

            // Selected count
            Text("\(selectedCards.count) selected")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            // Delete Button
            Button {
                showBulkDeleteAlert = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                    Text("Delete")
                }
                .font(DesignSystem.Typography.labelLarge)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.error)
                .clipShape(Capsule())
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
    }

    // MARK: - Bulk Delete Action
    private func performBulkDelete() {
        let cardsToDelete = filteredCards.filter { selectedCards.contains($0.id) }
        for card in cardsToDelete {
            modelContext.delete(card)
        }
        try? modelContext.save()
        selectedCards.removeAll()
        isSelectionMode = false
    }

    // MARK: - Refresh Inventory
    @MainActor
    private func refreshInventory() async {
        // Brief delay for visual feedback
        try? await Task.sleep(for: .milliseconds(500))

        // Trigger haptic feedback
        HapticManager.shared.light()

        // In the future, this would refresh from network/API
        // For now, the @Query will automatically update from SwiftData
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
        .background(DesignSystem.Colors.cardBackground)
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Category icon with colored circle background
            ZStack {
                Circle()
                    .fill(selectedCategory.color.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: selectedCategory.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(selectedCategory.color)
            }
            .padding(.bottom, DesignSystem.Spacing.xs)

            Text("No Cards Found")
                .font(DesignSystem.Typography.heading2)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(emptyStateMessage)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)

            VStack(spacing: DesignSystem.Spacing.xs) {
                // Primary action - Scan Cards
                Button {
                    // Navigate to Scan tab (will be implemented via AppState)
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "camera.fill")
                        Text("Scan Cards")
                    }
                    .font(DesignSystem.Typography.labelLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .shadow(
                        color: DesignSystem.Shadows.level2.color,
                        radius: DesignSystem.Shadows.level2.radius,
                        x: DesignSystem.Shadows.level2.x,
                        y: DesignSystem.Shadows.level2.y
                    )
                }

                // Secondary action - Add Manually
                Button {
                    showAddItemSheet = true
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "plus.circle")
                        Text("Add Manually")
                    }
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.cyan)
                    .frame(maxWidth: 280)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.cyan.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - List View
    private var cardListView: some View {
        List {
            ForEach(filteredCards) { card in
                if isSelectionMode {
                    Button {
                        withAnimation {
                            if selectedCards.contains(card.id) {
                                selectedCards.remove(card.id)
                            } else {
                                selectedCards.insert(card.id)
                            }
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            // Checkmark circle
                            Image(systemName: selectedCards.contains(card.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selectedCards.contains(card.id) ? DesignSystem.Colors.cyan : DesignSystem.Colors.textTertiary)

                            InventoryCardRow(card: card, category: mockCategory(for: card))
                        }
                    }
                    .buttonStyle(.plain)
                } else {
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
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable {
            await refreshInventory()
        }
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
        .background(Color.clear)
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

                // Confidence with color coding
                HStack(spacing: 2) {
                    Image(systemName: confidenceIcon(for: card.confidence))
                        .font(.caption2)
                    Text("\(Int(card.confidence * 100))%")
                        .font(.caption2)
                }
                .foregroundStyle(confidenceColor(for: card.confidence))
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
                        Image(systemName: confidenceIcon(for: card.confidence))
                            .font(.caption2)
                        Text("\(Int(card.confidence * 100))%")
                            .font(.caption2)
                    }
                    .foregroundStyle(confidenceColor(for: card.confidence))
                }
            }
        }
        .padding(12)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - CardCategory Extension for Identifiable
extension CardCategory: Identifiable {
    var id: String { rawValue }
}

// MARK: - Confidence Helper Functions
private func confidenceColor(for confidence: Double) -> Color {
    switch confidence {
    case 0.9...1.0: return DesignSystem.Colors.success
    case 0.75..<0.9: return DesignSystem.Colors.electricBlue
    case 0.5..<0.75: return DesignSystem.Colors.warning
    default: return DesignSystem.Colors.error
    }
}

private func confidenceIcon(for confidence: Double) -> String {
    switch confidence {
    case 0.9...1.0: return "checkmark.seal.fill"
    case 0.75..<0.9: return "checkmark.circle.fill"
    case 0.5..<0.75: return "exclamationmark.triangle.fill"
    default: return "xmark.octagon.fill"
    }
}
