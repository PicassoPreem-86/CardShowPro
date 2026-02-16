import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                NebulaBackgroundView()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        // Pricing & Analysis
                        ToolSection(title: "Pricing & Analysis") {
                            NavigationLink {
                                SalesCalculatorView()
                            } label: {
                                ToolRow(
                                    icon: "dollarsign.circle.fill",
                                    title: "Sales Calculator",
                                    description: "Calculate fees, shipping, and profit margins",
                                    color: .green
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("sales-calculator-button")

                            NavigationLink {
                                GradingROICalculatorView()
                            } label: {
                                ToolRow(
                                    icon: "chart.bar.doc.horizontal.fill",
                                    title: "Grading ROI Calculator",
                                    description: "Calculate if grading is worth the cost",
                                    color: .yellow
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                TradeAnalyzerView()
                            } label: {
                                ToolRow(
                                    icon: "arrow.left.arrow.right.circle.fill",
                                    title: "Trade Analyzer",
                                    description: "Compare card values in trades",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Listings & Sales
                        ToolSection(title: "Listings & Sales") {
                            NavigationLink {
                                ListingGeneratorView()
                            } label: {
                                ToolRow(
                                    icon: "square.and.pencil",
                                    title: "Listing Generator",
                                    description: "Auto-generate descriptions for listings",
                                    color: .indigo
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                AdvancedAnalyticsView()
                            } label: {
                                ToolRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Advanced Analytics",
                                    description: "View detailed portfolio insights and trends",
                                    color: .purple
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Business
                        ToolSection(title: "Business") {
                            NavigationLink {
                                ContactsView()
                            } label: {
                                ToolRow(
                                    icon: "person.2.fill",
                                    title: "Contacts",
                                    description: "Manage customers and vendor contacts",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .background(Color.clear)
        }
    }
}

// MARK: - Tool Section

struct ToolSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xxxs)

            VStack(spacing: 0) {
                content
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
}

// MARK: - Tool Row

struct ToolRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description)
    }
}
