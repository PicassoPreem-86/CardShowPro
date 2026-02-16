import SwiftUI
import SwiftData
import UIKit

// MARK: - Quick Buy View

/// Minimal sheet for rapid card acquisitions at a show.
/// Creates an InventoryCard and a purchase Transaction in one flow.
struct QuickBuyView: View {
    let eventName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var cardName = ""
    @State private var setName = ""
    @State private var cardNumber = ""
    @State private var costText = ""
    @State private var selectedCategory = "Raw Singles"
    @State private var selectedCondition = "Near Mint"
    @State private var showSuccess = false
    @State private var showSaveError = false
    @FocusState private var focusedField: Field?

    private let categories = ["Raw Singles", "Graded", "Sealed Product", "Supplies", "Other"]

    private let conditions: [String] = CardCondition.allCases.map(\.rawValue)

    enum Field: Hashable {
        case cardName, setName, cardNumber, cost
    }

    private var cost: Double {
        Double(costText) ?? 0
    }

    private var canConfirm: Bool {
        !cardName.isEmpty && cost > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Card Info
                    cardInfoSection

                    // Cost
                    costSection

                    // Category
                    categorySection

                    // Condition
                    conditionSection

                    // Confirm Button
                    confirmButton
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Quick Buy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The data could not be saved. Please try again.")
            }
        }
    }

    // MARK: - Card Info Section

    private var cardInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("CARD DETAILS")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                EventInputField(
                    icon: "rectangle.portrait.fill",
                    placeholder: "Card name *",
                    text: $cardName,
                    focusedField: $focusedField,
                    field: .cardName
                )

                EventInputField(
                    icon: "folder.fill",
                    placeholder: "Set name (optional)",
                    text: $setName,
                    focusedField: $focusedField,
                    field: .setName
                )

                EventInputField(
                    icon: "number",
                    placeholder: "Card number (optional)",
                    text: $cardNumber,
                    focusedField: $focusedField,
                    field: .cardNumber
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Cost Section

    private var costSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("PURCHASE COST")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("$")
                    .font(DesignSystem.Typography.displaySmall)
                    .foregroundStyle(DesignSystem.Colors.electricBlue)

                TextField("0.00", text: $costText)
                    .font(DesignSystem.Typography.displaySmall.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .cost)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .stroke(
                        focusedField == .cost
                            ? DesignSystem.Colors.electricBlue
                            : DesignSystem.Colors.borderPrimary,
                        lineWidth: focusedField == .cost ? 2 : 1
                    )
            )
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("CATEGORY")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            title: category,
                            icon: iconForCategory(category),
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(DesignSystem.Animation.springSnappy) {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Raw Singles": return "rectangle.portrait.fill"
        case "Graded": return "shield.checkered"
        case "Sealed Product": return "shippingbox.fill"
        case "Supplies": return "archivebox.fill"
        case "Other": return "ellipsis.circle.fill"
        default: return "questionmark.circle"
        }
    }

    // MARK: - Condition Section

    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("CONDITION")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(conditions, id: \.self) { condition in
                        ConditionChip(
                            title: condition,
                            isSelected: selectedCondition == condition
                        ) {
                            withAnimation(DesignSystem.Animation.springSnappy) {
                                selectedCondition = condition
                            }
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            confirmPurchase()
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add to Inventory")
                    .font(DesignSystem.Typography.labelLarge)
            }
            .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(canConfirm ? DesignSystem.Colors.electricBlue : DesignSystem.Colors.textDisabled)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .disabled(!canConfirm)
        .accessibilityLabel("Add card to inventory for \(cost.asCurrency)")
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.electricBlue)

            Text("Added to Inventory!")
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(cardName)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundPrimary.opacity(0.95))
        .transition(.opacity)
    }

    // MARK: - Confirm Purchase Logic

    private func confirmPurchase() {
        guard canConfirm else { return }

        // Normalize category for InventoryCard storage
        let storedCategory: String
        switch selectedCategory {
        case "Sealed Product": storedCategory = "Sealed"
        case "Supplies", "Other": storedCategory = "Misc"
        default: storedCategory = selectedCategory
        }

        // Create inventory card
        let newCard = InventoryCard(
            cardName: cardName,
            cardNumber: cardNumber,
            setName: setName,
            estimatedValue: cost,
            confidence: 0.5,
            timestamp: Date(),
            purchaseCost: cost,
            category: storedCategory,
            condition: selectedCondition,
            status: CardStatus.inStock.rawValue,
            acquisitionSource: AcquisitionSource.eventShow.rawValue
        )
        newCard.acquisitionDate = Date()
        modelContext.insert(newCard)

        // Create purchase transaction
        let transaction = Transaction(
            type: .purchase,
            date: Date(),
            amount: cost,
            platform: "Event/Show",
            cardId: newCard.id,
            cardName: cardName,
            cardSetName: setName,
            eventName: eventName,
            costBasis: cost
        )
        modelContext.insert(transaction)

        do {
            try modelContext.save()
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            // Show success then dismiss
            withAnimation(.easeInOut(duration: DesignSystem.Animation.fast)) {
                showSuccess = true
            }

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.2))
                dismiss()
            }
        } catch {
            #if DEBUG
            print("QuickBuyView save failed: \(error)")
            #endif
            showSaveError = true
        }
    }
}

// MARK: - Event Input Field

private struct EventInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var focusedField: QuickBuyView.Field?
    let field: QuickBuyView.Field

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
                    focusedField == field ? DesignSystem.Colors.electricBlue : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(DesignSystem.Typography.label)
            }
            .foregroundStyle(isSelected ? DesignSystem.Colors.backgroundPrimary : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(isSelected ? DesignSystem.Colors.electricBlue : DesignSystem.Colors.backgroundTertiary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Condition Chip

private struct ConditionChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(DesignSystem.Typography.label)
                .foregroundStyle(isSelected ? DesignSystem.Colors.backgroundPrimary : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(isSelected ? DesignSystem.Colors.thunderYellow : DesignSystem.Colors.backgroundTertiary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) condition")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Quick Buy") {
    QuickBuyView(eventName: "Portland Card Show")
}
