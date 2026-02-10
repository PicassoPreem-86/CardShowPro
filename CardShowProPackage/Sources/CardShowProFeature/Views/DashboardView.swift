import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query private var inventoryCards: [InventoryCard]
    @State private var showCamera = false
    @State private var showSettings = false
    @State private var showAddItem = false
    @State private var selectedPeriod = "1M"
    @State private var selectedTab = "Overview"

    // Calculated stats from inventory
    private var totalValue: Double {
        inventoryCards.reduce(0) { $0 + $1.marketValue }
    }

    private var totalCount: Int {
        inventoryCards.count
    }

    private var topCard: InventoryCard? {
        inventoryCards.max(by: { $0.marketValue < $1.marketValue })
    }

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            ZStack {
                // Nebula background layer
                NebulaBackgroundView()

                // Content layer
                VStack(spacing: 0) {
                // Quick Actions Section - Fixed at top
                quickActionsSection
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 4)

                // Scrollable content below
                ScrollView {
                    VStack(spacing: 24) {
                        // Business Health Overview
                        DashboardBusinessHealthCard(
                            selectedTab: $selectedTab,
                            selectedPeriod: $selectedPeriod
                        )

                        // Active Event Status (Show Mode)
                        if appState.isShowModeActive {
                            DashboardActiveEventSection()
                        }

                        // Category Breakdown
                        DashboardMarketMoversSection()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .padding(.bottom)
                }
            }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(isShowModeActive: $appState.isShowModeActive)
            }
            .sheet(isPresented: $showCamera) {
                NavigationStack {
                    CardPriceLookupView()
                }
            }
            .sheet(isPresented: $showAddItem) {
                NavigationStack {
                    AddEditItemView(cardToEdit: nil)
                }
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Price\nLookup",
                    icon: "magnifyingglass.circle.fill",
                    color: .cyan
                ) {
                    showCamera = true
                }

                QuickActionButton(
                    title: "View\nInventory",
                    icon: "square.stack.3d.up.fill",
                    color: .blue
                ) {
                    // Navigate to inventory tab (handled by tab bar)
                }

                QuickActionButton(
                    title: "Add\nManual",
                    icon: "plus.square.fill",
                    color: .green
                ) {
                    showAddItem = true
                }

                QuickActionButton(
                    title: "Total\nValue",
                    icon: "dollarsign.circle.fill",
                    color: .orange
                ) {
                    // Show total value - already visible on dashboard
                }
            }
        }
    }

    // MARK: - Sales Performance
    private var salesPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sales Performance")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatsCard(
                    icon: "dollarsign.circle.fill",
                    iconColor: .green,
                    value: "$2,340",
                    label: "Revenue This Week"
                )

                StatsCard(
                    icon: "cart.fill",
                    iconColor: .blue,
                    value: "18",
                    label: "Transactions"
                )

                StatsCard(
                    icon: "chart.bar.fill",
                    iconColor: .cyan,
                    value: "$130",
                    label: "Average Sale"
                )

                StatsCard(
                    icon: "percent",
                    iconColor: .orange,
                    value: "34%",
                    label: "Profit Margin"
                )
            }
        }
    }

    // MARK: - Inventory Health
    private var inventoryHealthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inventory Health")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatsCard(
                    icon: "square.stack.3d.up.fill",
                    iconColor: .blue,
                    value: "$18,920",
                    label: "Total Value"
                )

                StatsCard(
                    icon: "dollarsign.square.fill",
                    iconColor: .purple,
                    value: "$12,450",
                    label: "Cost Basis"
                )

                StatsCard(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .cyan,
                    value: "2.3x",
                    label: "Turnover Rate"
                )

                StatsCard(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    value: "12",
                    label: "Dead Stock Alert"
                )
            }
        }
    }

    // MARK: - Top Business Performers
    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PerformerCard(
                    title: "Most Profitable",
                    itemName: "Charizard VMAX",
                    value: "$450",
                    subtitle: "profit",
                    icon: "trophy.fill",
                    iconColor: .yellow
                )

                PerformerCard(
                    title: "Best Moving",
                    itemName: "Graded PSA 10s",
                    value: "15",
                    subtitle: "sold this month",
                    icon: "flame.fill",
                    iconColor: .orange
                )

                PerformerCard(
                    title: "Top Set",
                    itemName: "Base Set Unlimited",
                    value: "$1,200",
                    subtitle: "total profit",
                    icon: "star.fill",
                    iconColor: .cyan
                )

                PerformerCard(
                    title: "Best Source",
                    itemName: "Local Pickups",
                    value: "67%",
                    subtitle: "margin",
                    icon: "location.fill",
                    iconColor: .green
                )
            }
        }
    }
}
