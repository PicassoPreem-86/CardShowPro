import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query private var inventoryCards: [InventoryCard]
    @Query private var transactions: [Transaction]
    @Query(filter: #Predicate<WishlistItem> { !$0.isFulfilled }) private var wishlistItems: [WishlistItem]
    @Query private var contacts: [Contact]
    @State private var showCamera = false
    @State private var showSettings = false
    @State private var showAddItem = false
    @State private var showTransactions = false
    @State private var showEventHistory = false
    @State private var showSearch = false
    @State private var showCreateEvent = false
    @State private var selectedPeriod = "1M"
    @State private var selectedTab = "Overview"
    @State private var analyticsService = AnalyticsService()

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

    // Needs Attention alerts
    private var staleListings: [InventoryCard] {
        inventoryCards.filter { card in
            guard card.cardStatus == .listed, let listedDate = card.listedDate else { return false }
            let daysSinceListed = Calendar.current.dateComponents([.day], from: listedDate, to: Date()).day ?? 0
            return daysSinceListed >= 14
        }
    }

    private var missingCostCards: [InventoryCard] {
        activeCards.filter { $0.purchaseCost == nil }
    }

    private var recentTransactions: [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
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

                            needsAttentionSection

                            salesPerformanceSection

                            inventoryHealthSection

                            recentActivitySection

                            topPerformersSection
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .accessibilityLabel("Search everything")
                }
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
            .sheet(isPresented: $showEventHistory) {
                NavigationStack {
                    EventHistoryView()
                }
            }
            .sheet(isPresented: $showSearch) {
                NavigationStack {
                    UnifiedSearchView()
                }
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventView()
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionButton(
                        title: "Price\nLookup",
                        icon: "magnifyingglass.circle.fill",
                        color: .cyan
                    ) {
                        showCamera = true
                    }

                    QuickActionButton(
                        title: "Add\nManual",
                        icon: "plus.square.fill",
                        color: .green
                    ) {
                        showAddItem = true
                    }

                    QuickActionButton(
                        title: "Start\nEvent",
                        icon: "calendar.badge.plus",
                        color: .orange
                    ) {
                        showCreateEvent = true
                    }

                    QuickActionButton(
                        title: "Trans-\nactions",
                        icon: "arrow.left.arrow.right.circle.fill",
                        color: .purple
                    ) {
                        showTransactions = true
                    }

                    QuickActionButton(
                        title: "Event\nHistory",
                        icon: "calendar.circle.fill",
                        color: .indigo
                    ) {
                        showEventHistory = true
                    }
                }
            }
        }
    }

    // MARK: - Needs Attention
    private var needsAttentionSection: some View {
        let alerts = buildAlerts()

        return Group {
            if !alerts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Needs Attention")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ForEach(alerts, id: \.title) { alert in
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: alert.icon)
                                .font(.title3)
                                .foregroundStyle(alert.color)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                                Text(alert.title)
                                    .font(DesignSystem.Typography.labelLarge)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                                Text(alert.subtitle)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private struct AlertItem: Hashable {
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
    }

    private func buildAlerts() -> [AlertItem] {
        var items: [AlertItem] = []

        if !staleListings.isEmpty {
            items.append(AlertItem(
                title: "\(staleListings.count) stale listing\(staleListings.count == 1 ? "" : "s")",
                subtitle: "Listed over 14 days without selling",
                icon: "clock.badge.exclamationmark",
                color: DesignSystem.Colors.warning
            ))
        }

        if slowStockCount > 0 {
            items.append(AlertItem(
                title: "\(slowStockCount) slow stock item\(slowStockCount == 1 ? "" : "s")",
                subtitle: "Sitting in inventory 90+ days",
                icon: "tortoise.fill",
                color: .orange
            ))
        }

        if !missingCostCards.isEmpty {
            items.append(AlertItem(
                title: "\(missingCostCards.count) card\(missingCostCards.count == 1 ? "" : "s") missing cost",
                subtitle: "Add purchase cost for accurate profit tracking",
                icon: "exclamationmark.circle.fill",
                color: DesignSystem.Colors.textSecondary
            ))
        }

        let overdueFollowUps = contacts.filter { $0.isFollowUpOverdue }
        if !overdueFollowUps.isEmpty {
            let names = overdueFollowUps.prefix(2).map(\.name).joined(separator: ", ")
            let suffix = overdueFollowUps.count > 2 ? " + \(overdueFollowUps.count - 2) more" : ""
            items.append(AlertItem(
                title: "\(overdueFollowUps.count) overdue follow-up\(overdueFollowUps.count == 1 ? "" : "s")",
                subtitle: names + suffix,
                icon: "bell.badge.fill",
                color: DesignSystem.Colors.warning
            ))
        }

        return items
    }

    // MARK: - Sales Performance
    private var salesPerformanceSection: some View {
        let sellThrough = analyticsService.sellThroughRate(cards: inventoryCards)
        let avgDays = analyticsService.averageDaysToSale(cards: inventoryCards)
        let realized = analyticsService.realizedProfit(transactions: transactions)

        return VStack(alignment: .leading, spacing: 12) {
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

                StatsCard(
                    icon: "gauge.with.needle.fill",
                    iconColor: .purple,
                    value: String(format: "%.0f%%", sellThrough * 100),
                    label: "Sell-Through Rate"
                )

                StatsCard(
                    icon: "clock.fill",
                    iconColor: .teal,
                    value: avgDays.map { String(format: "%.0fd", $0) } ?? "--",
                    label: "Avg Days to Sale"
                )

                StatsCard(
                    icon: "banknote.fill",
                    iconColor: .green,
                    value: formatCurrency(realized),
                    label: "Realized Profit"
                )
            }
        }
    }

    // MARK: - Inventory Health
    private var inventoryHealthSection: some View {
        let turnover = analyticsService.inventoryTurnover(cards: inventoryCards, transactions: transactions)

        return VStack(alignment: .leading, spacing: 12) {
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

                StatsCard(
                    icon: "arrow.3.trianglepath",
                    iconColor: .mint,
                    value: String(format: "%.1fx", turnover),
                    label: "Inventory Turnover"
                )

                StatsCard(
                    icon: "heart.text.clipboard.fill",
                    iconColor: .pink,
                    value: "\(wishlistItems.count)",
                    label: "On Wishlist"
                )
            }
        }
    }

    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundStyle(.secondary)

            if recentTransactions.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    Text("No transactions yet")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            } else {
                VStack(spacing: 0) {
                    ForEach(recentTransactions, id: \.id) { transaction in
                        DashboardActivityRow(transaction: transaction)

                        if transaction.id != recentTransactions.last?.id {
                            Divider()
                                .background(DesignSystem.Colors.borderPrimary)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    }
                }
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
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

// MARK: - Dashboard Activity Row

private struct DashboardActivityRow: View {
    let transaction: Transaction

    private var isSale: Bool {
        transaction.transactionType == .sale
    }

    private var isPurchase: Bool {
        transaction.transactionType == .purchase
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: transactionIcon)
                .font(.title3)
                .foregroundStyle(transactionColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(transaction.cardName.isEmpty ? "Unknown" : transaction.cardName)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(transaction.transactionType.rawValue)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text(transaction.formattedDate)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer()

            Text("\(isSale ? "+" : isPurchase ? "-" : "")\(transaction.amount.asCurrency)")
                .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(isSale ? DesignSystem.Colors.success : isPurchase ? DesignSystem.Colors.warning : DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .accessibilityElement(children: .combine)
    }

    private var transactionIcon: String {
        switch transaction.transactionType {
        case .sale: return "arrow.down.circle.fill"
        case .purchase: return "arrow.up.circle.fill"
        case .trade: return "arrow.triangle.2.circlepath.circle.fill"
        case .consignment: return "shippingbox.circle.fill"
        case .refund: return "arrow.uturn.backward.circle.fill"
        }
    }

    private var transactionColor: Color {
        switch transaction.transactionType {
        case .sale: return DesignSystem.Colors.success
        case .purchase: return DesignSystem.Colors.electricBlue
        case .trade: return .orange
        case .consignment: return .purple
        case .refund: return .red
        }
    }
}
