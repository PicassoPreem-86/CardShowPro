import SwiftUI

/// Advanced Analytics Dashboard View
/// Phase 1: Hero metrics with foundation for future chart sections
@MainActor
struct AdvancedAnalyticsView: View {
    @State private var analyticsState = AnalyticsState()

    var body: some View {
        NavigationStack {
            Group {
                if analyticsState.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await analyticsState.refreshData()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }

                        Button {
                            analyticsState.resetFilters()
                        } label: {
                            Label("Reset Filters", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(DesignSystem.Colors.electricBlue)
                    }
                }
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Hero Metrics Section
                HeroMetricsSection(metrics: analyticsState.filteredMetrics)
                    .padding(.horizontal)

                // Future Enhancement: Value Distribution Chart
                placeholderSection(
                    title: "Value Distribution",
                    subtitle: "Coming in Phase 2",
                    icon: "chart.pie.fill"
                )

                // Future Enhancement: Top Performers Chart
                placeholderSection(
                    title: "Top Performers",
                    subtitle: "Coming in Phase 2",
                    icon: "chart.bar.horizontal.fill"
                )

                // Future Enhancement: Set Breakdown
                placeholderSection(
                    title: "Set Breakdown",
                    subtitle: "Coming in Phase 2",
                    icon: "chart.bar.fill"
                )

                // Future Enhancement: Portfolio Trends
                placeholderSection(
                    title: "Portfolio Trends",
                    subtitle: "Coming in Phase 2",
                    icon: "chart.line.uptrend.xyaxis"
                )

                // Future Enhancement: Insights
                placeholderSection(
                    title: "Insights & Opportunities",
                    subtitle: "Coming in Phase 2",
                    icon: "lightbulb.fill"
                )
            }
            .padding(.vertical)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .refreshable {
            await analyticsState.refreshData()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            // Icon
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 80))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            // Title
            Text("No Analytics Available")
                .font(DesignSystem.Typography.heading2)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Description
            Text("Start scanning cards to see portfolio insights and analytics")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundPrimary)
    }

    // MARK: - Placeholder Section

    private func placeholderSection(
        title: String,
        subtitle: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            AnalyticsSectionHeader(title: title, subtitle: subtitle)
                .padding(.horizontal)

            // Placeholder card
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(DesignSystem.Colors.electricBlue.opacity(0.3))

                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(DesignSystem.Colors.cardBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(
                        DesignSystem.Colors.borderPrimary,
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            )
            .padding(.horizontal)
        }
    }
}

// MARK: - Previews

#Preview("Analytics - With Data") {
    AdvancedAnalyticsView()
}

#Preview("Analytics - Empty State") {
    let emptyState = AnalyticsState(data: AnalyticsMockData.generateEmptyData())
    return AdvancedAnalyticsView()
        .onAppear {
            // Use emptyState for preview
        }
}
