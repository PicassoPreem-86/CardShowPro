import SwiftUI
import SwiftData

struct MarkAsShippedView: View {
    let card: InventoryCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCarrier: ShippingCarrier = .usps
    @State private var trackingNumber: String = ""
    @State private var shipDate: Date = Date()
    @State private var shippingCost: String = ""
    @State private var notes: String = ""
    @State private var showSaveError = false
    @FocusState private var focusedField: FocusField?

    enum FocusField: Hashable {
        case tracking, cost, notes
    }

    private struct ShippingPreset: Identifiable {
        let id = UUID()
        let label: String
        let cost: Double
    }

    private let shippingPresets: [ShippingPreset] = [
        ShippingPreset(label: "PWE", cost: 1.00),
        ShippingPreset(label: "Bubble Mailer", cost: 4.00),
        ShippingPreset(label: "Small Box", cost: 8.00),
        ShippingPreset(label: "Priority", cost: 15.00)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    cardHeader
                    carrierSection
                    trackingSection
                    shipDateSection
                    shippingCostSection
                    notesSection
                    confirmButton
                }
                .padding(DesignSystem.Spacing.sm)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Mark as Shipped")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { focusedField = nil }
                }
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("Try Again") { confirmShipped() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("The shipment could not be saved. Please try again.")
            }
        }
    }

    // MARK: - Card Header

    private var cardHeader: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.backgroundTertiary)
                    .frame(width: 50, height: 70)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(card.cardName)
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(card.setName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                if let soldPrice = card.soldPrice {
                    Text("Sold: $\(String(format: "%.2f", soldPrice))")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.success)
                }
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }

    // MARK: - Carrier Section

    private var carrierSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("CARRIER")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(ShippingCarrier.allCases, id: \.rawValue) { carrier in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCarrier = carrier
                            }
                        } label: {
                            Text(carrier.displayName)
                                .font(DesignSystem.Typography.captionBold)
                                .padding(.horizontal, DesignSystem.Spacing.xs)
                                .padding(.vertical, DesignSystem.Spacing.xxs)
                                .background(
                                    selectedCarrier == carrier
                                        ? DesignSystem.Colors.cyan.opacity(0.2)
                                        : DesignSystem.Colors.backgroundTertiary
                                )
                                .foregroundStyle(
                                    selectedCarrier == carrier
                                        ? DesignSystem.Colors.cyan
                                        : DesignSystem.Colors.textSecondary
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            selectedCarrier == carrier
                                                ? DesignSystem.Colors.cyan.opacity(0.5)
                                                : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Tracking Section

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("TRACKING NUMBER")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "barcode.viewfinder")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(width: 24)
                TextField("Enter tracking number", text: $trackingNumber)
                    .font(DesignSystem.Typography.body)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .focused($focusedField, equals: .tracking)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        focusedField == .tracking ? DesignSystem.Colors.electricBlue : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }

    // MARK: - Ship Date Section

    private var shipDateSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("SHIP DATE")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            DatePicker("Ship Date", selection: $shipDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(DesignSystem.Colors.cyan)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Shipping Cost Section

    private var shippingCostSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("SHIPPING COST")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            // Quick presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(shippingPresets) { preset in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                shippingCost = String(format: "%.2f", preset.cost)
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Text(preset.label)
                                    .font(DesignSystem.Typography.captionBold)
                                Text("$\(String(format: "%.0f", preset.cost))")
                                    .font(DesignSystem.Typography.captionSmall)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, DesignSystem.Spacing.xxs)
                            .background(
                                Double(shippingCost) == preset.cost
                                    ? DesignSystem.Colors.electricBlue.opacity(0.2)
                                    : DesignSystem.Colors.backgroundTertiary
                            )
                            .foregroundStyle(
                                Double(shippingCost) == preset.cost
                                    ? DesignSystem.Colors.electricBlue
                                    : DesignSystem.Colors.textSecondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                    .stroke(
                                        Double(shippingCost) == preset.cost
                                            ? DesignSystem.Colors.electricBlue.opacity(0.5)
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("$")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                TextField("0.00", text: $shippingCost)
                    .font(DesignSystem.Typography.heading3.monospacedDigit())
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .cost)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        focusedField == .cost ? DesignSystem.Colors.electricBlue : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("NOTES (OPTIONAL)")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            TextField("Shipping notes...", text: $notes, axis: .vertical)
                .font(DesignSystem.Typography.body)
                .lineLimit(3...6)
                .focused($focusedField, equals: .notes)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(
                            focusedField == .notes ? DesignSystem.Colors.electricBlue : Color.clear,
                            lineWidth: 2
                        )
                )
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            confirmShipped()
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: "paperplane.fill")
                    .font(.headline)
                Text("Confirm Shipped")
                    .font(DesignSystem.Typography.heading4)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cyan)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .padding(.top, DesignSystem.Spacing.xxs)
    }

    // MARK: - Confirm Shipped Action

    private func confirmShipped() {
        card.status = CardStatus.shipped.rawValue
        card.carrier = selectedCarrier.rawValue
        card.shippedDate = shipDate

        let trimmedTracking = trackingNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTracking.isEmpty {
            card.trackingNumber = trimmedTracking
        }

        // Try to update the related Transaction's tracking number
        if let cardId = Optional(card.id) {
            let predicate = #Predicate<Transaction> { $0.cardId == cardId }
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            if let transactions = try? modelContext.fetch(descriptor) {
                for transaction in transactions where transaction.transactionType == .sale {
                    if !trimmedTracking.isEmpty {
                        transaction.trackingNumber = trimmedTracking
                    }
                    let costValue = Double(shippingCost) ?? 0
                    if costValue > 0 && transaction.shippingCost == 0 {
                        transaction.shippingCost = costValue
                    }
                }
            }
        }

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save shipped status: \(error)")
            #endif
            showSaveError = true
        }
    }
}
