import SwiftUI
import SwiftData

struct ReturnCardView: View {
    let card: InventoryCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedReason: ReturnReason = .buyerChangedMind
    @State private var refundAmount: String = ""
    @State private var returnToStock: Bool = true
    @State private var notes: String = ""
    @State private var showSaveError = false
    @FocusState private var focusedField: FocusField?

    enum FocusField: Hashable {
        case refund, notes
    }

    enum ReturnReason: String, CaseIterable, Identifiable {
        case buyerChangedMind = "Buyer Changed Mind"
        case itemNotAsDescribed = "Item Not As Described"
        case damagedInShipping = "Damaged in Shipping"
        case wrongItemSent = "Wrong Item Sent"
        case other = "Other"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .buyerChangedMind: return "person.fill.questionmark"
            case .itemNotAsDescribed: return "exclamationmark.triangle.fill"
            case .damagedInShipping: return "shippingbox.and.arrow.backward.fill"
            case .wrongItemSent: return "arrow.triangle.swap"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }

    private var refundValue: Double {
        Double(refundAmount) ?? 0
    }

    private var canConfirm: Bool {
        refundValue > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    cardHeader
                    reasonSection
                    refundSection
                    returnToStockToggle
                    notesSection
                    confirmButton
                }
                .padding(DesignSystem.Spacing.sm)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Process Return")
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
            .onAppear {
                if let soldPrice = card.soldPrice {
                    refundAmount = String(format: "%.2f", soldPrice)
                }
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("Try Again") { confirmReturn() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("The return could not be saved. Please try again.")
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

    // MARK: - Reason Section

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("RETURN REASON")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            VStack(spacing: DesignSystem.Spacing.xxs) {
                ForEach(ReturnReason.allCases) { reason in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedReason = reason
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: reason.icon)
                                .font(.subheadline)
                                .frame(width: 24)
                            Text(reason.rawValue)
                                .font(DesignSystem.Typography.body)
                            Spacer()
                            if selectedReason == reason {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DesignSystem.Colors.cyan)
                            }
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(
                            selectedReason == reason
                                ? DesignSystem.Colors.cyan.opacity(0.1)
                                : DesignSystem.Colors.backgroundSecondary
                        )
                        .foregroundStyle(
                            selectedReason == reason
                                ? DesignSystem.Colors.cyan
                                : DesignSystem.Colors.textPrimary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .stroke(
                                    selectedReason == reason
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

    // MARK: - Refund Section

    private var refundSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            HStack {
                Text("REFUND AMOUNT")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
                if let soldPrice = card.soldPrice, refundValue < soldPrice {
                    Text("Partial Refund")
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.warning)
                }
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("$")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                TextField("0.00", text: $refundAmount)
                    .font(DesignSystem.Typography.heading2.monospacedDigit())
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .refund)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        focusedField == .refund ? DesignSystem.Colors.error : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }

    // MARK: - Return to Stock Toggle

    private var returnToStockToggle: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Toggle(isOn: $returnToStock) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Return to Stock")
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(returnToStock
                         ? "Card will be available for sale again"
                         : "Card will be marked as Returned"
                    )
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .tint(DesignSystem.Colors.cyan)
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("NOTES (OPTIONAL)")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            TextField("Return details...", text: $notes, axis: .vertical)
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
            confirmReturn()
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.headline)
                Text("Process Return")
                    .font(DesignSystem.Typography.heading4)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.sm)
            .background(canConfirm ? DesignSystem.Colors.error : DesignSystem.Colors.error.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .disabled(!canConfirm)
        .padding(.top, DesignSystem.Spacing.xxs)
    }

    // MARK: - Confirm Return Action

    private func confirmReturn() {
        let reasonText = selectedReason.rawValue
        let fullNotes = notes.isEmpty ? reasonText : "\(reasonText): \(notes)"

        // Create refund transaction
        let refundTransaction = Transaction.recordRefund(
            for: card,
            amount: refundValue,
            reason: fullNotes,
            platform: card.platform
        )
        modelContext.insert(refundTransaction)

        // Update card
        card.returnReason = reasonText
        card.refundAmount = refundValue
        card.refundDate = Date()

        if returnToStock {
            card.status = CardStatus.inStock.rawValue
            card.soldPrice = nil
            card.soldDate = nil
            card.platform = nil
            card.trackingNumber = nil
            card.carrier = nil
            card.shippedDate = nil
        } else {
            card.status = CardStatus.returned.rawValue
        }

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save return: \(error)")
            #endif
            showSaveError = true
        }
    }
}
