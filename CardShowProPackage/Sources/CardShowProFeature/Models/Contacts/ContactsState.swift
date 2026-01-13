import Foundation
import Observation

/// Filter options for contacts list
enum ContactFilter: String, CaseIterable, Sendable {
    case all = "All"
    case customers = "Customers"
    case vendors = "Vendors"
    case suppliers = "Suppliers"
    case leads = "Leads"
    case vip = "VIP"
    case needsAttention = "Needs Attention"
}

/// Observable state container for Contacts Management feature
@Observable
@MainActor
final class ContactsState: Sendable {
    var contacts: [Contact]
    var searchText: String = ""
    var selectedFilter: ContactFilter = .all
    var selectedPriority: ContactPriority?

    init(contacts: [Contact] = Contact.mockContacts) {
        self.contacts = contacts
    }

    /// Filtered and sorted contacts based on search text, filter, and priority
    var filteredContacts: [Contact] {
        var filtered = contacts

        // Apply contact type filter
        switch selectedFilter {
        case .all:
            break // No filtering
        case .customers:
            filtered = filtered.filter { $0.contactTypeEnum == .customer }
        case .vendors:
            filtered = filtered.filter { $0.contactTypeEnum == .vendor }
        case .suppliers:
            filtered = filtered.filter { $0.contactTypeEnum == .supplier }
        case .leads:
            filtered = filtered.filter { $0.contactTypeEnum == .lead }
        case .vip:
            filtered = filtered.filter { $0.priorityEnum == .vip }
        case .needsAttention:
            // Contacts not contacted in last 30 days or never contacted
            let thirtyDaysAgo = Date().addingTimeInterval(-86400 * 30)
            filtered = filtered.filter { contact in
                if let lastContacted = contact.lastContactedAt {
                    return lastContacted < thirtyDaysAgo
                } else {
                    return true // Never contacted
                }
            }
        }

        // Apply priority filter if selected
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priorityEnum == priority }
        }

        // Apply search text filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { contact in
                contact.name.lowercased().contains(searchLower) ||
                contact.phone?.contains(searchText) == true ||
                contact.email?.lowercased().contains(searchLower) == true ||
                contact.tags.contains(where: { $0.lowercased().contains(searchLower) })
            }
        }

        // Sort by name alphabetically
        return filtered.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Add a new contact
    func addContact(_ contact: Contact) {
        contacts.append(contact)
    }

    /// Update an existing contact
    func updateContact(_ contact: Contact) {
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index] = contact
        }
    }

    /// Delete a contact
    func deleteContact(_ contact: Contact) {
        contacts.removeAll { $0.id == contact.id }
    }

    /// Delete contacts at specific indices
    func deleteContacts(at offsets: IndexSet) {
        let contactsToDelete = offsets.map { filteredContacts[$0] }
        for contact in contactsToDelete {
            deleteContact(contact)
        }
    }

    /// Update last contacted timestamp for a contact
    func markAsContacted(_ contact: Contact) {
        contact.lastContactedAt = Date()
    }

    /// Reset all filters to default
    func resetFilters() {
        searchText = ""
        selectedFilter = .all
        selectedPriority = nil
    }
}
