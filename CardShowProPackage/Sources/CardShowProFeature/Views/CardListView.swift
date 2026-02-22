import SwiftUI
import SwiftData

public struct CardListView: View {
    @Query(sort: \InventoryCard.timestamp, order: .reverse) private var inventoryCards: [InventoryCard]
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
    @State private var selectedStatus: StatusFilter = .inStock
    @State private var showSortSheet = false
    @State private var showFilterSheet = false
    @State private var navigateToScan = false

    // Bulk operations state
    @State private var showBulkEditSheet = false
    @State private var showBulkStatusSheet = false
    @State private var showBulkListedSheet = false
    @State private var showBulkSoldSheet = false
    @State private var showBulkReturnAlert = false
    @State private var showExportShareSheet = false
    @State private var exportCSVContent = ""
    @State private var showCSVImportSheet = false

    // Swipe action state
    @State private var cardToSell: InventoryCard?
    @State private var cardToList: InventoryCard?
    @State private var cardToQuickPrice: InventoryCard?
    @State private var quickPriceValue: String = ""

    // Bulk listing/sold fields
    @State private var bulkListingPlatform = "eBay"
    @State private var bulkListingPrice = ""
    @State private var bulkSoldPlatform = "eBay"
    @State private var bulkSoldPrice = ""

    // Advanced filters
    @State private var advancedFilters = InventoryFilters()
    @State private var showAdvancedFilterSheet = false

    // Saved searches
    @State private var savedSearches: [SavedSearch] = SavedSearchStore.load()
    @State private var showSaveSearchAlert = false
    @State private var saveSearchName = ""

    // Duplicate detection
    @State private var showDuplicatesSheet = false

    enum StatusFilter: String, CaseIterable {
        case all = "All"
        case inStock = "In Stock"
        case listed = "Listed"
        case sold = "Sold"
    }

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
        case daysInInventory = "Days in Inventory"
        case condition = "Condition"
        case recentlyUpdated = "Recently Updated"
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

