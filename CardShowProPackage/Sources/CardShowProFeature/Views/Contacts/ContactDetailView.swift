import SwiftData
import SwiftUI

/// Detail view showing complete contact information with quick actions and transaction history
struct ContactDetailView: View {
    let contactID: UUID

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allContacts: [Contact]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    /// Resolve the contact from the query results by ID
    private var contact: Contact? {
        allContacts.first { $0.id == contactID }
    }

    /// Transactions linked to this contact
    private var contactTransactions: [Transaction] {
        allTransactions.filter { $0.contactId == contactID }
    }

    /// Sales transactions only
    private var salesTransactions: [Transaction] {
        contactTransactions.filter { $0.transactionType == .sale }
    }

    /// Total revenue from this contact
    private var totalRevenue: Double {
        salesTransactions.reduce(0) { $0 + $1.amount }
    }

    /// Average transaction value
    private var averageTransactionValue: Double {
        guard !contactTransactions.isEmpty else { return 0 }
        return contactTransactions.reduce(0) { $0 + $1.amount } / Double(contactTransactions.count)
    }

    var body: some View {
        Group {
            if let contact {
                contactContent(contact)
            } else {
                ContentUnavailableView(
                    "Contact Not Found",
                    systemImage: "person.crop.circle.badge.xmark",
                    description: Text("This contact may have been deleted.")
                )
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if contact != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Text("Edit")
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let contact {
                AddEditContactView(contact: contact)
            }
        }
        .alert("Delete Contact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteContact()
            }
        } message: {
            Text("Are you sure you want to delete \(contact?.name ?? "this contact")? This action cannot be undone.")
        }
    }

    // MARK: - Contact Content

    @ViewBuilder
    private func contactContent(_ contact: Contact) -> some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header with avatar and type badge
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ContactAvatarView(
                        initials: contact.initials,
                        size: CGSize(width: 100, height: 100),
                        color: contact.contactTypeEnum.color
                    )

                    Text(contact.name)
                        .font(DesignSystem.Typography.heading2)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ContactTypeBadge(type: contact.contactTypeEnum)

