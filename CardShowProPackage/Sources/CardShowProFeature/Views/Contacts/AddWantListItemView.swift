import SwiftUI
import SwiftData

/// Sheet for adding or editing want list items
struct AddWantListItemView: View {
    let contact: Contact
    let existingItem: WantListItem?
    let onSave: (WantListItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Form state
    @State private var cardName: String
    @State private var setName: String
    @State private var condition: String
    @State private var hasBudgetLimit: Bool
    @State private var minPrice: String
    @State private var maxPrice: String
    @State private var selectedPriority: ContactPriority
    @State private var notes: String
    @State private var notifyOnMatch: Bool

    private var isEditing: Bool {
        existingItem != nil
    }

    private var canSave: Bool {
        !cardName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(contact: Contact, existingItem: WantListItem? = nil, onSave: @escaping (WantListItem) -> Void) {
        self.contact = contact
        self.existingItem = existingItem
        self.onSave = onSave

        // Initialize state from existing item or defaults
        if let item = existingItem {
            _cardName = State(initialValue: item.cardName)
            _setName = State(initialValue: item.setName ?? "")
            _condition = State(initialValue: item.condition ?? "")
            _hasBudgetLimit = State(initialValue: item.maxPrice != nil)
            _minPrice = State(initialValue: "")
            _maxPrice = State(initialValue: item.maxPrice?.description ?? "")
            _selectedPriority = State(initialValue: item.priorityEnum)
            _notes = State(initialValue: item.notes ?? "")
            _notifyOnMatch = State(initialValue: item.notifyOnMatch)
        } else {
            _cardName = State(initialValue: "")
            _setName = State(initialValue: "")
            _condition = State(initialValue: "")
            _hasBudgetLimit = State(initialValue: false)
            _minPrice = State(initialValue: "")
            _maxPrice = State(initialValue: "")
            _selectedPriority = State(initialValue: .normal)
            _notes = State(initialValue: "")
            _notifyOnMatch = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Card Information Section
                Section {
                    TextField("Card Name", text: $cardName)
                        .font(DesignSystem.Typography.body)

                    TextField("Set Name (Optional)", text: $setName)
                        .font(DesignSystem.Typography.body)

                    TextField("Condition/Grade (Optional)", text: $condition)
                        .font(DesignSystem.Typography.body)
                } header: {
                    Text("Card Information")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                // Budget Section
                Section {
                    Toggle("Set Budget Limit", isOn: $hasBudgetLimit)
                        .font(DesignSystem.Typography.body)

                    if hasBudgetLimit {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Minimum")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                                TextField("$0", text: $minPrice)
                                    .keyboardType(.decimalPad)
                                    .font(DesignSystem.Typography.body)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Text("to")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .padding(.top, 20)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Maximum")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                                TextField("$0", text: $maxPrice)
                                    .keyboardType(.decimalPad)
                                    .font(DesignSystem.Typography.body)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                } header: {
                    Text("Budget")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } footer: {
                    if !hasBudgetLimit {
                        Text("No budget limit will be set for this item")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }

                // Priority Section
                Section {
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(ContactPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(priority))
                                    .frame(width: 12, height: 12)

                                Text(priority.rawValue)
                                    .font(DesignSystem.Typography.body)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Priority")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } footer: {
                    Text(priorityDescription)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                // Notes Section
                Section {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .font(DesignSystem.Typography.body)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes (Optional)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                // Notification Section
                Section {
                    Toggle("Notify on Match", isOn: $notifyOnMatch)
                        .font(DesignSystem.Typography.body)
                } header: {
                    Text("Notifications")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } footer: {
                    Text("Get notified when cards matching this item become available")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
            .navigationTitle(isEditing ? "Edit Want List Item" : "Add Want List Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveItem()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Actions

    private func saveItem() {
        let trimmedCardName = cardName.trimmingCharacters(in: .whitespaces)
        let trimmedSetName = setName.trimmingCharacters(in: .whitespaces)
        let trimmedCondition = condition.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        // Parse max price if budget limit is enabled
        var parsedMaxPrice: Decimal?
        if hasBudgetLimit, !maxPrice.isEmpty {
            if let value = Decimal(string: maxPrice) {
                parsedMaxPrice = value
            }
        }

        if let existing = existingItem {
            // Update existing item
            existing.cardName = trimmedCardName
            existing.setName = trimmedSetName.isEmpty ? nil : trimmedSetName
            existing.condition = trimmedCondition.isEmpty ? nil : trimmedCondition
            existing.maxPrice = parsedMaxPrice
            existing.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            existing.priority = selectedPriority.rawValue
            existing.notifyOnMatch = notifyOnMatch

            onSave(existing)
        } else {
            // Create new item
            let newItem = WantListItem(
                cardName: trimmedCardName,
                setName: trimmedSetName.isEmpty ? nil : trimmedSetName,
                condition: trimmedCondition.isEmpty ? nil : trimmedCondition,
                maxPrice: parsedMaxPrice,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                priority: selectedPriority,
                notifyOnMatch: notifyOnMatch
            )

            // Add to contact's want list
            contact.wantListItems.append(newItem)
            modelContext.insert(newItem)

            onSave(newItem)
        }

        dismiss()
    }

    // MARK: - Helpers

    private func priorityColor(_ priority: ContactPriority) -> Color {
        switch priority {
        case .vip:
            return DesignSystem.Colors.thunderYellow
        case .high:
            return DesignSystem.Colors.warning
        case .normal:
            return DesignSystem.Colors.textSecondary
        case .low:
            return DesignSystem.Colors.textTertiary
        }
    }

    private var priorityDescription: String {
        switch selectedPriority {
        case .vip:
            return "Highest priority - actively seeking"
        case .high:
            return "High priority - willing to pay premium"
        case .normal:
            return "Normal priority - casual interest"
        case .low:
            return "Low priority - only if great deal"
        }
    }
}

// MARK: - Previews

#Preview("Add Want List Item") {
    let contact = Contact.mockContacts[0]
    return AddWantListItemView(contact: contact) { _ in }
}

#Preview("Edit Want List Item") {
    let contact = Contact.mockContacts[1]
    let item = WantListItem(
        cardName: "Charizard",
        setName: "Base Set 1st Edition",
        condition: "PSA 10",
        maxPrice: 5000.00,
        priority: .vip,
        notifyOnMatch: true
    )

    return AddWantListItemView(contact: contact, existingItem: item) { _ in }
}
