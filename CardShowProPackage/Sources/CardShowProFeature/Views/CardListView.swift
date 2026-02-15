import SwiftUI
import SwiftData

public struct CardListView: View {
    @Query(sort: \InventoryCard.acquiredDate, order: .reverse) private var inventoryCards: [InventoryCard]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCategory: CardCategory = .allProduct
    @State private var showAddItemSheet = false
    @State private var viewMode: ViewMode = .list
    @State private var isSelectionMode = false
    @State private var selectedCards: Set<InventoryCard.ID> = []
    @State private var showBulkDeleteAlert = false
    @State private var sortOption: SortOption = .acquiredDate
    @State private var profitFilter: ProfitFilter = .all
    @State private var showSortSheet = false
    @State private var showFilterSheet = false
    @State private var navigateToScan = false

    enum ViewMode {
        case list
        case grid
    }

    enum SortOption: String, CaseIterable {
        case acquiredDate = "Date Added"
        case cardName = "Name"
        case marketValue = "Market Value"
        case profit = "Profit"
        case roi = "ROI %"
        case purchaseCost = "Purchase Cost"
    }

    enum ProfitFilter: String, CaseIterable {
        case all = "All Cards"
        case profitable = "Profitable Only"
        case unprofitable = "Unprofitable Only"
        case noCost = "No Purchase Cost"
        case highROI = "ROI > 100%"
        case mediumROI = "ROI 50-100%"
        case lowROI = "ROI < 50%"
    }

    // Mock category assignment - will be real field in model later
    private func mockCategory(for card: InventoryCard) -> CardCategory {
        if card.confidence > 0.9 {
            return .graded
        } else if card.cardName.contains("Box") || card.cardName.contains("Pack") {
            return .sealed
        } else if card.marketValue > 200 {
            return .rawSingles
        } else if card.marketValue < 50 {
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

        // Apply profit filter
        switch profitFilter {
        case .all:
            break
        case .profitable:
            cards = cards.filter { $0.profit > 0 }
        case .unprofitable:
            cards = cards.filter { $0.profit < 0 }
        case .noCost:
            cards = cards.filter { $0.purchaseCost == nil }
        case .highROI:
            cards = cards.filter { $0.roi > 100 }
        case .mediumROI:
            cards = cards.filter { $0.roi >= 50 && $0.roi <= 100 }
        case .lowROI:
            cards = cards.filter { $0.roi < 50 && $0.purchaseCost != nil }
        }

        // Apply sorting
        switch sortOption {
        case .acquiredDate:
            cards.sort { $0.acquiredDate > $1.acquiredDate }
        case .cardName:
            cards.sort { $0.cardName.localizedCaseInsensitiveCompare($1.cardName) == .orderedAscending }
        case .marketValue:
            cards.sort { $0.marketValue > $1.marketValue }
        case .profit:
            cards.sort { $0.profit > $1.profit }
        case .roi:
            cards.sort { $0.roi > $1.roi }
        case .purchaseCost:
            cards.sort { ($0.purchaseCost ?? 0) > ($1.purchaseCost ?? 0) }
        }

        return cards
    }

    var totalValue: Double {
        filteredCards.reduce(0) { $0 + $1.marketValue }
    }

    var totalInvested: Double {
        filteredCards.reduce(0) { $0 + ($1.purchaseCost ?? 0) }
    }

    var totalProfit: Double {
        filteredCards.reduce(0) { $0 + $1.profit }
    }

    var averageROI: Double {
        let cardsWithCost = filteredCards.filter { $0.purchaseCost != nil }
        guard !cardsWithCost.isEmpty else { return 0 }
        return cardsWithCost.reduce(0) { $0 + $1.roi } / Double(cardsWithCost.count)
    }

    var emptyStateMessage: String {
        if profitFilter == .noCost {
            return "No cards without purchase cost tracking"
        } else if profitFilter != .all {
            return "No cards match the selected profit filter"
        } else if selectedCategory == .allProduct {
            return "Start scanning or manually add cards to build your collection. Add purchase costs to track profit!"
        } else {
            return "No \(selectedCategory.rawValue.lowercased()) in your collection yet"
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Nebula background layer
                NebulaBackgroundView()

                // Content layer
                VStack(spacing: 0) {
                // Stats Header (when not searching)
                if searchText.isEmpty {
                    InventoryStatsHeader(
                        cardCount: filteredCards.count,
                        totalValue: totalValue,
                        totalInvested: totalInvested,
                        totalProfit: totalProfit,
                        averageROI: averageROI
                    )
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
                    InventoryEmptyState(
                        category: selectedCategory,
                        message: emptyStateMessage,
                        onScanTap: { navigateToScan = true },
                        onAddManualTap: { showAddItemSheet = true }
                    )
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
                        // Sort and Filter (hide in selection mode)
                        if !isSelectionMode {
                            // Sort Button
                            Button {
                                showSortSheet = true
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundStyle(.cyan)
                            }

                            // Filter Button
                            Button {
                                showFilterSheet = true
                            } label: {
                                Image(systemName: profitFilter == .all ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                                    .foregroundStyle(.cyan)
                            }

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
            }
            .sheet(isPresented: $showAddItemSheet) {
                AddEditItemView(cardToEdit: nil)
            }
            .sheet(isPresented: $showSortSheet) {
                SortOptionsSheet(selectedOption: $sortOption)
                    .presentationDetents([.height(400)])
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterOptionsSheet(selectedFilter: $profitFilter)
                    .presentationDetents([.height(450)])
            }
            .navigationDestination(isPresented: $navigateToScan) {
                ScanView(showBackButton: true)
                    .navigationBarHidden(true)
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
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Failed to save after bulk delete: \(error)")
            #endif
        }
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
                            do {
                                try modelContext.save()
                            } catch {
                                #if DEBUG
                                print("Failed to save after swipe delete: \(error)")
                                #endif
                            }
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
