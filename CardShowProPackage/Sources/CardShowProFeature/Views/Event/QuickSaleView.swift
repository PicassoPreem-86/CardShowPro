import SwiftUI
import SwiftData
import UIKit

// MARK: - Quick Sale View

/// Minimal sheet for rapid cash sales at a card show.
/// Supports picking from inventory or manual entry for maximum speed.
struct QuickSaleView: View {
    let eventName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<InventoryCard> { card in
            card.status == "In Stock"
        },
        sort: \InventoryCard.cardName
    )
    private var inStockCards: [InventoryCard]

    @State private var selectedCard: InventoryCard?
    @State private var isManualEntry = false
    @State private var manualCardName = ""
    @State private var salePriceText = ""
    @State private var selectedPaymentMethod = "Cash"
    @State private var searchText = ""
    @State private var showSuccess = false
    @FocusState private var focusedField: Field?

    private let paymentMethods = ["Cash", "Venmo", "Card", "Zelle", "Other"]

    enum Field: Hashable {
        case search, cardName, salePrice
    }

    private var filteredCards: [InventoryCard] {
        if searchText.isEmpty {
            return inStockCards
        }
        let query = searchText.lowercased()
        return inStockCards.filter {
            $0.cardName.lowercased().contains(query) ||
            $0.setName.lowercased().contains(query)
        }
    }

    private var salePrice: Double {
        Double(salePriceText) ?? 0
    }

    private var canConfirm: Bool {
        salePrice > 0 && (selectedCard != nil || (!manualCardName.isEmpty && isManualEntry))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Mode Toggle
                    modeToggle

                    // Card Selection or Manual Entry
                    if isManualEntry {
                        manualEntrySection
                    } else {
                        cardSelectionSection
                    }

                    // Sale Price
                    salePriceSection

                    // Payment Method
                    paymentMethodSection

                    // Confirm Button
                    confirmButton
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Quick Sale")
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
        }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(title: "From Inventory", isSelected: !isManualEntry) {
                withAnimation(DesignSystem.Animation.springSnappy) {
                    isManualEntry = false
                    manualCardName = ""
                }
            }

            modeButton(title: "Manual Entry", isSelected: isManualEntry) {
                withAnimation(DesignSystem.Animation.springSnappy) {
                    isManualEntry = true
                    selectedCard = nil
                }
            }
        }
        .background(DesignSystem.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }

    private func modeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(isSelected ? DesignSystem.Colors.backgroundPrimary : DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(isSelected ? DesignSystem.Colors.cyan : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card Selection

    private var cardSelectionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("SELECT CARD")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            // Search Bar
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                TextField("Search inventory...", text: $searchText)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .focused($focusedField, equals: .search)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

            // Card List
            if filteredCards.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    Text(searchText.isEmpty ? "No cards in stock" : "No matching cards")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xl)
            } else {
                VStack(spacing: DesignSystem.Spacing.xxxs) {
                    ForEach(filteredCards.prefix(10), id: \.id) { card in
                        CardPickerRow(
                            card: card,
                            isSelected: selectedCard?.id == card.id
                        ) {
                            withAnimation(DesignSystem.Animation.springSnappy) {
                                selectedCard = card
                            }
                        }
                    }
                    if filteredCards.count > 10 {
                        Text("\(filteredCards.count - 10) more results...")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .padding(.top, DesignSystem.Spacing.xs)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Manual Entry

    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("CARD DETAILS")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "rectangle.portrait.fill")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(width: 24)

                TextField("Card name", text: $manualCardName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .focused($focusedField, equals: .cardName)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Sale Price

    private var salePriceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("SALE PRICE")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("$")
                    .font(DesignSystem.Typography.displaySmall)
                    .foregroundStyle(DesignSystem.Colors.success)

                TextField("0.00", text: $salePriceText)
                    .font(DesignSystem.Typography.displaySmall.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .salePrice)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .stroke(
                        focusedField == .salePrice
                            ? DesignSystem.Colors.success
                            : DesignSystem.Colors.borderPrimary,
                        lineWidth: focusedField == .salePrice ? 2 : 1
                    )
            )
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Payment Method

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("PAYMENT METHOD")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(paymentMethods, id: \.self) { method in
                        PaymentMethodChip(
                            title: method,
                            icon: iconForPaymentMethod(method),
                            isSelected: selectedPaymentMethod == method
                        ) {
                            withAnimation(DesignSystem.Animation.springSnappy) {
                                selectedPaymentMethod = method
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

    private func iconForPaymentMethod(_ method: String) -> String {
        switch method {
        case "Cash": return "banknote.fill"
        case "Venmo": return "iphone.gen3"
        case "Card": return "creditcard.fill"
        case "Zelle": return "arrow.left.arrow.right"
        case "Other": return "ellipsis.circle.fill"
        default: return "questionmark.circle"
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            confirmSale()
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                Text("Confirm Sale")
                    .font(DesignSystem.Typography.labelLarge)
            }
            .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(canConfirm ? DesignSystem.Colors.success : DesignSystem.Colors.textDisabled)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .disabled(!canConfirm)
        .accessibilityLabel("Confirm sale for \(salePrice.asCurrency)")
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.success)

            Text("Sale Recorded!")
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(salePrice.asCurrency)
                .font(DesignSystem.Typography.displaySmall.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.success)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundPrimary.opacity(0.95))
        .transition(.opacity)
    }

    // MARK: - Confirm Sale Logic

    private func confirmSale() {
        guard canConfirm else { return }

        if let card = selectedCard {
            // Sale from existing inventory
            let transaction = Transaction.recordSale(
                card: card,
                salePrice: salePrice,
                platform: selectedPaymentMethod,
                fees: 0,
                shipping: 0,
                eventName: eventName
            )
            modelContext.insert(transaction)

            card.status = CardStatus.sold.rawValue
            card.soldPrice = salePrice
            card.soldDate = Date()
        } else {
            // Manual entry sale
            let transaction = Transaction(
                type: .sale,
                date: Date(),
                amount: salePrice,
                platform: selectedPaymentMethod,
                platformFees: 0,
                shippingCost: 0,
                cardName: manualCardName,
                cardSetName: "",
                eventName: eventName
            )
            modelContext.insert(transaction)
        }

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
    }
}

// MARK: - Card Picker Row

private struct CardPickerRow: View {
    let card: InventoryCard
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
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

                if let cost = card.purchaseCost {
                    Text("Cost: \(cost.asCurrency)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.cyan : DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(isSelected ? DesignSystem.Colors.cyan.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(card.cardName) from \(card.setName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Payment Method Chip

private struct PaymentMethodChip: View {
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
            .background(isSelected ? DesignSystem.Colors.cyan : DesignSystem.Colors.backgroundTertiary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) payment method")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Quick Sale") {
    QuickSaleView(eventName: "Portland Card Show")
}