                        if let rating = contact.rating, rating > 0 {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundStyle(star <= rating ? DesignSystem.Colors.thunderYellow : DesignSystem.Colors.textDisabled)
                                }
                            }
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.lg)

                // Tags
                if !contact.tagsArray.isEmpty {
                    tagsSection(contact)
                }

                // Follow-Up Reminder
                if contact.hasFollowUp {
                    followUpSection(contact)
                }

                // Customer Lifetime Value
                if !contactTransactions.isEmpty {
                    salesSummaryCard
                }

                // Quick Actions
                if contact.hasContactMethod {
                    quickActionsSection(contact)
                }

                // Contact Information
                contactInfoSection(contact)

                // Type-specific details
                typeSpecificSection(contact)

                // Notes
                if let notes = contact.notes, !notes.isEmpty {
                    notesSection(notes)
                }

                // Transaction History
                if !contactTransactions.isEmpty {
                    transactionHistorySection
                }

                // Metadata
                metadataSection(contact)

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
        }
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private func quickActionsSection(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Quick Actions")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xs)

            HStack(spacing: DesignSystem.Spacing.sm) {
                if let phone = contact.phone {
                    ContactQuickActionButton(
                        icon: "phone.fill",
                        title: "Call",
                        action: {
                            callContact(phone: phone)
                        }
                    )

                    ContactQuickActionButton(
                        icon: "message.fill",
                        title: "Text",
                        action: {
                            textContact(phone: phone)
                        }
                    )
                }

                if let email = contact.email {
                    ContactQuickActionButton(
                        icon: "envelope.fill",
                        title: "Email",
                        action: {
                            emailContact(email: email)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Contact Info

    @ViewBuilder
    private func contactInfoSection(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Contact Information")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xs)

            VStack(spacing: 0) {
                if let phone = contact.phone {
                    InfoRow(label: "Phone", value: phone, icon: "phone")
                    Divider()
                        .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)
                }

                if let email = contact.email {
                    InfoRow(label: "Email", value: email, icon: "envelope")
                    if contact.socialMedia != nil {
                        Divider()
                            .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)
                    }
                }

                if let social = contact.socialMedia {
                    InfoRow(label: "Social", value: social, icon: "at")
                }
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Type-Specific Section

    @ViewBuilder
    private func typeSpecificSection(_ contact: Contact) -> some View {
        switch contact.contactTypeEnum {
        case .customer:
            customerDetailsSection(contact)
        case .buyer:
            buyerDetailsSection(contact)
        case .vendor:
            vendorDetailsSection(contact)
        case .eventDirector:
            eventDirectorDetailsSection(contact)
        case .other:
            EmptyView()
        }
    }

    @ViewBuilder
    private func customerDetailsSection(_ contact: Contact) -> some View {
        let hasCustomerData = contact.collectingInterests != nil || contact.spendingTierEnum != nil || contact.preferredContactMethodEnum != nil

        if hasCustomerData {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Customer Details")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.xs)

                VStack(spacing: 0) {
                    if let interests = contact.collectingInterests, !interests.isEmpty {
                        InfoRow(label: "Collects", value: interests, icon: "sparkles")
                        if contact.spendingTierEnum != nil || contact.preferredContactMethodEnum != nil {
                            Divider()
                                .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)
                        }
                    }

                    if let tier = contact.spendingTierEnum {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: tier.icon)
                                .font(.body)
                                .foregroundStyle(tier.color)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Spending Tier")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                                Text(tier.label)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundStyle(tier.color)
                                    .fontWeight(.semibold)
                            }

                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.sm)

                        if contact.preferredContactMethodEnum != nil {
                            Divider()
                                .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)
                        }
                    }

                    if let method = contact.preferredContactMethodEnum, method != .noPreference {
                        InfoRow(label: "Prefers", value: method.label, icon: method.icon)
                    }
                }
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    @ViewBuilder
    private func buyerDetailsSection(_ contact: Contact) -> some View {
        if let prefs = contact.buyingPreferences, !prefs.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Buyer Details")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.xs)

                VStack(spacing: 0) {
                    InfoRow(label: "Looking to Buy", value: prefs, icon: "shippingbox")
                }
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    @ViewBuilder
    private func vendorDetailsSection(_ contact: Contact) -> some View {
        if let specialties = contact.specialties, !specialties.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Vendor Details")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.xs)

                VStack(spacing: 0) {
                    InfoRow(label: "Specialties", value: specialties, icon: "tag")
                }
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    @ViewBuilder
    private func eventDirectorDetailsSection(_ contact: Contact) -> some View {
        let hasEventData = contact.organization != nil || contact.eventName != nil || contact.venue != nil

        if hasEventData {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Event Details")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.xs)

                VStack(spacing: 0) {
                    if let org = contact.organization, !org.isEmpty {
                        InfoRow(label: "Organization", value: org, icon: "building.2")
                        if contact.eventName != nil || contact.venue != nil {
                            Divider()
                                .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)
                        }
                    }

                    if let event = contact.eventName, !event.isEmpty {
                        InfoRow(label: "Event", value: event, icon: "calendar")
                        if contact.venue != nil {
                            Divider()
                                .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)
                        }
                    }

                    if let venue = contact.venue, !venue.isEmpty {
                        InfoRow(label: "Venue", value: venue, icon: "mappin.and.ellipse")
                    }
                }
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Notes")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xs)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(notes)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Tags Section

    @ViewBuilder
    private func tagsSection(_ contact: Contact) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                ForEach(contact.tagsArray, id: \.self) { tag in
                    HStack(spacing: 3) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 9))
                        Text(tag)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(DesignSystem.Colors.electricBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DesignSystem.Colors.electricBlue.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Follow-Up Section

    @ViewBuilder
    private func followUpSection(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Follow-Up Reminder")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xs)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: contact.isFollowUpOverdue ? "bell.badge.fill" : "bell.fill")
                        .font(.body)
                        .foregroundStyle(contact.isFollowUpOverdue ? DesignSystem.Colors.warning : DesignSystem.Colors.electricBlue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        if let date = contact.followUpDate {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(DesignSystem.Typography.body)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                                if contact.isFollowUpOverdue {
                                    Text("Overdue")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(DesignSystem.Colors.warning)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        if let note = contact.followUpNote, !note.isEmpty {
                            Text(note)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                contact.isFollowUpOverdue
                    ? DesignSystem.Colors.warning.opacity(0.08)
                    : DesignSystem.Colors.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .strokeBorder(
                        contact.isFollowUpOverdue ? DesignSystem.Colors.warning.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Sales Summary Card

    @ViewBuilder
    private var salesSummaryCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Customer Lifetime Value")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xs)

            VStack(spacing: DesignSystem.Spacing.sm) {
                // Total revenue
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Revenue")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Text(totalRevenue.asCurrency)
                            .font(DesignSystem.Typography.heading2.monospacedDigit())
                            .foregroundStyle(DesignSystem.Colors.success)
                    }
                    Spacer()
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title)
                        .foregroundStyle(DesignSystem.Colors.success.opacity(0.5))
                }

                Divider()

                // Stats row
                HStack(spacing: DesignSystem.Spacing.lg) {
                    VStack(spacing: 2) {
                        Text("\(contactTransactions.count)")
                            .font(DesignSystem.Typography.heading3.monospacedDigit())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Transactions")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }

                    VStack(spacing: 2) {
                        Text("\(salesTransactions.count)")
                            .font(DesignSystem.Typography.heading3.monospacedDigit())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Sales")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }

                    VStack(spacing: 2) {
                        Text(averageTransactionValue.asCurrency)
                            .font(DesignSystem.Typography.heading3.monospacedDigit())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Avg Value")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Transaction History

    @ViewBuilder
    private var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Transaction History")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text("\(contactTransactions.count)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(contactTransactions.enumerated()), id: \.element.id) { index, transaction in
                    ContactTransactionRow(transaction: transaction)

                    if index < contactTransactions.count - 1 {
                        Divider()
                            .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)
                    }
                }
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Metadata

    @ViewBuilder
    private func metadataSection(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Details")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xs)

            VStack(spacing: 0) {
                InfoRow(
                    label: "Created",
                    value: contact.createdAt.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar.badge.plus"
                )

                if let lastContacted = contact.lastContactedAt {
                    Divider()
                        .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)

                    InfoRow(
                        label: "Last Contacted",
                        value: lastContacted.formatted(date: .abbreviated, time: .omitted),
                        icon: "clock"
                    )
                }
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Actions

    private func deleteContact() {
        guard let contact else { return }
        modelContext.delete(contact)
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Failed to delete contact: \(error)")
            #endif
        }
        dismiss()
    }

    private func callContact(phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }

    private func textContact(phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "sms:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }

    private func emailContact(email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Transaction Row

private struct ContactTransactionRow: View {
    let transaction: Transaction

    private var typeColor: Color {
        switch transaction.transactionType {
        case .sale: DesignSystem.Colors.success
        case .purchase: DesignSystem.Colors.electricBlue
        case .trade: DesignSystem.Colors.warning
        case .consignment: DesignSystem.Colors.textSecondary
        case .refund: .red
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: transaction.transactionType.icon)
                .font(.body)
                .foregroundStyle(typeColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(transaction.transactionType.rawValue)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                HStack {
                    if !transaction.cardName.isEmpty {
                        Text(transaction.cardName)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(transaction.formattedAmount)
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(typeColor)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
    }
}

// MARK: - Supporting Views

private struct ContactQuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(DesignSystem.Colors.thunderYellow)
                    .clipShape(Circle())

                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(DesignSystem.Colors.electricBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(value)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.sm)
    }
}

// MARK: - Previews

#Preview("Contact Detail") {
    NavigationStack {
        ContactDetailView(contactID: UUID())
    }
    .modelContainer(for: [Contact.self, Transaction.self], inMemory: true)
}
