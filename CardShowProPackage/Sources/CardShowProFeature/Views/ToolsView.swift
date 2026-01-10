import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Trading & Analysis Tools
                    ToolSection(title: "Trading & Analysis") {
                        NavigationLink {
                            TradeAnalyzerView()
                        } label: {
                            ToolRow(
                                icon: "arrow.left.arrow.right.circle.fill",
                                title: "Trade Analyzer",
                                description: "Compare card values in trades",
                                color: .blue,
                                isComingSoon: false
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
                                color: .purple,
                                isComingSoon: false
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            GradingROICalculatorView()
                        } label: {
                            ToolRow(
                                icon: "chart.bar.doc.horizontal.fill",
                                title: "Grading ROI Calculator",
                                description: "Calculate if grading is worth the cost",
                                color: .yellow,
                                isComingSoon: false
                            )
                        }
                        .buttonStyle(.plain)

                        ToolRow(
                            icon: "brain.head.profile",
                            title: "Pro Market Agent",
                            description: "AI-powered market insights and pricing",
                            color: .cyan
                        )
                    }

                    // Sales & Listing Tools
                    ToolSection(title: "Sales & Listings") {
                        NavigationLink {
                            SalesCalculatorView()
                        } label: {
                            ToolRow(
                                icon: "dollarsign.circle.fill",
                                title: "Sales Calculator",
                                description: "Calculate fees, shipping, and profit margins",
                                color: .green,
                                isComingSoon: false
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ListingGeneratorView()
                        } label: {
                            ToolRow(
                                icon: "square.and.pencil",
                                title: "Listing Generator",
                                description: "Auto-generate descriptions for listings",
                                color: .indigo,
                                isComingSoon: false
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Organization Tools
                    ToolSection(title: "Organization") {
                        ToolRow(
                            icon: "storefront.fill",
                            title: "Vendor Mode",
                            description: "Manage card shows and events",
                            color: .orange
                        )

                        NavigationLink {
                            ContactsView()
                        } label: {
                            ToolRow(
                                icon: "person.2.fill",
                                title: "Contacts",
                                description: "Manage customers and vendor contacts",
                                color: .blue,
                                isComingSoon: false
                            )
                        }
                        .buttonStyle(.plain)

                        ToolRow(
                            icon: "rectangle.stack.fill.badge.person.crop",
                            title: "Personal Collection",
                            description: "Track your personal card collection",
                            color: .purple
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Tools")
            .background(Color(.systemGroupedBackground))
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
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
    var isComingSoon: Bool = true // Default to coming soon until implemented

    var body: some View {
        Button {
            // Tool action - to be implemented
        } label: {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .opacity(isComingSoon ? 0.5 : 1.0)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if isComingSoon {
                            Text("SOON")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .opacity(isComingSoon ? 0.6 : 1.0)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                    .opacity(isComingSoon ? 0.3 : 1.0)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isComingSoon)
    }
}
