import SwiftUI

/// Reusable row view for displaying a contact in a list
struct ContactRowView: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Avatar colored by contact type
            ContactAvatarView(
                initials: contact.initials,
                size: CGSize(width: 50, height: 50),
                color: contact.contactType.color
            )

            // Contact Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(contact.name)
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    ContactTypeBadge(type: contact.contactType)
                }

                // Subtitle based on type
                if let subtitle = contact.subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                } else if let phone = contact.phone {
                    Text(phone)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else if let email = contact.email {
                    Text(email)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }

                if let lastContacted = contact.lastContactedAt {
                    Text("Last contact: \(lastContacted, style: .relative) ago")
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer()

            // Spending tier badge for customers
            if contact.contactType == .customer, let tier = contact.spendingTier {
                Image(systemName: tier.icon)
                    .font(.caption)
                    .foregroundStyle(tier.color)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
    }
}

// MARK: - Contact Type Badge

/// Small pill badge showing the contact type
struct ContactTypeBadge: View {
    let type: ContactType

    var body: some View {
        Text(type.label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(type.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(type.color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Previews

#Preview("Customer") {
    ContactRowView(contact: Contact.mockContacts[0])
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Vendor") {
    ContactRowView(contact: Contact.mockContacts[2])
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Event Director") {
    ContactRowView(contact: Contact.mockContacts[3])
        .background(DesignSystem.Colors.backgroundPrimary)
}
