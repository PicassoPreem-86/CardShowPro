import SwiftUI

/// Consistent section header component for analytics dashboard
/// Provides uniform styling for section titles with optional action buttons
@MainActor
struct AnalyticsSectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionLabel: String?

    init(
        title: String,
        subtitle: String? = nil,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(title)
                    .font(DesignSystem.Typography.heading3)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()

            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.electricBlue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, DesignSystem.Spacing.xs)
    }
}

// MARK: - Previews

#Preview("Section Header - Basic") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        AnalyticsSectionHeader(title: "Portfolio Overview")

        Divider()

        AnalyticsSectionHeader(
            title: "Top Performers",
            subtitle: "Your highest value cards"
        )

        Divider()

        AnalyticsSectionHeader(
            title: "Set Breakdown",
            subtitle: "Performance by Pokemon set",
            actionLabel: "View All",
            action: { print("View All tapped") }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
