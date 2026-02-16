import SwiftUI
import SwiftData
import UIKit

// MARK: - Start Event View

/// Sheet to create and start a new card show event.
/// Upon starting, the Event is persisted with isActive = true and startedAt = now.
struct StartEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onEventStarted: ((Event) -> Void)?

    @State private var eventName = ""
    @State private var venue = ""
    @State private var date = Date()
    @State private var tableCostText = ""
    @State private var travelCostText = ""
    @State private var notes = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, venue, tableCost, travelCost, notes
    }

    private var tableCost: Double {
        Double(tableCostText) ?? 0
    }

    private var travelCost: Double {
        Double(travelCostText) ?? 0
    }

    private var canStart: Bool {
        !eventName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !venue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Hero header
                    headerSection

                    // Event details
                    detailsSection

                    // Costs
                    costsSection

                    // Date
                    dateSection

                    // Notes
                    notesSection

                    // Start button
                    startButton
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.thunderYellow)

            Text("Start a Card Show")
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Track sales, purchases, and profits in real time")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("EVENT DETAILS")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                StartEventInputField(
                    icon: "calendar",
                    placeholder: "Event name *",
                    text: $eventName,
                    focusedField: $focusedField,
                    field: .name
                )

                StartEventInputField(
                    icon: "building.2.fill",
                    placeholder: "Venue *",
                    text: $venue,
                    focusedField: $focusedField,
                    field: .venue
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Costs Section

    private var costsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("COSTS")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                CurrencyInputField(
                    icon: "tablecells.fill",
                    placeholder: "Table cost",
                    text: $tableCostText,
                    focusedField: $focusedField,
                    field: .tableCost
                )

                CurrencyInputField(
                    icon: "car.fill",
                    placeholder: "Travel cost",
                    text: $travelCostText,
                    focusedField: $focusedField,
                    field: .travelCost
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("DATE")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            DatePicker(
                "Event date",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(DesignSystem.Colors.cyan)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Notes Section

    private var notesSection: some View {
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
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.borderPrimary, lineWidth: 1)
                )
                .focused($focusedField, equals: .notes)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            startEvent()
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "play.fill")
                    .font(.title3)
                Text("Start Event")
                    .font(DesignSystem.Typography.labelLarge)
            }
            .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(
                canStart
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.thunderYellow, DesignSystem.Colors.goldAmber],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    : AnyShapeStyle(DesignSystem.Colors.textDisabled)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            .shadow(
                color: canStart ? DesignSystem.Colors.thunderYellow.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(!canStart)
        .accessibilityLabel("Start event named \(eventName)")
    }

    // MARK: - Start Event Logic

    private func startEvent() {
        guard canStart else { return }

        let event = Event(
            name: eventName.trimmingCharacters(in: .whitespaces),
            date: date,
            venue: venue.trimmingCharacters(in: .whitespaces),
            tableCost: tableCost,
            travelCost: travelCost,
            isActive: true,
            startedAt: Date(),
            notes: notes
        )
        modelContext.insert(event)

        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("StartEventView save failed: \(error)")
            #endif
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        onEventStarted?(event)
        dismiss()
    }
}

// MARK: - Start Event Input Field

private struct StartEventInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var focusedField: StartEventView.Field?
    let field: StartEventView.Field

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .focused($focusedField, equals: field)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(
                    focusedField == field ? DesignSystem.Colors.cyan : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Currency Input Field

private struct CurrencyInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var focusedField: StartEventView.Field?
    let field: StartEventView.Field

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .frame(width: 24)

            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Text("$")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                TextField(placeholder, text: $text)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: field)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(
                    focusedField == field ? DesignSystem.Colors.cyan : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

#Preview("Start Event") {
    StartEventView()
}
