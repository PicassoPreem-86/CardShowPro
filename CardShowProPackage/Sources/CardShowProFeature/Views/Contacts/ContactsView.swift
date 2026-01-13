import SwiftUI

/// Main contacts list view with search and FAB to add new contacts
struct ContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var state = ContactsState()
    @State private var showingAddSheet = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main Content
            VStack(spacing: 0) {
                // Filter Bar
                if !state.contacts.isEmpty {
                    ContactFilterBar(selectedFilter: $state.selectedFilter)
                        .background(DesignSystem.Colors.backgroundPrimary)
                }

                // Contacts List or Empty State
                if state.filteredContacts.isEmpty {
                    emptyStateView
                } else {
                    contactsList
                }
            }

            // Floating Action Button
            fabButton
        }
        .navigationTitle("Contacts")
        .searchable(text: $state.searchText, prompt: "Search contacts")
        .background(DesignSystem.Colors.backgroundPrimary)
        .sheet(isPresented: $showingAddSheet) {
            AddEditContactView { newContact in
                state.addContact(newContact)
            }
        }
    }

    // MARK: - Contacts List

    @ViewBuilder
    private var contactsList: some View {
        List {
            ForEach(state.filteredContacts) { contact in
                NavigationLink {
                    ContactDetailView(
                        contact: contact,
                        onUpdate: { updatedContact in
                            state.updateContact(updatedContact)
                        },
                        onDelete: {
                            state.deleteContact(contact)
                            dismiss()
                        }
                    )
                } label: {
                    ContactRowView(contact: contact)
                }
                .listRowInsets(EdgeInsets(top: 2, leading: DesignSystem.Spacing.sm, bottom: 2, trailing: DesignSystem.Spacing.sm))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        state.deleteContact(contact)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete { indexSet in
                state.deleteContacts(at: indexSet)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            // Spacer to prevent FAB from covering last contact
            Color.clear.frame(height: 76)  // FAB height (60) + padding (16)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: state.searchText.isEmpty ? "person.3" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(state.searchText.isEmpty ? "No contacts yet" : "No results")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(state.searchText.isEmpty ? "Add your first contact to get started" : "Try a different search term")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if state.searchText.isEmpty {
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
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }

    // MARK: - FAB Button

    @ViewBuilder
    private var fabButton: some View {
        if !state.filteredContacts.isEmpty || !state.searchText.isEmpty {
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

// MARK: - Previews

#Preview("With Contacts") {
    ContactsView()
}

#Preview("Empty State") {
    @Previewable @State var emptyState = ContactsState(contacts: [])
    NavigationStack {
        ZStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Spacer()

                Image(systemName: "person.3")
                    .font(.system(size: 60))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("No contacts yet")
                        .font(DesignSystem.Typography.heading3)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Add your first contact to get started")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    // Action
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
        .navigationTitle("Contacts")
        .background(DesignSystem.Colors.backgroundPrimary)
    }
}
