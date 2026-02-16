import SwiftUI
import SwiftData

// MARK: - Event History View

/// List of all past and current events with summary stats for each.
/// Tapping an event shows a detailed report.
struct EventHistoryView: View {
    @Query(sort: \Event.date, order: .reverse) private var events: [Event]
    @Query private var allTransactions: [Transaction]

    @State private var selectedEvent: Event?

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                if events.isEmpty {
                    emptyState
                } else {
                    // Active events
                    let activeEvents = events.filter { $0.isActive }
                    if !activeEvents.isEmpty {
                        sectionHeader("ACTIVE")
                        ForEach(activeEvents, id: \.id) { event in
                            EventHistoryRow(
                                event: event,
                                netProfit: computeNetProfit(for: event),
                                salesCount: computeSalesCount(for: event),
                                isActive: true
                            )
                            .onTapGesture {
                                selectedEvent = event
                            }
                        }
                    }

                    // Past events
                    let pastEvents = events.filter { !$0.isActive }
                    if !pastEvents.isEmpty {
                        sectionHeader("PAST EVENTS")
                        ForEach(pastEvents, id: \.id) { event in
                            EventHistoryRow(
                                event: event,
                                netProfit: computeNetProfit(for: event),
                                salesCount: computeSalesCount(for: event),
                                isActive: false
                            )
                            .onTapGesture {
                                selectedEvent = event
                            }
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle("Event History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEvent) { event in
            EndEventReportView(event: event)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No Events Yet")
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Start your first card show event to track sales and profits in real time.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Spacing.xxxl)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
        }
        .padding(.top, DesignSystem.Spacing.sm)
    }

    // MARK: - Computation Helpers

    private func transactionsForEvent(_ event: Event) -> [Transaction] {
        allTransactions.filter { $0.eventName == event.name }
    }

    private func computeNetProfit(for event: Event) -> Double {
        let txns = transactionsForEvent(event)
        let revenue = txns.filter { $0.transactionType == .sale }.reduce(0) { $0 + $1.amount }
        let spent = txns.filter { $0.transactionType == .purchase }.reduce(0) { $0 + $1.amount }
        return revenue - spent - event.tableCost - event.travelCost
    }

    private func computeSalesCount(for event: Event) -> Int {
        transactionsForEvent(event).filter { $0.transactionType == .sale }.count
    }
}

// MARK: - Event History Row

private struct EventHistoryRow: View {
    let event: Event
    let netProfit: Double
    let salesCount: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Icon
            VStack {
                Image(systemName: isActive ? "bolt.circle.fill" : "calendar.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isActive ? DesignSystem.Colors.success : DesignSystem.Colors.textTertiary)
            }
            .frame(width: 40)

            // Details
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(event.name)
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)

                    if isActive {
                        Text("LIVE")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.success)
                            .padding(.horizontal, DesignSystem.Spacing.xxs)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.success.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: DesignSystem.Spacing.sm) {
                    Label(event.venue, systemImage: "mappin")
                    Label(event.formattedDate, systemImage: "calendar")
                }
                .font(DesignSystem.Typography.captionSmall)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text("\(salesCount) sales")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    if event.isCompleted {
                        Text(event.formattedDuration)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }

            Spacer()

            // Net Profit
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxxs) {
                Text(netProfit.asCurrency)
                    .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                    .foregroundStyle(netProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)

                Text(netProfit >= 0 ? "profit" : "loss")
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(
                    isActive ? DesignSystem.Colors.success.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.name) at \(event.venue), \(netProfit >= 0 ? "profit" : "loss") \(netProfit.asCurrency)")
    }
}

#Preview("Event History") {
    NavigationStack {
        EventHistoryView()
    }
}
