import SwiftUI
import SwiftData

/// Full want list screen showing all items for a contact
struct WantListView: View {
    let contact: Contact

    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var editingItem: WantListItem?
    @State private var itemToDelete: WantListItem?
    @State private var showingDeleteAlert = false

    private var filteredItems: [WantListItem] {
        if searchText.isEmpty {
            return contact.wantListItems.sorted { $0.dateAdded > $1.dateAdded }
        } else {
            return contact.wantListItems
                .filter { item in
                    item.cardName.localizedCaseInsensitiveContains(searchText) ||
                    (item.setName?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
                .sorted { $0.dateAdded > $1.dateAdded }
        }
    }

    var body: some View {
        ZStack {
            if contact.wantListItems.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .navigationTitle("\(contact.name)'s Want List")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search want list...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddWantListItemView(contact: contact) { _ in
                // Item saved, sheet will dismiss automatically
            }
        }
        .sheet(item: $editingItem) { item in
            AddWantListItemView(contact: contact, existingItem: item) { _ in
                // Item updated, sheet will dismiss automatically
            }
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    deleteItem(item)
                }
            }
        } message: {
            if let item = itemToDelete {
                Text("Are you sure you want to delete '\(item.cardName)' from the want list?")
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No Want List Items")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Add items that \(contact.name) is looking for")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))

                    Text("Add First Item")
                        .font(DesignSystem.Typography.labelLarge)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.electricBlue)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundPrimary)
    }

    // MARK: - List Content

    @ViewBuilder
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                // Summary header
                summaryHeader

                // Search results info
                if !searchText.isEmpty {
                    searchResultsHeader
                }

                // Items list
                ForEach(filteredItems, id: \.id) { item in
                    WantListItemRow(
                        item: item,
                        onEdit: {
                            editingItem = item
                        },
                        onDelete: {
                            itemToDelete = item
                            showingDeleteAlert = true
                        }
                    )
                }

                // Empty search results
                if !searchText.isEmpty && filteredItems.isEmpty {
                    emptySearchResults
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
    }

    // MARK: - Summary Header

    @ViewBuilder
    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(contact.wantListItems.count)")
                        .font(DesignSystem.Typography.displaySmall)
                        .foregroundStyle(DesignSystem.Colors.thunderYellow)

                    Text(contact.wantListItems.count == 1 ? "Item" : "Items")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                // Priority breakdown
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Circle()
                            .fill(DesignSystem.Colors.thunderYellow)
                            .frame(width: 8, height: 8)
                        Text("\(priorityCount(.vip)) VIP")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Circle()
                            .fill(DesignSystem.Colors.warning)
                            .frame(width: 8, height: 8)
                        Text("\(priorityCount(.high)) High")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }

    // MARK: - Search Results Header

    @ViewBuilder
    private var searchResultsHeader: some View {
        HStack {
            Text("Found \(filteredItems.count) \(filteredItems.count == 1 ? "result" : "results")")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Button {
                searchText = ""
            } label: {
                Text("Clear")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.electricBlue)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
    }

    // MARK: - Empty Search Results

    @ViewBuilder
    private var emptySearchResults: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No Results")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("No items match '\(searchText)'")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxxl)
    }

    // MARK: - Actions

    private func deleteItem(_ item: WantListItem) {
        withAnimation {
            // Remove from contact's want list
            if let index = contact.wantListItems.firstIndex(where: { $0.id == item.id }) {
                contact.wantListItems.remove(at: index)
            }

            // Delete from model context
            modelContext.delete(item)
        }

        itemToDelete = nil
    }

    private func priorityCount(_ priority: ContactPriority) -> Int {
        contact.wantListItems.filter { $0.priorityEnum == priority }.count
    }
}

// MARK: - Previews

#Preview("Want List - Empty") {
    NavigationStack {
        WantListView(contact: Contact.mockContacts[2])
    }
}

#Preview("Want List - With Items") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Contact.self, WantListItem.self, configurations: config)

    let contact = Contact(
        name: "John Smith",
        phone: "555-0123",
        email: "john@example.com"
    )

    // Create want list items
    let items = [
        WantListItem(
            cardName: "Charizard",
            setName: "Base Set 1st Edition",
            condition: "PSA 10",
            maxPrice: 5000.00,
            priority: .vip,
            dateAdded: Date().addingTimeInterval(-86400 * 5)
        ),
        WantListItem(
            cardName: "Pikachu Illustrator",
            setName: "CoroCoro Comic Promo",
            condition: "Raw Near Mint",
            maxPrice: nil,
            priority: .vip,
            dateAdded: Date().addingTimeInterval(-86400 * 10)
        ),
        WantListItem(
            cardName: "Blastoise Holo",
            setName: "Base Set Shadowless",
            condition: nil,
            maxPrice: 150.00,
            priority: .high,
            dateAdded: Date().addingTimeInterval(-86400 * 2)
        ),
        WantListItem(
            cardName: "Venusaur",
            setName: "Base Set Unlimited",
            condition: "Lightly Played",
            maxPrice: 75.50,
            priority: .normal,
            dateAdded: Date().addingTimeInterval(-86400 * 15)
        ),
        WantListItem(
            cardName: "Alakazam Holo",
            setName: "Base Set",
            condition: "Near Mint",
            maxPrice: 50.00,
            priority: .low,
            dateAdded: Date().addingTimeInterval(-86400 * 20)
        )
    ]

    contact.wantListItems = items

    container.mainContext.insert(contact)
    for item in items {
        container.mainContext.insert(item)
    }

    return NavigationStack {
        WantListView(contact: contact)
            .modelContainer(container)
    }
}

#Preview("Want List - Search Results") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Contact.self, WantListItem.self, configurations: config)

    let contact = Contact(
        name: "Sarah Johnson",
        phone: "555-0456",
        email: "sarah@example.com"
    )

    let items = [
        WantListItem(
            cardName: "Charizard GX",
            setName: "Hidden Fates",
            maxPrice: 200.00,
            priority: .high
        ),
        WantListItem(
            cardName: "Pikachu VMAX",
            setName: "Vivid Voltage",
            maxPrice: 100.00,
            priority: .normal
        )
    ]

    contact.wantListItems = items

    container.mainContext.insert(contact)
    for item in items {
        container.mainContext.insert(item)
    }

    return NavigationStack {
        WantListView(contact: contact)
            .modelContainer(container)
    }
}
