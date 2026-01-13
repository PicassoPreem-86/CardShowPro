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
                // Name and badges row
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Text(contact.name)
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    // Contact Type Badge
                    ContactTypeBadgeView(contactType: contact.contactTypeEnum)

                    Spacer()

                    // Priority Badge (VIP/High only)
                    if contact.priorityEnum == .vip || contact.priorityEnum == .high {
                        PriorityBadgeView(priority: contact.priorityEnum)
                    }
                }

                // Contact method
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

                // Bottom row: last contacted and want list count
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    // Last contacted
                    if let lastContacted = contact.lastContactedAt {
                        Text(lastContacted, style: .relative)
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    } else {
                        Text("Never")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }

                    // Want list count
                    if contact.wantListItems.count > 0 {
                        Text("•")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)

                        Text("📋 \(contact.wantListItems.count) wants")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.cyan)
                    }

                    // Mock match count badge (placeholder UI)
                    if shouldShowMatchBadge {
                        Text("•")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)

                        HStack(spacing: 2) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 8))
                            Text("\(mockMatchCount)")
                                .font(DesignSystem.Typography.captionSmall)
                        }
                        .foregroundStyle(DesignSystem.Colors.thunderYellow)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.sm)
        .frame(minHeight: 72)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .contentShape(Rectangle())  // Ensure entire card is tappable
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Double tap to view contact details")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Accessibility

    private var accessibilityText: String {
        var text = "\(contact.name), \(contact.contactTypeEnum.rawValue)"

        if contact.priorityEnum == .vip {
            text += ", VIP"
        } else if contact.priorityEnum == .high {
            text += ", High Priority"
        }

        if contact.wantListItems.count > 0 {
            text += ", \(contact.wantListItems.count) items on want list"
        }

        if let lastContacted = contact.lastContactedAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            text += ", last contacted \(formatter.localizedString(for: lastContacted, relativeTo: Date()))"
        } else {
            text += ", never contacted"
        }

        return text
    }

    // MARK: - Mock Data Helpers

    /// Mock logic to show match badge - will be replaced with real matching logic
    private var shouldShowMatchBadge: Bool {
        // Show for VIP contacts with want lists as mock behavior
        contact.priorityEnum == .vip && contact.wantListItems.count > 0
    }

    private var mockMatchCount: Int {
        // Mock count based on want list size
        min(contact.wantListItems.count, 3)
    }
}

// MARK: - Contact Type Badge

private struct ContactTypeBadgeView: View {
    let contactType: ContactType

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: contactType.icon)
                .font(.system(size: 10))
            Text(contactType.rawValue)
                .font(DesignSystem.Typography.captionSmall)
        }
        .foregroundStyle(DesignSystem.Colors.textSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(DesignSystem.Colors.backgroundTertiary)
        .clipShape(Capsule())
    }
}

// MARK: - Priority Badge

private struct PriorityBadgeView: View {
    let priority: ContactPriority

    var body: some View {
        Text(priority.rawValue)
            .font(DesignSystem.Typography.captionSmall)
            .foregroundStyle(
                priority == .vip
                    ? DesignSystem.Colors.backgroundPrimary
                    : DesignSystem.Colors.textPrimary
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priority.color)
            .clipShape(Capsule())
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
