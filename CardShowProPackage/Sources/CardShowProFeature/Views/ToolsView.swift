import SwiftUI
import SwiftData

struct ToolsView: View {
    @Environment(AppState.self) private var appState
    @Query private var events: [Event]
    @Query private var contacts: [Contact]
    @Query(filter: #Predicate<WishlistItem> { !$0.isFulfilled }) private var wishlistItems: [WishlistItem]

    @State private var navigationPath = NavigationPath()

    private var activeEventCount: Int {
        events.filter { $0.isActive }.count
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                NebulaBackgroundView()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        // Events - Top priority for card show dealers
                        ToolSection(title: "Events") {
                            NavigationLink(value: ToolDestination.eventHistory) {
                                ToolRow(
                                    icon: "calendar.circle.fill",
                                    title: "Event History",
                                    description: "View past and current card show events",
                                    color: .purple,
                                    badge: activeEventCount > 0 ? "\(activeEventCount) live" : nil,
                                    badgeColor: .green
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(value: ToolDestination.createEvent) {
                                ToolRow(
                                    icon: "calendar.badge.plus",
                                    title: "Start New Event",
                                    description: "Create a new card show or vendor event",
                                    color: .orange
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Contacts - Promoted to its own section
                        ToolSection(title: "Contacts") {
                            NavigationLink(value: ToolDestination.contacts) {
                                ToolRow(
                                    icon: "person.2.fill",
                                    title: "Business Contacts",
                                    description: "Manage customers and vendor contacts",
                                    color: .blue,
                                    badge: contacts.isEmpty ? nil : "\(contacts.count)",
                                    badgeColor: .blue
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Pricing & Analysis
                        ToolSection(title: "Pricing & Analysis") {
                            NavigationLink(value: ToolDestination.salesCalculator) {
                                ToolRow(
                                    icon: "dollarsign.circle.fill",
                                    title: "Sales Calculator",
                                    description: "Calculate fees, shipping, and profit margins",
                                    color: .green
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("sales-calculator-button")

                            NavigationLink(value: ToolDestination.gradingROI) {
                                ToolRow(
                                    icon: "chart.bar.doc.horizontal.fill",
                                    title: "Grading ROI Calculator",
                                    description: "Calculate if grading is worth the cost",
                                    color: .yellow
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(value: ToolDestination.tradeAnalyzer) {
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
                            NavigationLink(value: ToolDestination.listingGenerator) {
                                ToolRow(
                                    icon: "square.and.pencil",
                                    title: "Listing Generator",
                                    description: "Auto-generate descriptions for listings",
                                    color: .indigo
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(value: ToolDestination.advancedAnalytics) {
                                ToolRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Advanced Analytics",
                                    description: "View detailed portfolio insights and trends",
                                    color: .purple
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Collection
                        ToolSection(title: "Collection") {
                            NavigationLink(value: ToolDestination.wishlist) {
                                ToolRow(
                                    icon: "heart.text.clipboard.fill",
                                    title: "Wishlist",
                                    description: "Track cards you want and share with trade partners",
                                    color: .pink,
                                    badge: wishlistItems.isEmpty ? nil : "\(wishlistItems.count)",
                                    badgeColor: .pink
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Business
                        ToolSection(title: "Business") {
                            NavigationLink(value: ToolDestination.taxSummary) {
                                ToolRow(
                                    icon: "doc.text.fill",
                                    title: "Tax Summary",
                                    description: "Revenue, deductions, and profit for tax reporting",
                                    color: .red
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(value: ToolDestination.managePlatforms) {
                                ToolRow(
                                    icon: "storefront.fill",
                                    title: "Manage Platforms",
                                    description: "Customize platform fees and add your own",
                                    color: .orange
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
            .navigationDestination(for: ToolDestination.self) { destination in
                destination.view
            }
            .onChange(of: appState.pendingDeepLink) { _, newLink in
                guard let link = newLink else { return }
                if let destination = ToolDestination.from(deepLink: link) {
                    navigationPath.append(destination)
                    appState.pendingDeepLink = nil
                }
            }
        }
    }
}

// MARK: - Tool Destinations

enum ToolDestination: Hashable {
    case eventHistory
    case createEvent
    case contacts
    case salesCalculator
    case gradingROI
    case tradeAnalyzer
    case listingGenerator
    case advancedAnalytics
    case wishlist
    case taxSummary
    case managePlatforms

    @MainActor @ViewBuilder
    var view: some View {
        switch self {
        case .eventHistory: EventHistoryView()
        case .createEvent: CreateEventView()
        case .contacts: ContactsView()
        case .salesCalculator: SalesCalculatorView()
        case .gradingROI: GradingROICalculatorView()
        case .tradeAnalyzer: TradeAnalyzerView()
        case .listingGenerator: ListingGeneratorView()
        case .advancedAnalytics: AdvancedAnalyticsView()
        case .wishlist: WishlistView()
        case .taxSummary: TaxSummaryView()
        case .managePlatforms: ManagePlatformsView()
        }
    }

    static func from(deepLink: AppState.DeepLink) -> ToolDestination? {
        switch deepLink {
        case .eventHistory: return .eventHistory
        case .createEvent: return .createEvent
        case .contacts: return .contacts
        case .wishlist: return .wishlist
        case .analytics: return .advancedAnalytics
        case .taxSummary: return .taxSummary
        default: return nil
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
    var badge: String? = nil
    var badgeColor: Color = .blue

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if let badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badgeColor)
                            .clipShape(Capsule())
                    }
                }

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
