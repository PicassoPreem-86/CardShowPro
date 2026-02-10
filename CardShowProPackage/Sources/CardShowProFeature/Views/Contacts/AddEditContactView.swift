import SwiftUI

/// Form sheet for adding or editing a contact
struct AddEditContactView: View {
    @Environment(\.dismiss) private var dismiss
    let contact: Contact?
    let onSave: (Contact) -> Void

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var notes: String = ""

    private var isEditing: Bool {
        contact != nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(contact: Contact? = nil, onSave: @escaping (Contact) -> Void) {
        self.contact = contact
        self.onSave = onSave

        // Initialize state from contact if editing
        if let contact = contact {
            _name = State(initialValue: contact.name)
            _phone = State(initialValue: contact.phone ?? "")
            _email = State(initialValue: contact.email ?? "")
            _notes = State(initialValue: contact.notes ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Contact Information")
                }

                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Add any relevant information about this contact")
                }
            }
            .navigationTitle(isEditing ? "Edit Contact" : "New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveContact() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        let newContact = Contact(
            id: contact?.id ?? UUID(),
            name: trimmedName,
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
            email: trimmedEmail.isEmpty ? nil : trimmedEmail,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            createdAt: contact?.createdAt ?? Date(),
            lastContactedAt: contact?.lastContactedAt
        )

        onSave(newContact)
        dismiss()
    }
}

// MARK: - Previews

#Preview("Add Contact") {
    AddEditContactView { contact in
        print("Saved: \(contact.name)")
    }
}

#Preview("Edit Contact") {
    AddEditContactView(contact: Contact.mockContacts[0]) { contact in
        print("Updated: \(contact.name)")
    }
}
