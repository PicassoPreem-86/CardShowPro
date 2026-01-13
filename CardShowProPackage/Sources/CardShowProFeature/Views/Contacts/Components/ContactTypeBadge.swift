import SwiftUI

/// Colored pill badge showing contact type (Customer/Vendor/Supplier/Lead)
/// Only displayed for non-Customer types
@MainActor
struct ContactTypeBadge: View {
    let contactType: ContactType

    /// Returns true if this contact type should show a badge (not Customer)
    var shouldShow: Bool {
        contactType != .customer
    }

    var body: some View {
        if shouldShow {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: contactType.icon)
                    .font(.system(size: 10, weight: .semibold))

                Text(contactType.rawValue)
                    .font(DesignSystem.Typography.captionBold)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, DesignSystem.Spacing.xxs)
            .padding(.vertical, DesignSystem.Spacing.xxxs)
            .background(backgroundColor)
            .clipShape(Capsule())
        }
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        switch contactType {
        case .customer:
            return DesignSystem.Colors.electricBlue.opacity(0.2)
        case .vendor:
            return DesignSystem.Colors.goldAmber.opacity(0.2)
        case .supplier:
            return DesignSystem.Colors.cyan.opacity(0.2)
        case .lead:
            return DesignSystem.Colors.warning.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch contactType {
        case .customer:
            return DesignSystem.Colors.electricBlue
        case .vendor:
            return DesignSystem.Colors.goldAmber
        case .supplier:
            return DesignSystem.Colors.cyan
        case .lead:
            return DesignSystem.Colors.warning
        }
    }
}

// MARK: - Previews

#Preview("Vendor Badge") {
    VStack(spacing: DesignSystem.Spacing.md) {
        ContactTypeBadge(contactType: .vendor)
        ContactTypeBadge(contactType: .supplier)
        ContactTypeBadge(contactType: .lead)

        // Customer type should not show badge
        ContactTypeBadge(contactType: .customer)
            .overlay {
                if !ContactTypeBadge(contactType: .customer).shouldShow {
                    Text("(No badge shown)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("All Types") {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
        ForEach(ContactType.allCases, id: \.self) { type in
            HStack {
                Text("\(type.rawValue):")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .frame(width: 80, alignment: .leading)

                ContactTypeBadge(contactType: type)
            }
        }
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
