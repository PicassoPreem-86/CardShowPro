import SwiftUI

/// Reusable row view for displaying a contact in a list
struct ContactRowView: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Avatar
            ContactAvatarView(initials: contact.initials, size: CGSize(width: 50, height: 50))

            // Contact Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(contact.name)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if let phone = contact.phone {
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

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
    }
}

// MARK: - Previews

#Preview("With Phone") {
    ContactRowView(contact: Contact.mockContacts[0])
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("With Email Only") {
    ContactRowView(contact: Contact.mockContacts[3])
        .background(DesignSystem.Colors.backgroundPrimary)
}
