import SwiftUI

/// Horizontal scrollable filter bar for contact filtering
struct ContactFilterBar: View {
    @Binding var selectedFilter: ContactFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                ForEach(ContactFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: {
                            selectedFilter = filter
                        }
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xxxs)
        }
        .frame(height: 44)  // HIG minimum touch target
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.labelSmall)
                .foregroundStyle(
                    isSelected
                        ? DesignSystem.Colors.backgroundPrimary
                        : DesignSystem.Colors.textSecondary
                )
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xxs)
                .background(
                    isSelected
                        ? DesignSystem.Colors.thunderYellow
                        : DesignSystem.Colors.backgroundTertiary
                )
                .clipShape(Capsule())
        }
        .animation(DesignSystem.Animation.springSnappy, value: isSelected)
    }
}

// MARK: - Previews

#Preview("Filter Bar - All Selected") {
    @Previewable @State var selectedFilter: ContactFilter = .all

    VStack(spacing: 0) {
        ContactFilterBar(selectedFilter: $selectedFilter)
        Spacer()
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Filter Bar - VIP Selected") {
    @Previewable @State var selectedFilter: ContactFilter = .vip

    VStack(spacing: 0) {
        ContactFilterBar(selectedFilter: $selectedFilter)
        Spacer()
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}
