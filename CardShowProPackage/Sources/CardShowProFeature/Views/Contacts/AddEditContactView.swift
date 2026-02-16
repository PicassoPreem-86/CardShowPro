import SwiftData
import SwiftUI

/// Form sheet for adding or editing a contact
struct AddEditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// When editing, this is the existing Contact to update. Nil for new contacts.
    let contact: Contact?

    @State private var name: String = ""
    @State private var contactType: ContactType = .customer
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var socialMedia: String = ""
    @State private var notes: String = ""

    // Customer fields
    @State private var collectingInterests: String = ""
    @State private var spendingTier: SpendingTier = .casual
    @State private var preferredContactMethod: PreferredContactMethod = .noPreference

    // Buyer fields
    @State private var buyingPreferences: String = ""

    // Vendor fields
    @State private var specialties: String = ""

    // Event Director fields
    @State private var organization: String = ""
    @State private var eventName: String = ""
    @State private var venue: String = ""

    private var isEditing: Bool {
        contact != nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(contact: Contact? = nil) {
        self.contact = contact

        if let contact {
            _name = State(initialValue: contact.name)
            _contactType = State(initialValue: contact.contactTypeEnum)
            _phone = State(initialValue: contact.phone ?? "")
            _email = State(initialValue: contact.email ?? "")
            _socialMedia = State(initialValue: contact.socialMedia ?? "")
            _notes = State(initialValue: contact.notes ?? "")
            _collectingInterests = State(initialValue: contact.collectingInterests ?? "")
            _spendingTier = State(initialValue: contact.spendingTierEnum ?? .casual)
            _preferredContactMethod = State(initialValue: contact.preferredContactMethodEnum ?? .noPreference)
            _buyingPreferences = State(initialValue: contact.buyingPreferences ?? "")
            _specialties = State(initialValue: contact.specialties ?? "")
            _organization = State(initialValue: contact.organization ?? "")
            _eventName = State(initialValue: contact.eventName ?? "")
            _venue = State(initialValue: contact.venue ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Contact Type Picker
                Section {
                    Picker("Type", selection: $contactType) {
                        ForEach(ContactType.allCases) { type in
                            Label(type.label, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Contact Type")
                } footer: {
                    Text(typeDescription)
                }

                // Basic Info
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

                    TextField("Social Media Handle", text: $socialMedia)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Contact Information")
                }

                // Type-specific fields
                typeSpecificSection

                // Notes
                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Anything you want to remember about this contact")
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

    // MARK: - Type Description

    private var typeDescription: String {
        switch contactType {
        case .customer:
            "Someone who buys cards from you"
        case .buyer:
            "Someone you can offload inventory to"
        case .vendor:
            "A fellow vendor you meet at shows or events"
        case .eventDirector:
            "Someone who organizes card shows or events"
        case .other:
            "Any other contact in the card business"
        }
    }

    // MARK: - Type-Specific Fields

    @ViewBuilder
    private var typeSpecificSection: some View {
        switch contactType {
        case .customer:
            customerFields
        case .buyer:
            buyerFields
        case .vendor:
            vendorFields
        case .eventDirector:
            eventDirectorFields
        case .other:
            EmptyView()
        }
    }

    @ViewBuilder
    private var customerFields: some View {
        Section {
            TextField("What do they collect?", text: $collectingInterests, axis: .vertical)
                .lineLimit(2...4)

            Picker("Spending Tier", selection: $spendingTier) {
                ForEach(SpendingTier.allCases) { tier in
                    Label(tier.label, systemImage: tier.icon)
                        .tag(tier)
                }
            }

            Picker("Preferred Contact Method", selection: $preferredContactMethod) {
                ForEach(PreferredContactMethod.allCases) { method in
                    Label(method.label, systemImage: method.icon)
                        .tag(method)
                }
            }
        } header: {
            Text("Customer Details")
        } footer: {
            Text("Track what this customer is interested in and how they like to be reached")
        }
    }

    @ViewBuilder
    private var buyerFields: some View {
        Section {
            TextField("What do they buy?", text: $buyingPreferences, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Buyer Details")
        } footer: {
            Text("What kind of inventory they're looking to take off your hands")
        }
    }

    @ViewBuilder
    private var vendorFields: some View {
        Section {
            TextField("What do they deal in?", text: $specialties, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Vendor Details")
        } footer: {
            Text("What kind of cards or products they specialize in")
        }
    }

    @ViewBuilder
    private var eventDirectorFields: some View {
        Section {
            TextField("Organization", text: $organization)

            TextField("Event Name", text: $eventName)

            TextField("Venue / Location", text: $venue)
        } header: {
            Text("Event Details")
        } footer: {
            Text("Details about the shows or events they run")
        }
    }

    // MARK: - Save

    private func saveContact() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedSocial = socialMedia.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let trimmedInterests = collectingInterests.trimmingCharacters(in: .whitespaces)
        let trimmedBuying = buyingPreferences.trimmingCharacters(in: .whitespaces)
        let trimmedSpecialties = specialties.trimmingCharacters(in: .whitespaces)
        let trimmedOrganization = organization.trimmingCharacters(in: .whitespaces)
        let trimmedEventName = eventName.trimmingCharacters(in: .whitespaces)
        let trimmedVenue = venue.trimmingCharacters(in: .whitespaces)

        if let contact {
            // Update existing contact in-place (SwiftData tracks changes)
            contact.name = trimmedName
            contact.contactTypeEnum = contactType
            contact.phone = trimmedPhone.isEmpty ? nil : trimmedPhone
            contact.email = trimmedEmail.isEmpty ? nil : trimmedEmail
            contact.socialMedia = trimmedSocial.isEmpty ? nil : trimmedSocial
            contact.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            contact.collectingInterests = contactType == .customer && !trimmedInterests.isEmpty ? trimmedInterests : nil
            contact.spendingTierEnum = contactType == .customer ? spendingTier : nil
            contact.preferredContactMethodEnum = contactType == .customer ? preferredContactMethod : nil
            contact.buyingPreferences = contactType == .buyer && !trimmedBuying.isEmpty ? trimmedBuying : nil
            contact.specialties = contactType == .vendor && !trimmedSpecialties.isEmpty ? trimmedSpecialties : nil
            contact.organization = contactType == .eventDirector && !trimmedOrganization.isEmpty ? trimmedOrganization : nil
            contact.eventName = contactType == .eventDirector && !trimmedEventName.isEmpty ? trimmedEventName : nil
            contact.venue = contactType == .eventDirector && !trimmedVenue.isEmpty ? trimmedVenue : nil
        } else {
            // Create new contact and insert into SwiftData
            let newContact = Contact(
                name: trimmedName,
                contactType: contactType,
                phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
                email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                socialMedia: trimmedSocial.isEmpty ? nil : trimmedSocial,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                collectingInterests: contactType == .customer && !trimmedInterests.isEmpty ? trimmedInterests : nil,
                spendingTier: contactType == .customer ? spendingTier : nil,
                preferredContactMethod: contactType == .customer ? preferredContactMethod : nil,
                buyingPreferences: contactType == .buyer && !trimmedBuying.isEmpty ? trimmedBuying : nil,
                specialties: contactType == .vendor && !trimmedSpecialties.isEmpty ? trimmedSpecialties : nil,
                organization: contactType == .eventDirector && !trimmedOrganization.isEmpty ? trimmedOrganization : nil,
                eventName: contactType == .eventDirector && !trimmedEventName.isEmpty ? trimmedEventName : nil,
                venue: contactType == .eventDirector && !trimmedVenue.isEmpty ? trimmedVenue : nil
            )
            modelContext.insert(newContact)
        }

        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Failed to save contact: \(error)")
            #endif
        }

        dismiss()
    }
}

// MARK: - Previews

#Preview("Add Contact") {
    AddEditContactView()
        .modelContainer(for: Contact.self, inMemory: true)
}

#Preview("Edit Contact") {
    AddEditContactView(
        contact: Contact(
            name: "John Smith",
            contactType: .customer,
            phone: "555-0123",
            collectingInterests: "Vintage Pokemon",
            spendingTier: .regular,
            preferredContactMethod: .text
        )
    )
    .modelContainer(for: Contact.self, inMemory: true)
}
