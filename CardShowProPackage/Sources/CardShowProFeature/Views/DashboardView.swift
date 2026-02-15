import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query private var inventoryCards: [InventoryCard]
    @Query private var transactions: [Transaction]
    @State private var showCamera = false
    @State private var showSettings = false
    @State private var showAddItem = false
    @State private var showTransactions = false
    @State private var selectedPeriod = "1M"
    @State private var selectedTab = "Overview"

    // Calculated stats from real inventory
    private var activeCards: [InventoryCard] {
        inventoryCards.filter { $0.isAvailable }
    }

    private var totalValue: Double {
        activeCards.reduce(0.0) { $0 + $1.marketValue }
    }

    private var totalCost: Double {
        activeCards.reduce(0.0) { $0 + ($1.purchaseCost ?? 0) }
    }

    private var topCard: InventoryCard? {
        activeCards.max(by: { $0.marketValue < $1.marketValue })
    }

    private var saleTxns: [Transaction] {
        transactions.filter { $0.transactionType == .sale }
    }

    private var totalRevenue: Double {
        saleTxns.reduce(0.0) { $0 + $1.netAmount }
    }

    private var profitMargin: Double {
        guard totalRevenue > 0 else { return 0 }
        let totalSaleProfit = saleTxns.reduce(0.0) { $0 + $1.profit }
        return (totalSaleProfit / totalRevenue) * 100
    }

    private var avgSale: Double {
        guard !saleTxns.isEmpty else { return 0 }
        return totalRevenue / Double(saleTxns.count)
    }

    private var slowStockCount: Int {
        activeCards.filter { $0.daysInInventory >= 90 }.count
    }

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            ZStack {
                NebulaBackgroundView()

                VStack(spacing: 0) {
                    quickActionsSection
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 4)

                    ScrollView {
                        VStack(spacing: 24) {
                            DashboardBusinessHealthCard(
                                selectedTab: $selectedTab,
                                selectedPeriod: $selectedPeriod
                            )

                            if appState.isShowModeActive {
                                DashboardActiveEventSection()
                            }

                            salesPerformanceSection

                            inventoryHealthSection

                            topPerformersSection

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
            .sheet(isPresented: $showTransactions) {
                NavigationStack {
                    TransactionHistoryView()
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
                    title: "Trans-\nactions",
                    icon: "arrow.left.arrow.right.circle.fill",
                    color: .orange
                ) {
                    showTransactions = true
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
                    value: formatCurrency(totalRevenue),
                    label: "Total Revenue"
                )

                StatsCard(
                    icon: "cart.fill",
                    iconColor: .blue,
                    value: "\(saleTxns.count)",
                    label: "Transactions"
                )

                StatsCard(
                    icon: "chart.bar.fill",
                    iconColor: .cyan,
                    value: formatCurrency(avgSale),
                    label: "Average Sale"
                )

                StatsCard(
                    icon: "percent",
                    iconColor: .orange,
                    value: String(format: "%.0f%%", profitMargin),
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
                    value: formatCurrency(totalValue),
                    label: "Total Value"
                )

                StatsCard(
                    icon: "dollarsign.square.fill",
                    iconColor: .purple,
                    value: formatCurrency(totalCost),
                    label: "Cost Basis"
                )

                StatsCard(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .cyan,
                    value: "\(activeCards.count)",
                    label: "Active Cards"
                )

                StatsCard(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    value: "\(slowStockCount)",
                    label: "Slow Stock (90d+)"
                )
            }
        }
    }

    // MARK: - Top Business Performers
    private var topPerformersSection: some View {
        let mostProfitable = activeCards.max(by: { $0.profit < $1.profit })
        let soldCards = inventoryCards.filter { $0.isSold }
        let topSet = Dictionary(grouping: activeCards, by: { $0.setName })
            .max(by: { $0.value.reduce(0) { $0 + $1.profit } < $1.value.reduce(0) { $0 + $1.profit } })
        let gradedSoldCount = soldCards.filter { $0.isGraded }.count

        return VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PerformerCard(
                    title: "Most Profitable",
                    itemName: mostProfitable?.cardName ?? "N/A",
                    value: formatCurrency(mostProfitable?.profit ?? 0),
                    subtitle: "profit",
                    icon: "trophy.fill",
                    iconColor: .yellow
                )

                PerformerCard(
                    title: "Cards Sold",
                    itemName: "\(soldCards.count) total",
                    value: "\(soldCards.count)",
                    subtitle: "all time",
                    icon: "flame.fill",
                    iconColor: .orange
                )

                PerformerCard(
                    title: "Top Set",
                    itemName: topSet?.key ?? "N/A",
                    value: formatCurrency(topSet?.value.reduce(0) { $0 + $1.profit } ?? 0),
                    subtitle: "total profit",
                    icon: "star.fill",
                    iconColor: .cyan
                )

                PerformerCard(
                    title: "Graded Sold",
                    itemName: "\(gradedSoldCount) cards",
                    value: "\(gradedSoldCount)",
                    subtitle: "graded sold",
                    icon: "location.fill",
                    iconColor: .green
                )
            }
        }
    }

    // MARK: - Formatting

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