    var filteredCards: [InventoryCard] {
        var cards = inventoryCards

        // Apply status filter
        switch selectedStatus {
        case .all:
            break
        case .inStock:
            cards = cards.filter { $0.cardStatus == .inStock }
        case .listed:
            cards = cards.filter { $0.cardStatus == .listed }
        case .sold:
            cards = cards.filter { $0.cardStatus == .sold || $0.cardStatus == .shipped }
        }

        // Apply category filter
        if selectedCategory != .allProduct {
            cards = cards.filter { $0.cardCategory == selectedCategory }
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

        // Apply advanced filters
        if advancedFilters.hasActiveFilters {
            cards = applyAdvancedFilters(to: cards)
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
        case .daysInInventory:
            cards.sort { $0.daysInInventory > $1.daysInInventory }
        case .condition:
            let conditionOrder: [String] = CardCondition.allCases.map(\.rawValue)
            cards.sort { a, b in
                let aIdx = conditionOrder.firstIndex(of: a.condition) ?? conditionOrder.count
                let bIdx = conditionOrder.firstIndex(of: b.condition) ?? conditionOrder.count
                return aIdx < bIdx
            }
        case .recentlyUpdated:
            // Use the most recent of soldDate, listedDate, shippedDate, or timestamp
            cards.sort { a, b in
                let aDate = [a.soldDate, a.listedDate, a.shippedDate].compactMap { $0 }.max() ?? a.timestamp
                let bDate = [b.soldDate, b.listedDate, b.shippedDate].compactMap { $0 }.max() ?? b.timestamp
                return aDate > bDate
            }
        }

        return cards
    }

    private func applyAdvancedFilters(to cards: [InventoryCard]) -> [InventoryCard] {
        var result = cards

        if let minPrice = advancedFilters.minPrice {
            result = result.filter { $0.estimatedValue >= minPrice }
        }
        if let maxPrice = advancedFilters.maxPrice {
            result = result.filter { $0.estimatedValue <= maxPrice }
        }
        if let dateFrom = advancedFilters.dateFrom {
            result = result.filter { $0.timestamp >= dateFrom }
        }
        if let dateTo = advancedFilters.dateTo {
            result = result.filter { $0.timestamp <= dateTo }
        }
        if !advancedFilters.conditions.isEmpty {
            result = result.filter { advancedFilters.conditions.contains($0.condition) }
        }
        if !advancedFilters.variants.isEmpty {
            result = result.filter {
                guard let variant = $0.variant else { return false }
                return advancedFilters.variants.contains(variant)
            }
        }
        if !advancedFilters.gradingServices.isEmpty {
            result = result.filter {
                guard let gs = $0.gradingService else { return false }
                return advancedFilters.gradingServices.contains(gs)
            }
        }
        if !advancedFilters.acquisitionSources.isEmpty {
            result = result.filter {
                guard let source = $0.acquisitionSource else { return false }
                return advancedFilters.acquisitionSources.contains(source)
            }
        }

        return result
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

    private var selectedCardObjects: [InventoryCard] {
        filteredCards.filter { selectedCards.contains($0.id) }
    }

    private var isFiltered: Bool {
        !searchText.isEmpty || selectedCategory != .allProduct || profitFilter != .all || selectedStatus != .all || advancedFilters.hasActiveFilters
    }

    private var totalActiveFilterCount: Int {
        var count = advancedFilters.activeFilterCount
        if profitFilter != .all { count += 1 }
        if selectedStatus != .all { count += 1 }
        if selectedCategory != .allProduct { count += 1 }
        return count
    }

    /// Find groups of potential duplicate cards
    private var duplicateGroups: [[InventoryCard]] {
        var groups: [String: [InventoryCard]] = [:]
        for card in inventoryCards {
            let key = "\(card.cardName.lowercased())|\(card.setName.lowercased())|\(card.cardNumber.lowercased())"
            groups[key, default: []].append(card)
        }
        return groups.values.filter { $0.count > 1 }.sorted { $0[0].cardName < $1[0].cardName }
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

                // Filtered results summary
                if isFiltered && !filteredCards.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Showing \(filteredCards.count) of \(inventoryCards.count) cards")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Text("|")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                        Text("$\(String(format: "%.0f", totalValue)) value")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.cyan)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                }

                // Saved search pills
                if !savedSearches.isEmpty && !isSelectionMode {
                    savedSearchPills
                }

                // Status Filter Pills
                HStack(spacing: 0) {
                    ForEach(StatusFilter.allCases, id: \.self) { status in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedStatus = status
                            }
                        } label: {
                            Text(status.rawValue)
                                .font(DesignSystem.Typography.captionBold)
                                .padding(.horizontal, DesignSystem.Spacing.xs)
                                .padding(.vertical, DesignSystem.Spacing.xxs)
                                .frame(maxWidth: .infinity)
                                .background(
                                    selectedStatus == status
                                        ? DesignSystem.Colors.cyan
                                        : Color.clear
                                )
                                .foregroundStyle(
                                    selectedStatus == status
                                        ? DesignSystem.Colors.backgroundPrimary
                                        : DesignSystem.Colors.textSecondary
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                .padding(.horizontal)
                .padding(.top, DesignSystem.Spacing.xxs)

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

                // Selection mode quick-select buttons
                if isSelectionMode {
                    selectionModeHeader
                }

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
                            // Import Button
                            Button {
                                showCSVImportSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.down")
                                    .foregroundStyle(.cyan)
                            }

                            // Sort Button
                            Button {
                                showSortSheet = true
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundStyle(.cyan)
                            }

                            // Advanced Filter Button (with badge)
                            Button {
                                showAdvancedFilterSheet = true
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundStyle(.cyan)
                                    if advancedFilters.hasActiveFilters {
                                        Text("\(advancedFilters.activeFilterCount)")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(3)
                                            .background(DesignSystem.Colors.error)
                                            .clipShape(Circle())
                                            .offset(x: 6, y: -6)
                                    }
                                }
                            }

                            // Profit Filter Button
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
                            Menu {
                                Button {
                                    showAddItemSheet = true
                                } label: {
                                    Label("Add Card", systemImage: "plus")
                                }
                                Button {
                                    showCSVImportSheet = true
                                } label: {
                                    Label("Import CSV", systemImage: "square.and.arrow.down")
                                }
                                if isFiltered {
                                    Divider()
                                    Button {
                                        showSaveSearchAlert = true
                                    } label: {
                                        Label("Save Current Filters", systemImage: "bookmark")
                                    }
                                }
                                if !duplicateGroups.isEmpty {
                                    Divider()
                                    Button {
                                        showDuplicatesSheet = true
                                    } label: {
                                        Label("Find Duplicates (\(duplicateGroups.count))", systemImage: "doc.on.doc")
                                    }
                                }
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
                    .presentationDetents([.height(500)])
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterOptionsSheet(selectedFilter: $profitFilter)
                    .presentationDetents([.height(450)])
            }
            .sheet(isPresented: $showAdvancedFilterSheet) {
                AdvancedFilterView(filters: $advancedFilters)
            }
            .sheet(isPresented: $showBulkEditSheet) {
                BulkEditView(cards: selectedCardObjects)
            }
            .sheet(isPresented: $showCSVImportSheet) {
                CSVImportView()
            }
            .sheet(isPresented: $showBulkListedSheet) {
                bulkMarkAsListedSheet
            }
            .sheet(isPresented: $showBulkSoldSheet) {
                bulkMarkAsSoldSheet
            }
            .sheet(item: $cardToSell) { card in
                SellCardView(card: card)
            }
            .sheet(item: $cardToList) { card in
                MarkAsListedView(card: card)
            }
            .sheet(isPresented: $showExportShareSheet) {
                InventoryShareSheet(items: [exportCSVContent])
            }
            .sheet(isPresented: $showDuplicatesSheet) {
                DuplicateCardsView(groups: duplicateGroups)
            }
            .sheet(item: $cardToQuickPrice) { card in
                QuickPriceEditSheet(card: card)
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
            .alert("Return \(selectedCards.count) card(s) to stock?", isPresented: $showBulkReturnAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Return to Stock") {
                    performBulkReturnToStock()
                }
            } message: {
                Text("This will reset the selected cards to In Stock status.")
            }
            .alert("Save Search", isPresented: $showSaveSearchAlert) {
                TextField("Search name", text: $saveSearchName)
                Button("Cancel", role: .cancel) { saveSearchName = "" }
                Button("Save") {
                    saveCurrentSearch()
                }
            } message: {
                Text("Name this filter combination for quick access.")
            }
            .confirmationDialog("Change Status", isPresented: $showBulkStatusSheet) {
                Button("Mark All as Listed") {
                    bulkListingPrice = ""
                    showBulkListedSheet = true
                }
                Button("Mark All as Sold") {
                    bulkSoldPrice = ""
                    showBulkSoldSheet = true
                }
                Button("Return All to Stock") {
                    showBulkReturnAlert = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .overlay(alignment: .bottom) {
                if isSelectionMode && !selectedCards.isEmpty {
                    bulkActionBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Saved Search Pills

    private var savedSearchPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                ForEach(savedSearches) { search in
                    Button {
                        applySavedSearch(search)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bookmark.fill")
                                .font(.caption2)
                            Text(search.name)
                                .font(DesignSystem.Typography.captionBold)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(DesignSystem.Colors.electricBlue.opacity(0.15))
                        .foregroundStyle(DesignSystem.Colors.electricBlue)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteSavedSearch(search)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, DesignSystem.Spacing.xxs)
        }
    }

    // MARK: - Selection Mode Header

    private var selectionModeHeader: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Button {
                withAnimation {
                    selectedCards = Set(filteredCards.map(\.id))
                }
            } label: {
                Text("Select All Visible")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.cyan)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(DesignSystem.Colors.cyan.opacity(0.15))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if selectedCategory != .allProduct {
                Button {
                    withAnimation {
                        let categoryCards = filteredCards.filter { $0.cardCategory == selectedCategory }
                        selectedCards = Set(categoryCards.map(\.id))
                    }
                } label: {
                    Text("Select All \(selectedCategory.rawValue)")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(selectedCategory.color)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(selectedCategory.color.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, DesignSystem.Spacing.xxs)
    }

    // MARK: - Bulk Action Bar
    private var bulkActionBar: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Selected count
            Text("\(selectedCards.count) selected")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                // Select All / Deselect All
                Button {
                    withAnimation {
                        if selectedCards.count == filteredCards.count {
                            selectedCards.removeAll()
                        } else {
                            selectedCards = Set(filteredCards.map(\.id))
                        }
                    }
                } label: {
                    Text(selectedCards.count == filteredCards.count ? "Deselect" : "All")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }

                Spacer()

                // Edit
                Button {
                    showBulkEditSheet = true
                } label: {
                    bulkBarButton(icon: "pencil", label: "Edit", color: DesignSystem.Colors.electricBlue)
                }

                // Status
                Button {
                    showBulkStatusSheet = true
                } label: {
                    bulkBarButton(icon: "arrow.triangle.2.circlepath", label: "Status", color: DesignSystem.Colors.warning)
                }

                // Export
                Button {
                    exportSelectedCards()
                } label: {
                    bulkBarButton(icon: "square.and.arrow.up", label: "Export", color: DesignSystem.Colors.success)
                }

                // Delete
                Button {
                    showBulkDeleteAlert = true
                } label: {
                    bulkBarButton(icon: "trash.fill", label: "Delete", color: DesignSystem.Colors.error)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
    }

    private func bulkBarButton(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.body)
            Text(label)
                .font(DesignSystem.Typography.captionSmall)
        }
        .foregroundStyle(color)
        .frame(minWidth: 50)
    }

    // MARK: - Bulk Mark As Listed Sheet

    private var bulkMarkAsListedSheet: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("List \(selectedCards.count) card(s) for sale")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(.top, DesignSystem.Spacing.md)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("PLATFORM")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Picker("Platform", selection: $bulkListingPlatform) {
                        Text("eBay").tag("eBay")
                        Text("TCGPlayer").tag("TCGPlayer")
                        Text("Facebook").tag("Facebook Marketplace")
                        Text("Mercari").tag("Mercari")
                        Text("Local").tag("Local")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("LISTING PRICE (applied to all)")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    HStack {
                        Text("$")
                            .font(DesignSystem.Typography.heading3)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        TextField("Leave blank to use market value", text: $bulkListingPrice)
                            .font(DesignSystem.Typography.heading3.monospacedDigit())
                            .keyboardType(.decimalPad)
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                Spacer()

                Button {
                    performBulkMarkAsListed()
                    showBulkListedSheet = false
                } label: {
                    HStack {
                        Image(systemName: "tag.fill")
                        Text("Mark All as Listed")
                            .font(DesignSystem.Typography.heading4)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.electricBlue)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Bulk List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showBulkListedSheet = false }
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Bulk Mark As Sold Sheet

    private var bulkMarkAsSoldSheet: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Sell \(selectedCards.count) card(s)")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(.top, DesignSystem.Spacing.md)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("PLATFORM")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Picker("Platform", selection: $bulkSoldPlatform) {
                        Text("eBay").tag("eBay")
                        Text("TCGPlayer").tag("TCGPlayer")
                        Text("Facebook").tag("Facebook Marketplace")
                        Text("Local/Cash").tag("Local/Cash")
                        Text("Event").tag("Event")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("SALE PRICE (applied to all)")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    HStack {
                        Text("$")
                            .font(DesignSystem.Typography.heading3)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        TextField("Leave blank to use market value", text: $bulkSoldPrice)
                            .font(DesignSystem.Typography.heading3.monospacedDigit())
                            .keyboardType(.decimalPad)
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                Spacer()

                Button {
                    performBulkMarkAsSold()
                    showBulkSoldSheet = false
                } label: {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                        Text("Mark All as Sold")
                            .font(DesignSystem.Typography.heading4)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.success)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Bulk Sell")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showBulkSoldSheet = false }
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Bulk Actions

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

    private func performBulkMarkAsListed() {
        let cards = selectedCardObjects
        let price = Double(bulkListingPrice)

        for card in cards {
            card.status = CardStatus.listed.rawValue
            card.platform = bulkListingPlatform
            card.listingPrice = price ?? card.marketValue
            card.listedDate = Date()
        }

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            #if DEBUG
            print("Failed to save bulk listing: \(error)")
            #endif
        }
        selectedCards.removeAll()
        isSelectionMode = false
    }

    private func performBulkMarkAsSold() {
        let cards = selectedCardObjects
        let price = Double(bulkSoldPrice)

        for card in cards {
            let salePrice = price ?? card.marketValue

            // Create transaction for each card
            let transaction = Transaction.recordSale(
                card: card,
                salePrice: salePrice,
                platform: bulkSoldPlatform
            )
            modelContext.insert(transaction)

            card.status = CardStatus.sold.rawValue
            card.soldPrice = salePrice
            card.soldDate = Date()
            card.platform = bulkSoldPlatform
        }

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            #if DEBUG
            print("Failed to save bulk sold: \(error)")
            #endif
        }
        selectedCards.removeAll()
        isSelectionMode = false
    }

    private func performBulkReturnToStock() {
        let cards = selectedCardObjects

        for card in cards {
            card.status = CardStatus.inStock.rawValue
            card.soldPrice = nil
            card.soldDate = nil
            card.listingPrice = nil
            card.listedDate = nil
            card.platform = nil
        }

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            #if DEBUG
            print("Failed to save bulk return: \(error)")
            #endif
        }
        selectedCards.removeAll()
        isSelectionMode = false
    }

    private func exportSelectedCards() {
        let cards = selectedCardObjects
        exportCSVContent = DataExportService.exportSelectedInventoryCSV(cards: cards)
        showExportShareSheet = true
    }

    // MARK: - Saved Searches

    private func saveCurrentSearch() {
        let name = saveSearchName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let search = SavedSearch(
            name: name,
            status: selectedStatus.rawValue,
            category: selectedCategory.rawValue,
            profitFilter: profitFilter.rawValue,
            sortOption: sortOption.rawValue,
            advancedFilters: advancedFilters
        )

        savedSearches.append(search)
        SavedSearchStore.save(savedSearches)
        saveSearchName = ""
        HapticManager.shared.light()
    }

    private func applySavedSearch(_ search: SavedSearch) {
        if let status = StatusFilter(rawValue: search.status) {
            selectedStatus = status
        }
        if let category = CardCategory(rawValue: search.category) {
            selectedCategory = category
        }
        if let filter = ProfitFilter(rawValue: search.profitFilter) {
            profitFilter = filter
        }
        if let sort = SortOption(rawValue: search.sortOption) {
            sortOption = sort
        }
        advancedFilters = search.advancedFilters
        HapticManager.shared.light()
    }

    private func deleteSavedSearch(_ search: SavedSearch) {
        savedSearches.removeAll { $0.id == search.id }
        SavedSearchStore.save(savedSearches)
    }

    // MARK: - Refresh Inventory
    @MainActor
    private func refreshInventory() async {
        try? await Task.sleep(for: .milliseconds(500))
        HapticManager.shared.light()
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
                            Image(systemName: selectedCards.contains(card.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selectedCards.contains(card.id) ? DesignSystem.Colors.cyan : DesignSystem.Colors.textTertiary)

                            InventoryCardRow(card: card)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink {
                        CardDetailView(card: card)
                    } label: {
                        InventoryCardRow(card: card)
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
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        if card.cardStatus == .inStock || card.cardStatus == .listed {
                            Button {
                                cardToSell = card
                            } label: {
                                Label("Sell", systemImage: "dollarsign.circle.fill")
                            }
                            .tint(DesignSystem.Colors.success)
                        }

                        if card.cardStatus == .inStock {
                            Button {
                                cardToList = card
                            } label: {
                                Label("List", systemImage: "tag.fill")
                            }
                            .tint(DesignSystem.Colors.electricBlue)
                        }

                        Button {
                            cardToQuickPrice = card
                        } label: {
                            Label("Price", systemImage: "dollarsign.arrow.circlepath")
                        }
                        .tint(.orange)
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
                        InventoryCardGridItem(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color.clear)
    }
}

// MARK: - ShareSheet UIActivityViewController Wrapper

private struct InventoryShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Saved Search Model

struct SavedSearch: Identifiable, Codable {
    var id = UUID()
    var name: String
    var status: String
    var category: String
    var profitFilter: String
    var sortOption: String
    var advancedFilters: InventoryFilters
}

// MARK: - Saved Search Store (UserDefaults)

enum SavedSearchStore {
    private static let key = "com.cardshowpro.savedSearches"

    static func load() -> [SavedSearch] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([SavedSearch].self, from: data)) ?? []
    }

    static func save(_ searches: [SavedSearch]) {
        if let data = try? JSONEncoder().encode(searches) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Quick Price Edit Sheet

private struct QuickPriceEditSheet: View {
    let card: InventoryCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var priceText: String = ""
    @State private var showSaveError = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if let image = card.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.cardName)
                            .font(DesignSystem.Typography.heading4)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Current: $\(String(format: "%.2f", card.marketValue))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.md)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("NEW MARKET VALUE")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    HStack {
                        Text("$")
                            .font(DesignSystem.Typography.heading2)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        TextField("0.00", text: $priceText)
                            .font(DesignSystem.Typography.heading2.monospacedDigit())
                            .keyboardType(.decimalPad)
                            .focused($focused)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                Spacer()

                Button {
                    savePrice()
                } label: {
                    Text("Update Price")
                        .font(DesignSystem.Typography.heading4)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.sm)
                        .background((Double(priceText) ?? 0) > 0 ? DesignSystem.Colors.cyan : DesignSystem.Colors.cyan.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
                .disabled((Double(priceText) ?? 0) <= 0)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Quick Edit Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { focused = false }
                }
            }
            .onAppear {
                priceText = String(format: "%.2f", card.marketValue)
                focused = true
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("OK", role: .cancel) { }
            }
        }
        .presentationDetents([.height(350)])
    }

    private func savePrice() {
        guard let newPrice = Double(priceText), newPrice > 0 else { return }
        card.estimatedValue = newPrice
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            showSaveError = true
        }
    }
}

// MARK: - Duplicate Cards View

private struct DuplicateCardsView: View {
    let groups: [[InventoryCard]]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(DesignSystem.Colors.success)
                                Text("No duplicates found")
                                    .font(DesignSystem.Typography.heading4)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                            }
                            .padding(.vertical, DesignSystem.Spacing.lg)
                            Spacer()
                        }
                    }
                } else {
                    ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                        Section {
                            ForEach(group) { card in
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(card.cardName)
                                            .font(DesignSystem.Typography.labelLarge)
                                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                                        Text("\(card.setName) #\(card.cardNumber)")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("$\(String(format: "%.2f", card.marketValue))")
                                            .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                                            .foregroundStyle(DesignSystem.Colors.cyan)
                                        Text(card.status)
                                            .font(DesignSystem.Typography.captionSmall)
                                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundStyle(DesignSystem.Colors.warning)
                                Text("\(group.count) copies")
                                    .foregroundStyle(DesignSystem.Colors.warning)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Potential Duplicates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }
            }
        }
    }
}
