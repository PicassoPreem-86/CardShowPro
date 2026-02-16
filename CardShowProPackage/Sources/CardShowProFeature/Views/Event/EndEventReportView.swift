import SwiftUI
import SwiftData
import UIKit

// MARK: - End Event Report View

/// Summary report shown when ending an event.
/// Displays final stats and allows the user to close the event.
struct EndEventReportView: View {
    @Bindable var event: Event
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allTransactions: [Transaction]

    @State private var showConfirmClose = false

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

    private var totalAcquisitions: Double {
        purchaseTransactions.reduce(0) { $0 + $1.amount }
    }

    private var netProfit: Double {
        totalRevenue - totalAcquisitions - event.tableCost - event.travelCost
    }

    private var cardsSold: Int {
        salesTransactions.count
    }

    private var cardsAcquired: Int {
        purchaseTransactions.count
    }

    private var bestSale: Transaction? {
        salesTransactions.max(by: { $0.amount < $1.amount })
    }

    private var eventDuration: String {
        guard let start = event.startedAt else { return "--" }
        let end = event.endedAt ?? Date()
        let interval = end.timeIntervalSince(start)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    reportHeader

                    // Profit Card
                    profitCard

                    // Breakdown
                    breakdownSection

                    // Activity Stats
                    activityStats

                    // Best Sale
                    if let best = bestSale {
                        bestSaleCard(transaction: best)
                    }

                    // Close Button
                    if !event.isCompleted {
                        closeEventButton
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Event Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.cyan)
                }
            }
            .alert("End Event?", isPresented: $showConfirmClose) {
                Button("Cancel", role: .cancel) { }
                Button("End Event", role: .destructive) {
                    closeEvent()
                }
            } message: {
                Text("This will mark \"\(event.name)\" as complete. You can still view the report from Event History.")
            }
        }
    }

    // MARK: - Report Header

    private var reportHeader: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            if event.isCompleted {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 36))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            } else {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
            }

            Text(event.name)
                .font(DesignSystem.Typography.heading1)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                Label(event.venue, systemImage: "mappin.circle.fill")
                Label(eventDuration, systemImage: "clock.fill")
            }
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(event.formattedDate)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
    }

    // MARK: - Profit Card

    private var profitCard: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("NET PROFIT")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(netProfit.asCurrency)
                .font(DesignSystem.Typography.displayLarge.monospacedDigit())
                .foregroundStyle(netProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)

            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: netProfit >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                Text(netProfit >= 0 ? "Profitable" : "Loss")
            }
            .font(DesignSystem.Typography.captionBold)
            .foregroundStyle(netProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xxxs)
            .background((netProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error).opacity(0.15))
            .clipShape(Capsule())
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
                .stroke(
                    (netProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error).opacity(0.3),
                    lineWidth: 2
                )
        )
        .shadow(
            color: DesignSystem.Shadows.level3.color,
            radius: DesignSystem.Shadows.level3.radius,
            x: DesignSystem.Shadows.level3.x,
            y: DesignSystem.Shadows.level3.y
        )
    }

    // MARK: - Breakdown Section

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("BREAKDOWN")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                ReportRow(label: "Revenue from Sales", value: totalRevenue.asCurrency, color: DesignSystem.Colors.success)

                Divider().background(DesignSystem.Colors.borderPrimary)

                ReportRow(label: "Card Acquisitions", value: "- \(totalAcquisitions.asCurrency)", color: DesignSystem.Colors.warning)
                ReportRow(label: "Table Cost", value: "- \(event.tableCost.asCurrency)", color: DesignSystem.Colors.warning)
                ReportRow(label: "Travel Cost", value: "- \(event.travelCost.asCurrency)", color: DesignSystem.Colors.warning)

                Divider().background(DesignSystem.Colors.borderPrimary)

                ReportRow(
                    label: "Net Profit",
                    value: netProfit.asCurrency,
                    color: netProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error,
                    isBold: true
                )
            }
            .padding(DesignSystem.Spacing.sm)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Activity Stats

    private var activityStats: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            EventStatCard(
                label: "Cards Sold",
                value: "\(cardsSold)",
                icon: "tag.fill",
                color: DesignSystem.Colors.success
            )

            EventStatCard(
                label: "Cards Acquired",
                value: "\(cardsAcquired)",
                icon: "cart.fill",
                color: DesignSystem.Colors.electricBlue
            )
        }
    }

    // MARK: - Best Sale Card

    private func bestSaleCard(transaction: Transaction) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
                Text("BEST SALE")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text(transaction.cardName.isEmpty ? "Unknown Card" : transaction.cardName)
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    if !transaction.cardSetName.isEmpty {
                        Text(transaction.cardSetName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }

                Spacer()

                Text(transaction.amount.asCurrency)
                    .font(DesignSystem.Typography.heading2.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.cardBackground,
                    DesignSystem.Colors.thunderYellow.opacity(0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.thunderYellow.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Close Event Button

    private var closeEventButton: some View {
        Button {
            showConfirmClose = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "flag.checkered")
                    .font(.title3)
                Text("Close Event")
                    .font(DesignSystem.Typography.labelLarge)
            }
            .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.error)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close this event and finalize the report")
    }

    // MARK: - Close Event Logic

    private func closeEvent() {
        event.endedAt = Date()
        event.isActive = false

        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        dismiss()
    }
}

// MARK: - Report Row

private struct ReportRow: View {
    let label: String
    let value: String
    var color: Color = DesignSystem.Colors.textSecondary
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isBold ? DesignSystem.Typography.labelLarge : DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Text(value)
                .font((isBold ? DesignSystem.Typography.labelLarge : DesignSystem.Typography.body).monospacedDigit())
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Event Stat Card

private struct EventStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(DesignSystem.Typography.displaySmall.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview("End Event Report") {
    EndEventReportView(
        event: {
            let e = Event(
                name: "Portland Card Show",
                venue: "Oregon Convention Center",
                tableCost: 150,
                travelCost: 45,
                isActive: true,
                startedAt: Date().addingTimeInterval(-3600 * 4)
            )
            return e
        }()
    )
}
