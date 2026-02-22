import SwiftUI
import SwiftData

// MARK: - Event Dashboard View

/// Live dashboard shown during an active card show event.
/// Displays real-time stats, running timer, and quick action buttons.
struct EventDashboardView: View {
    @Bindable var event: Event
    @Environment(\.modelContext) private var modelContext

    @Query private var allTransactions: [Transaction]
    @Query private var allCards: [InventoryCard]

    @State private var showQuickSale = false
    @State private var showQuickBuy = false
    @State private var showEndEvent = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var lookupSearchText = ""
    @State private var revenueGoal: Double = 0
    @State private var showGoalEntry = false

    // MARK: - Filtered Transactions

    private var eventTransactions: [Transaction] {
        allTransactions.filter { $0.eventName == event.name }
    }

    private var salesTransactions: [Transaction] {
        eventTransactions.filter { $0.transactionType == .sale }
    }

    private var purchaseTransactions: [Transaction] {
        eventTransactions.filter { $0.transactionType == .purchase }
    }

    // MARK: - Stats

    private var totalRevenue: Double {
        salesTransactions.reduce(0) { $0 + $1.amount }
    }

    private var totalSpent: Double {
        purchaseTransactions.reduce(0) { $0 + $1.amount }
    }

    private var netProfit: Double {
        totalRevenue - totalSpent - event.tableCost - event.travelCost
    }

    private var cardsSold: Int {
        salesTransactions.count
    }

    private var cardsAcquired: Int {
        purchaseTransactions.count
    }

    // MARK: - Price Lookup

    private var lookupResults: [InventoryCard] {
        guard !lookupSearchText.isEmpty else { return [] }
        let query = lookupSearchText.lowercased()
        return allCards.filter {
            $0.cardName.lowercased().contains(query) ||
            $0.setName.lowercased().contains(query)
        }.prefix(5).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                eventHeader

                // Timer
                runningTimer

                // Quick Price Lookup
                priceLookupBar

                // Running sales counter
                salesCounter

                // Revenue Goal Progress
                if revenueGoal > 0 {
                    goalProgress
                }

                // Live Stats Grid
                statsGrid

                // Quick Action Buttons
                quickActions

                // Recent Activity
                recentActivity

                // End Event Button
                endEventButton
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle("Show Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .sheet(isPresented: $showQuickSale) {
            QuickSaleView(eventName: event.name)
        }
        .sheet(isPresented: $showQuickBuy) {
            QuickBuyView(eventName: event.name)
        }
        .sheet(isPresented: $showEndEvent) {
            EndEventReportView(event: event)
        }
    }

    // MARK: - Event Header

