import SwiftUI
import SwiftData

// MARK: - Event History View

/// List of all past and current events with summary stats for each.
/// Tapping an event shows a detailed report.
struct EventHistoryView: View {
    @Query(sort: \Event.date, order: .reverse) private var events: [Event]
    @Query private var allTransactions: [Transaction]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedEvent: Event?
    @State private var showCreateEvent = false
    @State private var editingEvent: Event?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                                .contextMenu {
                                    Button {
                                        editingEvent = event
                                    } label: {
                                        Label("Edit Event", systemImage: "pencil")
                                    }
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
                                .contextMenu {
                                    Button {
                                        editingEvent = event
                                    } label: {
                                        Label("Edit Event", systemImage: "pencil")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)

            // FAB - Create Event
            Button {
                showCreateEvent = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                    .frame(width: 60, height: 60)
                    .background(DesignSystem.Colors.thunderYellow)
                    .clipShape(Circle())
                    .shadow(
                        color: DesignSystem.Shadows.level4.color,
                        radius: DesignSystem.Shadows.level4.radius,
                        x: DesignSystem.Shadows.level4.x,
                        y: DesignSystem.Shadows.level4.y
                    )
            }
            .padding(DesignSystem.Spacing.lg)
            .accessibilityLabel("Create new event")
        }
        .navigationTitle("Event History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateEvent = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            EndEventReportView(event: event)
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView()
        }
        .sheet(item: $editingEvent) { event in
            EditEventSheet(event: event)
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

// MARK: - Edit Event Sheet

private struct EditEventSheet: View {
    @Bindable var event: Event
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var venue: String = ""
    @State private var tableCostText: String = ""
    @State private var travelCostText: String = ""
    @State private var notes: String = ""
    @State private var showSaveError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("EVENT NAME")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        TextField("Event name", text: $name)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("VENUE")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        TextField("Venue", text: $venue)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("COSTS")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "tablecells")
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                            Text("$")
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            TextField("Table cost", text: $tableCostText)
                                .keyboardType(.decimalPad)
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "car.fill")
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                            Text("$")
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            TextField("Travel cost", text: $travelCostText)
                                .keyboardType(.decimalPad)
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("NOTES")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        TextEditor(text: $notes)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80)
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = event.name
                venue = event.venue
                tableCostText = event.tableCost > 0 ? String(format: "%.2f", event.tableCost) : ""
                travelCostText = event.travelCost > 0 ? String(format: "%.2f", event.travelCost) : ""
                notes = event.notes
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Could not save event changes. Please try again.")
            }
        }
    }

    private func saveChanges() {
        event.name = name.trimmingCharacters(in: .whitespaces)
        event.venue = venue.trimmingCharacters(in: .whitespaces)
        event.tableCost = Double(tableCostText) ?? 0
        event.travelCost = Double(travelCostText) ?? 0
        event.notes = notes
        do {
            try modelContext.save()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save event edits: \(error)")
            #endif
            showSaveError = true
        }
    }
}

#Preview("Event History") {
    NavigationStack {
        EventHistoryView()
    }
}
