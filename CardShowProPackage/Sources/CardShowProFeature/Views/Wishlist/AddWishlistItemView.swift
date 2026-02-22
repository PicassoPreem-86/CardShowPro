import SwiftUI
import SwiftData

// MARK: - Add / Edit Wishlist Item View

struct AddWishlistItemView: View {
    var editingItem: WishlistItem?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var cardName = ""
    @State private var setName = ""
    @State private var cardNumber = ""
    @State private var selectedVariant: InventoryCardVariant?
    @State private var desiredCondition = "Near Mint"
    @State private var maxPriceText = ""
    @State private var selectedPriority: WishlistPriority = .medium
    @State private var notes = ""
    @State private var showSaveError = false

    private let conditions = ["Near Mint", "Lightly Played", "Moderately Played", "Heavily Played", "Damaged"]

    private var isEditing: Bool { editingItem != nil }

    private var canSave: Bool {
        !cardName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Card Name (required)
                    cardNameSection

                    // Set Name & Card Number
                    cardInfoSection

                    // Variant
                    variantSection

                    // Condition
                    conditionSection

                    // Max Price
                    maxPriceSection

                    // Priority
                    prioritySection

                    // Notes
                    notesSection
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle(isEditing ? "Edit Wishlist Item" : "Add to Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .onAppear {
                loadEditingItem()
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Could not save the wishlist item. Please try again.")
            }
        }
    }

    // MARK: - Card Name

    private var cardNameSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Text("CARD NAME")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text("*")
                    .foregroundStyle(DesignSystem.Colors.error)
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "rectangle.portrait.fill")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(width: 24)

                TextField("e.g. Charizard VMAX", text: $cardName)
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
    }

    // MARK: - Card Info

    private var cardInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("CARD INFO")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(width: 24)

                TextField("Set name (optional)", text: $setName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "number")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(width: 24)

                TextField("Card number (optional)", text: $cardNumber)
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
    }

    // MARK: - Variant

    private var variantSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("VARIANT")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    VariantChip(label: "Any", isSelected: selectedVariant == nil) {
                        selectedVariant = nil
                    }

                    ForEach(InventoryCardVariant.allCases, id: \.self) { variant in
                        VariantChip(label: variant.displayName, isSelected: selectedVariant == variant) {
                            selectedVariant = selectedVariant == variant ? nil : variant
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Condition

    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("DESIRED CONDITION")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(conditions, id: \.self) { condition in
                        Button {
                            desiredCondition = condition
                        } label: {
                            Text(condition)
                                .font(DesignSystem.Typography.label)
                                .foregroundStyle(
                                    desiredCondition == condition
                                        ? DesignSystem.Colors.backgroundPrimary
                                        : DesignSystem.Colors.textSecondary
                                )
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(
                                    desiredCondition == condition
                                        ? DesignSystem.Colors.cyan
                                        : DesignSystem.Colors.backgroundTertiary
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Max Price

    private var maxPriceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("MAX PRICE")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("$")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.success)

                TextField("No limit", text: $maxPriceText)
                    .font(DesignSystem.Typography.heading3.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Priority

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("PRIORITY")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: 0) {
                ForEach(WishlistPriority.allCases, id: \.self) { priority in
                    Button {
                        selectedPriority = priority
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xxxs) {
                            Image(systemName: priority.icon)
                                .font(.caption)
                            Text(priority.displayName)
                                .font(DesignSystem.Typography.labelLarge)
                        }
                        .foregroundStyle(
                            selectedPriority == priority
                                ? DesignSystem.Colors.backgroundPrimary
                                : DesignSystem.Colors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            selectedPriority == priority
                                ? priority.color
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Notes

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
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Actions

    private func loadEditingItem() {
        guard let item = editingItem else { return }
        cardName = item.cardName
        setName = item.setName ?? ""
        cardNumber = item.cardNumber ?? ""
        selectedVariant = item.variantType
        desiredCondition = item.desiredCondition ?? "Near Mint"
        if let price = item.maxPrice {
            maxPriceText = String(format: "%.2f", price)
        }
        selectedPriority = item.wishlistPriority
        notes = item.notes ?? ""
    }

    private func saveItem() {
        guard canSave else { return }

        let maxPrice = Double(maxPriceText)
        let trimmedName = cardName.trimmingCharacters(in: .whitespaces)

        if let item = editingItem {
            item.cardName = trimmedName
            item.setName = setName.isEmpty ? nil : setName
            item.cardNumber = cardNumber.isEmpty ? nil : cardNumber
            item.variant = selectedVariant?.rawValue
            item.desiredCondition = desiredCondition
            item.maxPrice = maxPrice
            item.priority = selectedPriority.rawValue
            item.notes = notes.isEmpty ? nil : notes
        } else {
            let item = WishlistItem(
                cardName: trimmedName,
                setName: setName.isEmpty ? nil : setName,
                cardNumber: cardNumber.isEmpty ? nil : cardNumber,
                variant: selectedVariant?.rawValue,
                desiredCondition: desiredCondition,
                maxPrice: maxPrice,
                priority: selectedPriority,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(item)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save wishlist item: \(error)")
            #endif
            showSaveError = true
        }
    }
}

// MARK: - Variant Chip

private struct VariantChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DesignSystem.Typography.label)
                .foregroundStyle(
                    isSelected
                        ? DesignSystem.Colors.backgroundPrimary
                        : DesignSystem.Colors.textSecondary
                )
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    isSelected
                        ? DesignSystem.Colors.electricBlue
                        : DesignSystem.Colors.backgroundTertiary
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Add Wishlist Item") {
    AddWishlistItemView()
        .modelContainer(for: WishlistItem.self, inMemory: true)
}
