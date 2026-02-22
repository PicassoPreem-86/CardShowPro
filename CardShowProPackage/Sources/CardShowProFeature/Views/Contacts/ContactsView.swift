import SwiftData
import SwiftUI

/// Main contacts list view — a dedicated business rolodex for the card trading space
struct ContactsView: View {
    @Query(sort: \Contact.name) private var contacts: [Contact]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""
    @State private var selectedTypeFilter: ContactType?
    @State private var selectedTagFilter: String?
    @State private var showingAddSheet = false
    @State private var selectedContactID: UUID?

    /// All unique tags across all contacts
    private var allTags: [String] {
        var tagSet: Set<String> = []
        for contact in contacts {
            for tag in contact.tagsArray {
                tagSet.insert(tag)
            }
        }
        return tagSet.sorted()
    }

    /// Filtered contacts based on search text, type filter, and tag filter
    private var filteredContacts: [Contact] {
        var filtered = contacts

        // Apply type filter
        if let typeFilter = selectedTypeFilter {
            filtered = filtered.filter { $0.contactTypeEnum == typeFilter }
        }

        // Apply tag filter
        if let tagFilter = selectedTagFilter {
            filtered = filtered.filter { $0.hasTag(tagFilter) }
        }

        // Apply search
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { contact in
                contact.name.lowercased().contains(searchLower) ||
                contact.phone?.contains(searchText) == true ||
                contact.email?.lowercased().contains(searchLower) == true ||
                contact.socialMedia?.lowercased().contains(searchLower) == true ||
                contact.collectingInterests?.lowercased().contains(searchLower) == true ||
                contact.buyingPreferences?.lowercased().contains(searchLower) == true ||
                contact.specialties?.lowercased().contains(searchLower) == true ||
                contact.organization?.lowercased().contains(searchLower) == true ||
                contact.tags?.lowercased().contains(searchLower) == true
            }
        }

        return filtered
    }

    /// Count of contacts for a given type
    private func count(for type: ContactType) -> Int {
        contacts.filter { $0.contactTypeEnum == type }.count
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main Content
            Group {
                if contacts.isEmpty && searchText.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        // Type filter chips
                        typeFilterBar
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.xs)

                        // Tag filter pills
                        if !allTags.isEmpty {
                            tagFilterBar
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.top, DesignSystem.Spacing.xxxs)
                        }

                        Spacer().frame(height: DesignSystem.Spacing.xs)

                        if filteredContacts.isEmpty {
                            noResultsView
                        } else {
                            contactsList
                        }
                    }
                }
            }

            // Floating Action Button
            fabButton
        }
        .navigationTitle("Contacts")
        .searchable(text: $searchText, prompt: "Search contacts")
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationDestination(item: $selectedContactID) { contactID in
            ContactDetailView(contactID: contactID)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditContactView()
        }
    }

    // MARK: - Type Filter Bar

    @ViewBuilder
    private var typeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                // "All" chip
                FilterChip(
                    label: "All",
                    count: contacts.count,
                    isSelected: selectedTypeFilter == nil,
                    color: DesignSystem.Colors.textPrimary
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTypeFilter = nil
                    }
                }

                ForEach(ContactType.allCases) { type in
                    let typeCount = count(for: type)
                    if typeCount > 0 {
                        FilterChip(
                            label: type.label,
                            count: typeCount,
                            isSelected: selectedTypeFilter == type,
                            color: type.color
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTypeFilter = selectedTypeFilter == type ? nil : type
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tag Filter Bar

    @ViewBuilder
    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                ForEach(allTags, id: \.self) { tag in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTagFilter = selectedTagFilter == tag ? nil : tag
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 9))
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(selectedTagFilter == tag ? .white : DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            selectedTagFilter == tag
                                ? DesignSystem.Colors.electricBlue
                                : DesignSystem.Colors.backgroundTertiary
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    selectedTagFilter == tag ? Color.clear : DesignSystem.Colors.borderPrimary,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Contacts List

    @ViewBuilder
    private var contactsList: some View {
        List {
            ForEach(filteredContacts) { contact in
                Button {
                    selectedContactID = contact.id
                } label: {
                    ContactRowView(contact: contact)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                deleteContacts(at: indexSet)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - No Results

    @ViewBuilder
    private var noResultsView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No results")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if selectedTypeFilter != nil && !searchText.isEmpty {
                    Text("Try a different search or filter")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else if let filter = selectedTypeFilter {
                    Text("No \(filter.label.lowercased()) contacts yet")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else {
                    Text("Try a different search term")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Your Business Rolodex")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Keep track of customers, vendors, and event directors you meet in the card business — separate from your personal contacts.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Contact")
                }
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.thunderYellow)
                .clipShape(Capsule())
            }
            .padding(.top, DesignSystem.Spacing.sm)

            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }

    // MARK: - FAB Button

    @ViewBuilder
    private var fabButton: some View {
        if !contacts.isEmpty {
            Button {
                showingAddSheet = true
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
        }
    }

    // MARK: - Actions

    private func deleteContacts(at offsets: IndexSet) {
        let contactsToDelete = offsets.map { filteredContacts[$0] }
        for contact in contactsToDelete {
            modelContext.delete(contact)
        }
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Failed to save after deleting contacts: \(error)")
            #endif
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))

                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(
                        isSelected
                            ? Color.white.opacity(0.2)
                            : DesignSystem.Colors.backgroundTertiary
                    )
                    .clipShape(Capsule())
            }
            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? color
                    : DesignSystem.Colors.cardBackground
            )
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

// MARK: - Previews

#Preview("Contacts") {
    NavigationStack {
        ContactsView()
    }
    .modelContainer(for: Contact.self, inMemory: true)
}
