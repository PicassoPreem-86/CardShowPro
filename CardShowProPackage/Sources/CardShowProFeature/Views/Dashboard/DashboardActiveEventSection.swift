import SwiftUI
import SwiftData

struct DashboardActiveEventSection: View {
    @Query(sort: \Event.date, order: .reverse) private var events: [Event]
    @Query private var allTransactions: [Transaction]

    @State private var showStartEvent = false
    @State private var showEventDashboard = false

    private var activeEvent: Event? {
        events.first(where: { $0.isActive })
    }

    private var eventTransactions: [Transaction] {
        guard let event = activeEvent else { return [] }
        return allTransactions.filter { $0.eventName == event.name }
    }

    private var eventSales: [Transaction] {
        eventTransactions.filter { $0.transactionType == .sale }
    }

    private var eventRevenue: Double {
        eventSales.reduce(0) { $0 + $1.amount }
    }

    private var eventProfit: Double {
        let purchases = eventTransactions.filter { $0.transactionType == .purchase }
        let spent = purchases.reduce(0) { $0 + $1.amount }
        return eventRevenue - spent - (activeEvent?.fixedCosts ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Show Mode")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let event = activeEvent {
                // Active event card - tap to open full dashboard
                Button {
                    showEventDashboard = true
                } label: {
                    activeEventCard(event: event)
                }
                .buttonStyle(.plain)

                // Live stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    EventMetricCard(
                        label: "Revenue",
                        value: eventRevenue.asCurrency,
                        icon: "dollarsign.circle.fill",
                        iconColor: .green
                    )

                    EventMetricCard(
                        label: "Net Profit",
                        value: eventProfit.asCurrency,
                        icon: "chart.bar.fill",
                        iconColor: eventProfit >= 0 ? .orange : .red
                    )

                    EventMetricCard(
                        label: "Cards Sold",
                        value: "\(eventSales.count)",
                        icon: "tag.fill",
                        iconColor: .blue
                    )

                    EventMetricCard(
                        label: "Transactions",
                        value: "\(eventTransactions.count)",
                        icon: "creditcard.fill",
                        iconColor: .purple
                    )
                }
            } else {
                // No active event - show start button
                Button {
                    showStartEvent = true
                } label: {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "ticket.fill")
                            .font(.title2)
                            .foregroundStyle(DesignSystem.Colors.thunderYellow)

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                            Text("Start a Card Show")
                                .font(DesignSystem.Typography.labelLarge)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text("Track sales and profits in real time")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.thunderYellow.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showStartEvent) {
            StartEventView()
        }
        .sheet(isPresented: $showEventDashboard) {
            if let event = activeEvent {
                NavigationStack {
                    EventDashboardView(event: event)
                }
            }
        }
    }

    // MARK: - Active Event Card

    private func activeEventCard(event: Event) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Circle()
                        .fill(DesignSystem.Colors.success)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.success)
                }

                Text(event.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                    Text(event.venue)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                Text("Running \(event.formattedDuration)")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.cyan)
            }

            Spacer()

            Image(systemName: "chevron.right.circle.fill")
                .font(.title2)
                .foregroundStyle(DesignSystem.Colors.thunderYellow)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [DesignSystem.Colors.cardBackground, DesignSystem.Colors.premiumCardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel("Active event: \(event.name) at \(event.venue)")
        .accessibilityHint("Tap to open event dashboard")
    }
}
