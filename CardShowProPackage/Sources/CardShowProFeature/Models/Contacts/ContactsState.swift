import Foundation
import Observation

/// Observable state container for Contacts Management feature
@Observable
@MainActor
final class ContactsState: Sendable {
    var contacts: [Contact]
    var searchText: String = ""

    init(contacts: [Contact] = Contact.mockContacts) {
        self.contacts = contacts
    }

    /// Filtered and sorted contacts based on search text
    var filteredContacts: [Contact] {
        let filtered: [Contact]
        if searchText.isEmpty {
            filtered = contacts
        } else {
            let searchLower = searchText.lowercased()
            filtered = contacts.filter { contact in
                contact.name.lowercased().contains(searchLower) ||
                contact.phone?.contains(searchText) == true ||
                contact.email?.lowercased().contains(searchLower) == true
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
        var updatedContact = contact
        updatedContact.lastContactedAt = Date()
        updateContact(updatedContact)
    }
}
