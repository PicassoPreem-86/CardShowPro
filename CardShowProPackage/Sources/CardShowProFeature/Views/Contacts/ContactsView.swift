import SwiftUI

/// Main contacts list view — a dedicated business rolodex for the card trading space
struct ContactsView: View {
    @State private var state = ContactsState()
    @State private var showingAddSheet = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                // Main Content
                Group {
                    if state.contacts.isEmpty && state.searchText.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: 0) {
                            // Type filter chips
                            typeFilterBar
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.xs)

                            if state.filteredContacts.isEmpty {
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
            .searchable(text: $state.searchText, prompt: "Search contacts")
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationDestination(for: Contact.self) { contact in
                ContactDetailView(
                    contact: contact,
                    onUpdate: { updatedContact in
                        state.updateContact(updatedContact)
                    },
                    onDelete: {
                        state.deleteContact(contact)
                        navigationPath.removeLast()
                    }
                )
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditContactView { newContact in
                    state.addContact(newContact)
                }
            }
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
                    count: state.contacts.count,
                    isSelected: state.selectedTypeFilter == nil,
                    color: DesignSystem.Colors.textPrimary
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        state.selectedTypeFilter = nil
                    }
                }

                ForEach(ContactType.allCases) { type in
                    let count = state.count(for: type)
                    if count > 0 {
                        FilterChip(
                            label: type.label,
                            count: count,
                            isSelected: state.selectedTypeFilter == type,
                            color: type.color
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                state.selectedTypeFilter = state.selectedTypeFilter == type ? nil : type
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Contacts List

    @ViewBuilder
    private var contactsList: some View {
        List {
            ForEach(state.filteredContacts) { contact in
                NavigationLink(value: contact) {
                    ContactRowView(contact: contact)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                state.deleteContacts(at: indexSet)
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

                if state.selectedTypeFilter != nil && !state.searchText.isEmpty {
                    Text("Try a different search or filter")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else if state.selectedTypeFilter != nil {
                    Text("No \(state.selectedTypeFilter!.label.lowercased()) contacts yet")
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
        if !state.contacts.isEmpty {
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

#Preview("With Contacts") {
    ContactsView()
}

#Preview("Empty State") {
    let _ = ContactsState(contacts: [])
    NavigationStack {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Your Business Rolodex")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Keep track of customers, vendors, and event directors you meet in the card business.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
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
        .navigationTitle("Contacts")
        .background(DesignSystem.Colors.backgroundPrimary)
    }
}
