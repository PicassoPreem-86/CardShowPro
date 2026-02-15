import SwiftUI

/// Detail view showing complete contact information with quick actions
struct ContactDetailView: View {
    let contact: Contact
    let onUpdate: (Contact) -> Void
    let onDelete: () -> Void

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header with avatar and type badge
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ContactAvatarView(
                        initials: contact.initials,
                        size: CGSize(width: 100, height: 100),
                        color: contact.contactType.color
                    )

                    Text(contact.name)
                        .font(DesignSystem.Typography.heading2)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    ContactTypeBadge(type: contact.contactType)
                }
                .padding(.top, DesignSystem.Spacing.lg)

                // Quick Actions
                if contact.hasContactMethod {
                    quickActionsSection
                }

                // Contact Information
                contactInfoSection

                // Type-specific details
                typeSpecificSection

                // Notes
                if let notes = contact.notes, !notes.isEmpty {
                    notesSection(notes)
                }

                // Metadata
                metadataSection

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .sheet(isPresented: $showingEditSheet) {
            AddEditContactView(contact: contact) { updatedContact in
                onUpdate(updatedContact)
            }
        }
        .alert("Delete Contact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \(contact.name)? This action cannot be undone.")
        }
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActionsSection: some View {
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
    private var contactInfoSection: some View {
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
    private var typeSpecificSection: some View {
        switch contact.contactType {
        case .customer:
            customerDetailsSection
        case .buyer:
            buyerDetailsSection
        case .vendor:
            vendorDetailsSection
        case .eventDirector:
            eventDirectorDetailsSection
        case .other:
            EmptyView()
        }
    }

    @ViewBuilder
    private var customerDetailsSection: some View {
        let hasCustomerData = contact.collectingInterests != nil || contact.spendingTier != nil || contact.preferredContactMethod != nil

        if hasCustomerData {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Customer Details")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.xs)

                VStack(spacing: 0) {
                    if let interests = contact.collectingInterests, !interests.isEmpty {
                        InfoRow(label: "Collects", value: interests, icon: "sparkles")
                        if contact.spendingTier != nil || contact.preferredContactMethod != nil {
                            Divider()
                                .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)
                        }
                    }

                    if let tier = contact.spendingTier {
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

                        if contact.preferredContactMethod != nil {
                            Divider()
                                .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)
                        }
                    }

                    if let method = contact.preferredContactMethod, method != .noPreference {
                        InfoRow(label: "Prefers", value: method.label, icon: method.icon)
                    }
                }
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    @ViewBuilder
    private var buyerDetailsSection: some View {
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
    private var vendorDetailsSection: some View {
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
    private var eventDirectorDetailsSection: some View {
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

    // MARK: - Metadata

    @ViewBuilder
    private var metadataSection: some View {
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

#Preview("Customer") {
    NavigationStack {
        ContactDetailView(
            contact: Contact.mockContacts[0],
            onUpdate: { _ in },
            onDelete: { }
        )
    }
}

#Preview("Vendor") {
    NavigationStack {
        ContactDetailView(
            contact: Contact.mockContacts[2],
            onUpdate: { _ in },
            onDelete: { }
        )
    }
}

#Preview("Event Director") {
    NavigationStack {
        ContactDetailView(
            contact: Contact.mockContacts[3],
            onUpdate: { _ in },
            onDelete: { }
        )
    }
}
