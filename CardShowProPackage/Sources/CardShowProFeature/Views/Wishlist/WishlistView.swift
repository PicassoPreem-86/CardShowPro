import SwiftUI
import SwiftData

// MARK: - Wishlist Sort Option

private enum WishlistSortOption: String, CaseIterable {
    case priority = "Priority"
    case dateAdded = "Date Added"
    case maxPrice = "Max Price"
}

// MARK: - Wishlist View

struct WishlistView: View {
    @Query private var items: [WishlistItem]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selectedPriority: WishlistPriority?
    @State private var showingAddItem = false
    @State private var showFulfilledItems = false
    @State private var sortOption: WishlistSortOption = .priority
    @State private var editingItem: WishlistItem?

    // MARK: - Filtered & Sorted Items

    private var unfulfilledCount: Int {
        items.filter { !$0.isFulfilled }.count
    }

    private var filteredItems: [WishlistItem] {
        var result = items

        // Show/hide fulfilled
        if !showFulfilledItems {
            result = result.filter { !$0.isFulfilled }
        }

        // Filter by priority
        if let priority = selectedPriority {
            result = result.filter { $0.wishlistPriority == priority }
        }

        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { item in
                item.cardName.lowercased().contains(query) ||
                (item.setName?.lowercased().contains(query) == true)
            }
        }

        // Sort
        switch sortOption {
        case .priority:
            let order: [WishlistPriority] = [.high, .medium, .low]
            result.sort { a, b in
                let aIndex = order.firstIndex(of: a.wishlistPriority) ?? 1
                let bIndex = order.firstIndex(of: b.wishlistPriority) ?? 1
                if aIndex != bIndex { return aIndex < bIndex }
                return a.dateAdded > b.dateAdded
            }
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .maxPrice:
            result.sort { ($0.maxPrice ?? 0) > ($1.maxPrice ?? 0) }
        }

        return result
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Search bar
                    searchBar

                    // Priority filter pills
                    priorityFilterBar

                    // Sort & toggles
                    sortAndToggleBar

                    // Content
                    if filteredItems.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(filteredItems, id: \.id) { item in
                                WishlistItemRow(item: item, onFulfill: {
                                    markAsFulfilled(item)
                                }, onEdit: {
                                    editingItem = item
                                })
                                .contextMenu {
                                    if !item.isFulfilled {
                                        Button {
                                            markAsFulfilled(item)
                                        } label: {
                                            Label("Mark as Found", systemImage: "checkmark.circle")
                                        }
                                    }

                                    Button {
                                        editingItem = item
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        deleteItem(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)

            // FAB
            Button {
                showingAddItem = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                    .frame(width: 60, height: 60)
                    .background(DesignSystem.Colors.thunderYellow)
                    .clipShape(Circle())
                    .shadow(
                        color: DesignSystem.Shadows.level4.color,
                        radius: DesignSystem.Shadows.level4.radius,
                        x: DesignSystem.Shadows.level4.x,
                        y: DesignSystem.Shadows.level4.y
                    )
            }
            .padding(DesignSystem.Spacing.lg)
            .accessibilityLabel("Add wishlist item")
        }
        .navigationTitle("Wishlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if unfulfilledCount > 0 {
                    Text("\(unfulfilledCount)")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.thunderYellow)
                        .clipShape(Capsule())
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddWishlistItemView()
        }
        .sheet(item: $editingItem) { item in
            AddWishlistItemView(editingItem: item)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            TextField("Search wishlist...", text: $searchText)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }

    // MARK: - Priority Filter

    private var priorityFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                PriorityPill(label: "All", isSelected: selectedPriority == nil, color: DesignSystem.Colors.textPrimary) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPriority = nil
                    }
                }

                ForEach(WishlistPriority.allCases, id: \.self) { priority in
                    PriorityPill(
                        label: priority.displayName,
                        icon: priority.icon,
                        isSelected: selectedPriority == priority,
                        color: priority.color
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPriority = selectedPriority == priority ? nil : priority
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sort & Toggle

    private var sortAndToggleBar: some View {
        HStack {
            Menu {
                ForEach(WishlistSortOption.allCases, id: \.self) { option in
                    Button {
                        sortOption = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(sortOption.rawValue)
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            Button {
                withAnimation {
                    showFulfilledItems.toggle()
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    Image(systemName: showFulfilledItems ? "eye.fill" : "eye.slash")
                    Text(showFulfilledItems ? "Showing Found" : "Hiding Found")
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("Your wishlist is empty")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Add cards you're looking for!")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddItem = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Card")
                }
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.thunderYellow)
                .clipShape(Capsule())
            }
            .padding(.top, DesignSystem.Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Spacing.xxxl)
    }

    // MARK: - Actions

    private func markAsFulfilled(_ item: WishlistItem) {
        item.isFulfilled = true
        item.fulfilledDate = Date()
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Failed to save wishlist item: \(error)")
            #endif
        }
    }

    private func deleteItem(_ item: WishlistItem) {
        modelContext.delete(item)
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Failed to delete wishlist item: \(error)")
            #endif
        }
    }
}

// MARK: - Priority Pill

private struct PriorityPill: View {
    let label: String
    var icon: String?
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color : DesignSystem.Colors.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : DesignSystem.Colors.borderPrimary,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wishlist Item Row

private struct WishlistItemRow: View {
    let item: WishlistItem
    let onFulfill: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Priority icon
                Image(systemName: item.wishlistPriority.icon)
                    .font(.title3)
                    .foregroundStyle(item.isFulfilled ? DesignSystem.Colors.textTertiary : item.wishlistPriority.color)

                // Details
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(item.cardName)
                            .font(DesignSystem.Typography.labelLarge)
                            .foregroundStyle(item.isFulfilled ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                            .strikethrough(item.isFulfilled)

                        if item.isFulfilled {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(DesignSystem.Colors.success)
                        }
                    }

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        if let setName = item.setName, !setName.isEmpty {
                            Text(setName)
                                .font(DesignSystem.Typography.captionSmall)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                                .lineLimit(1)
                        }

                        if let variant = item.variantType {
                            Text(variant.displayName)
                                .font(DesignSystem.Typography.captionSmall)
                                .foregroundStyle(DesignSystem.Colors.electricBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.Colors.electricBlue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                // Max price
                if let maxPrice = item.maxPrice, maxPrice > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(maxPrice.asCurrency)
                            .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("max")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }

                // Swipe-to-fulfill indicator
                if !item.isFulfilled {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            .opacity(item.isFulfilled ? 0.7 : 1)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                // Handled by context menu delete
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !item.isFulfilled {
                Button {
                    onFulfill()
                } label: {
                    Label("Found", systemImage: "checkmark.circle")
                }
                .tint(DesignSystem.Colors.success)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.wishlistPriority.displayName) priority: \(item.cardName)")
        .accessibilityHint(item.isFulfilled ? "Already found" : "Tap to edit, swipe right to mark as found")
    }
}

#Preview("Wishlist") {
    NavigationStack {
        WishlistView()
    }
    .modelContainer(for: WishlistItem.self, inMemory: true)
}