    private var eventHeader: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(DesignSystem.Colors.success)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .fill(DesignSystem.Colors.success.opacity(0.4))
                            .frame(width: 20, height: 20)
                    )

                Text("LIVE")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.success)
            }

            Text(event.name)
                .font(DesignSystem.Typography.heading1)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                Text(event.venue)
                    .font(DesignSystem.Typography.body)
            }
            .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.cardBackground,
                    DesignSystem.Colors.premiumCardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .stroke(DesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Running Timer

    private var runningTimer: some View {
        VStack(spacing: DesignSystem.Spacing.xxxs) {
            Text("ELAPSED TIME")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(formattedElapsedTime)
                .font(DesignSystem.Typography.displayMedium.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.cyan)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .accessibilityLabel("Elapsed time: \(formattedElapsedTime)")
    }

    private var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                StatCard(
                    label: "Revenue",
                    value: totalRevenue.asCurrency,
                    icon: "arrow.down.circle.fill",
                    color: DesignSystem.Colors.success
                )

                StatCard(
                    label: "Spent",
                    value: totalSpent.asCurrency,
                    icon: "arrow.up.circle.fill",
                    color: DesignSystem.Colors.warning
                )
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                StatCard(
                    label: "Net Profit",
                    value: netProfit.asCurrency,
                    icon: "chart.line.uptrend.xyaxis",
                    color: netProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error
                )

                HStack(spacing: DesignSystem.Spacing.sm) {
                    MiniStatCard(
                        label: "Sold",
                        value: "\(cardsSold)",
                        icon: "tag.fill",
                        color: DesignSystem.Colors.success
                    )

                    MiniStatCard(
                        label: "Bought",
                        value: "\(cardsAcquired)",
                        icon: "cart.fill",
                        color: DesignSystem.Colors.electricBlue
                    )
                }
            }
        }
    }

    // MARK: - Price Lookup Bar

    private var priceLookupBar: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                TextField("Quick price lookup...", text: $lookupSearchText)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .autocorrectionDisabled()

                if !lookupSearchText.isEmpty {
                    Button {
                        lookupSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

            if !lookupResults.isEmpty {
                VStack(spacing: DesignSystem.Spacing.xxxs) {
                    ForEach(lookupResults, id: \.id) { card in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(card.cardName)
                                    .font(DesignSystem.Typography.labelLarge)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    .lineLimit(1)
                                Text(card.setName)
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(card.estimatedValue.asCurrency)
                                .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                                .foregroundStyle(DesignSystem.Colors.success)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                    }
                }
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            } else if !lookupSearchText.isEmpty {
                Text("No matching cards in inventory")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Sales Counter

    private var salesCounter: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text("SESSION TOTAL")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text("\(totalRevenue.asCurrency) from \(cardsSold) sales")
                    .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.success)
            }

            Spacer()

            Button {
                showQuickSale = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    Image(systemName: "plus.circle.fill")
                    Text("Sell Another")
                }
                .font(DesignSystem.Typography.label)
                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.success)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Goal Progress

    private var goalProgress: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("REVENUE GOAL")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text("\(totalRevenue.asCurrency) / \(revenueGoal.asCurrency)")
                    .font(DesignSystem.Typography.caption.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.backgroundTertiary)
                        .frame(height: 8)

                    let progress = min(totalRevenue / revenueGoal, 1.0)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress >= 1.0 ? DesignSystem.Colors.success : DesignSystem.Colors.thunderYellow)
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            if totalRevenue >= revenueGoal {
                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text("Goal reached!")
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.success)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Button {
                showQuickSale = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        Text("Quick Sale")
                            .font(DesignSystem.Typography.labelLarge)
                        Text("Record a sale")
                            .font(DesignSystem.Typography.captionSmall)
                            .opacity(0.8)
                    }
                }
                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.success)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Quick Sale: Record a sale at this event")

            Button {
                showQuickBuy = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "cart.fill.badge.plus")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        Text("Quick Buy")
                            .font(DesignSystem.Typography.labelLarge)
                        Text("Add to inventory")
                            .font(DesignSystem.Typography.captionSmall)
                            .opacity(0.8)
                    }
                }
                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.electricBlue)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Quick Buy: Add a card purchase to inventory")
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("RECENT ACTIVITY")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            if eventTransactions.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    Text("No transactions yet")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    Text("Use Quick Sale or Quick Buy to get started")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xl)
            } else {
                let recentItems = Array(
                    eventTransactions
                        .sorted { $0.date > $1.date }
                        .prefix(5)
                )
                ForEach(recentItems, id: \.id) { transaction in
                    ActivityRow(transaction: transaction)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - End Event Button

    private var endEventButton: some View {
        Button {
            showEndEvent = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "flag.checkered")
                Text("End Event")
                    .font(DesignSystem.Typography.labelLarge)
            }
            .foregroundStyle(DesignSystem.Colors.error)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.error.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("End this event and see your summary report")
    }

    // MARK: - Timer Management

    private func startTimer() {
        updateElapsedTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                updateElapsedTime()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsedTime() {
        guard let start = event.startedAt else {
            elapsedTime = 0
            return
        }
        elapsedTime = Date().timeIntervalSince(start)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label.uppercased())
                    .font(DesignSystem.Typography.captionBold)
            }
            .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(value)
                .font(DesignSystem.Typography.heading2.monospacedDigit())
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Mini Stat Card

private struct MiniStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxxs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(DesignSystem.Typography.heading3.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text(label)
                .font(DesignSystem.Typography.captionSmall)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let transaction: Transaction

    private var isSale: Bool {
        transaction.transactionType == .sale
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: isSale ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title3)
                .foregroundStyle(isSale ? DesignSystem.Colors.success : DesignSystem.Colors.electricBlue)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(transaction.cardName.isEmpty ? "Unknown Card" : transaction.cardName)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                Text(isSale ? "Sale" : "Purchase")
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            Text("\(isSale ? "+" : "-")\(transaction.amount.asCurrency)")
                .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(isSale ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Event Dashboard - Active") {
    NavigationStack {
        EventDashboardView(
            event: {
                let e = Event(
                    name: "Portland Card Show",
                    venue: "Oregon Convention Center",
                    tableCost: 150,
                    travelCost: 45,
                    isActive: true,
                    startedAt: Date().addingTimeInterval(-3600 * 2)
                )
                return e
            }()
        )
    }
}
