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
        VStack(spacing: 0) {
            // Top Row: Cards and Value
            HStack(spacing: 16) {
                // Total Cards
                InventoryStatBox(
                    label: "Cards",
                    value: "\(filteredCards.count)",
                    color: .white
                )

                // Total Value
                InventoryStatBox(
                    label: "Value",
                    value: "$\(String(format: "%.0f", totalValue))",
                    color: DesignSystem.Colors.cyan
                )

                // Total Invested
                InventoryStatBox(
                    label: "Invested",
                    value: "$\(String(format: "%.0f", totalInvested))",
                    color: DesignSystem.Colors.goldAmber
                )
            }
            .padding(.horizontal)
            .padding(.top, DesignSystem.Spacing.md)

            Divider()
                .padding(.vertical, DesignSystem.Spacing.xs)
                .padding(.horizontal)

            // Bottom Row: Profit Metrics
            HStack(spacing: 16) {
                // Total Profit
                InventoryStatBox(
                    label: "Profit",
                    value: "$\(String(format: "%.0f", totalProfit))",
                    color: totalProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error
                )

                // Average ROI
                InventoryStatBox(
                    label: "Avg ROI",
                    value: "\(String(format: "%.0f", averageROI))%",
                    color: averageROI >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error
                )

                // Profit Margin
                let profitMarginPercent = totalInvested > 0 ? (totalProfit / totalInvested * 100) : 0
                InventoryStatBox(
                    label: "Margin",
                    value: "\(String(format: "%.0f", profitMarginPercent))%",
                    color: profitMarginPercent >= 0 ? DesignSystem.Colors.electricBlue : DesignSystem.Colors.error
                )
            }
            .padding(.horizontal)
            .padding(.bottom, DesignSystem.Spacing.md)
        }
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
                    navigateToScan = true
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

            // Value and Profit Section
            VStack(alignment: .trailing, spacing: 6) {
                // Market Value
                Text("$\(String(format: "%.2f", card.marketValue))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)

                // Profit Badge (if purchase cost exists)
                if card.purchaseCost != nil {
                    ProfitBadge(profit: card.profit, roi: card.roi)
                } else {
                    // No purchase cost indicator
                    Text("No Cost")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.backgroundTertiary)
                        .clipShape(Capsule())
                }
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
            VStack(alignment: .leading, spacing: 6) {
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text("$\(String(format: "%.2f", card.marketValue))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.cyan)

                        // Profit display
                        if card.purchaseCost != nil {
                            HStack(spacing: 4) {
                                Image(systemName: card.profit >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption2)
                                Text("$\(String(format: "%.0f", abs(card.profit)))")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(card.profit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                        }
                    }

                    Spacer()

                    if card.purchaseCost != nil {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(String(format: "%.0f", card.roi))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(card.roi >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                            Text("ROI")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
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

// MARK: - Profit Badge Component
struct ProfitBadge: View {
    let profit: Double
    let roi: Double

    private var profitColor: Color {
        if profit > 0 {
            return DesignSystem.Colors.success
        } else if profit < 0 {
            return DesignSystem.Colors.error
        } else {
            return DesignSystem.Colors.textSecondary
        }
    }

    private var profitIcon: String {
        profit >= 0 ? "arrow.up.right" : "arrow.down.right"
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: profitIcon)
                .font(.caption2)
            Text("$\(String(format: "%.0f", abs(profit)))")
                .font(.caption)
                .fontWeight(.semibold)
            Text("(\(String(format: "%.0f", roi))%)")
                .font(.caption2)
        }
        .foregroundStyle(profitColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(profitColor.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Inventory Stat Box Component
struct InventoryStatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sort Options Sheet
struct SortOptionsSheet: View {
    @Binding var selectedOption: CardListView.SortOption
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(CardListView.SortOption.allCases, id: \.self) { option in
                    Button {
                        selectedOption = option
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.rawValue)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Spacer()
                            if selectedOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignSystem.Colors.cyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.cyan)
                }
            }
        }
    }
}

// MARK: - Filter Options Sheet
struct FilterOptionsSheet: View {
    @Binding var selectedFilter: CardListView.ProfitFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(CardListView.ProfitFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(filter.rawValue)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                if let description = filterDescription(for: filter) {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                                }
                            }
                            Spacer()
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignSystem.Colors.cyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.cyan)
                }
            }
        }
    }

    private func filterDescription(for filter: CardListView.ProfitFilter) -> String? {
        switch filter {
        case .all:
            return nil
        case .profitable:
            return "Cards with positive profit"
        case .unprofitable:
            return "Cards with negative profit"
        case .noCost:
            return "Cards without purchase cost"
        case .highROI:
            return "Return over 100%"
        case .mediumROI:
            return "Return 50-100%"
        case .lowROI:
            return "Return under 50%"
        }
    }
}
