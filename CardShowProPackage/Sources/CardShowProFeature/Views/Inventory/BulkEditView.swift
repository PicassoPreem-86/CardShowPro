import SwiftUI
import SwiftData

struct BulkEditView: View {
    let cards: [InventoryCard]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Editable fields (nil = no change)
    @State private var selectedCategory: CardCategory?
    @State private var selectedCondition: CardCondition?
    @State private var selectedVariant: InventoryCardVariant?
    @State private var tagsToAdd: String = ""
    @State private var tagsToRemove: String = ""
    @State private var storageLocation: String = ""
    @State private var notesToAppend: String = ""

    // Market value adjustment
    @State private var adjustmentMode: AdjustmentMode = .none
    @State private var adjustmentValue: String = ""

    @State private var showConfirmation = false
    @State private var showSaveError = false

    enum AdjustmentMode: String, CaseIterable {
        case none = "No Change"
        case fixedIncrease = "+ Fixed $"
        case fixedDecrease = "- Fixed $"
        case percentIncrease = "+ Percent %"
        case percentDecrease = "- Percent %"
    }

    private var hasChanges: Bool {
        selectedCategory != nil ||
        selectedCondition != nil ||
        selectedVariant != nil ||
        !tagsToAdd.trimmingCharacters(in: .whitespaces).isEmpty ||
        !tagsToRemove.trimmingCharacters(in: .whitespaces).isEmpty ||
        !storageLocation.trimmingCharacters(in: .whitespaces).isEmpty ||
        !notesToAppend.trimmingCharacters(in: .whitespaces).isEmpty ||
        (adjustmentMode != .none && !(adjustmentValue.trimmingCharacters(in: .whitespaces).isEmpty))
    }

    private var changeSummary: [String] {
        var changes: [String] = []
        if let cat = selectedCategory {
            changes.append("Category -> \(cat.rawValue)")
        }
        if let cond = selectedCondition {
            changes.append("Condition -> \(cond.rawValue)")
        }
        if let variant = selectedVariant {
            changes.append("Variant -> \(variant.rawValue)")
        }
        let addTags = tagsToAdd.trimmingCharacters(in: .whitespaces)
        if !addTags.isEmpty {
            changes.append("Add tags: \(addTags)")
        }
        let removeTags = tagsToRemove.trimmingCharacters(in: .whitespaces)
        if !removeTags.isEmpty {
            changes.append("Remove tags: \(removeTags)")
        }
        let loc = storageLocation.trimmingCharacters(in: .whitespaces)
        if !loc.isEmpty {
            changes.append("Storage -> \(loc)")
        }
        let notes = notesToAppend.trimmingCharacters(in: .whitespaces)
        if !notes.isEmpty {
            changes.append("Append notes: \"\(notes)\"")
        }
        if adjustmentMode != .none, let val = Double(adjustmentValue), val > 0 {
            switch adjustmentMode {
            case .fixedIncrease: changes.append("Market value +$\(String(format: "%.2f", val))")
            case .fixedDecrease: changes.append("Market value -$\(String(format: "%.2f", val))")
            case .percentIncrease: changes.append("Market value +\(String(format: "%.1f", val))%")
            case .percentDecrease: changes.append("Market value -\(String(format: "%.1f", val))%")
            case .none: break
            }
        }
        return changes
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    headerSection
                    categorySection
                    conditionSection
                    variantSection
                    tagsSection
                    storageSection
                    valueAdjustmentSection
                    notesSection

                    if !changeSummary.isEmpty {
                        previewSection
                    }

                    applyButton
                }
                .padding(DesignSystem.Spacing.sm)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Bulk Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }
            }
            .alert("Apply Changes?", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Apply") { applyChanges() }
            } message: {
                Text("This will update \(cards.count) card(s). This cannot be undone.")
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Changes could not be saved. Please try again.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "pencil.and.list.clipboard")
                .font(.title2)
                .foregroundStyle(DesignSystem.Colors.cyan)

            VStack(alignment: .leading, spacing: 2) {
                Text("Editing \(cards.count) card\(cards.count == 1 ? "" : "s")")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Only changed fields will be applied")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            sectionLabel("CATEGORY")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    clearablePill("No Change", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(CardCategory.allCases.filter { $0 != .allProduct }, id: \.self) { cat in
                        clearablePill(cat.rawValue, isSelected: selectedCategory == cat) {
                            selectedCategory = cat
                        }
                    }
                }
            }
        }
    }

    // MARK: - Condition

    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            sectionLabel("CONDITION")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    clearablePill("No Change", isSelected: selectedCondition == nil) {
                        selectedCondition = nil
                    }
                    ForEach(CardCondition.allCases, id: \.self) { cond in
                        clearablePill(cond.rawValue, isSelected: selectedCondition == cond) {
                            selectedCondition = cond
                        }
                    }
                }
            }
        }
    }

    // MARK: - Variant

    private var variantSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            sectionLabel("VARIANT")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    clearablePill("No Change", isSelected: selectedVariant == nil) {
                        selectedVariant = nil
                    }
                    ForEach(InventoryCardVariant.allCases, id: \.self) { v in
                        clearablePill(v.rawValue, isSelected: selectedVariant == v) {
                            selectedVariant = v
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            sectionLabel("TAGS")

            VStack(spacing: DesignSystem.Spacing.xs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.success)
                        .frame(width: 24)
                    TextField("Add tags (comma-separated)", text: $tagsToAdd)
                        .font(DesignSystem.Typography.body)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.error)
                        .frame(width: 24)
                    TextField("Remove tags (comma-separated)", text: $tagsToRemove)
                        .font(DesignSystem.Typography.body)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Storage

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            sectionLabel("STORAGE LOCATION")

            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "archivebox.fill")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(width: 24)
                TextField("Set storage location", text: $storageLocation)
                    .font(DesignSystem.Typography.body)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Value Adjustment

    private var valueAdjustmentSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            sectionLabel("MARKET VALUE ADJUSTMENT")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(AdjustmentMode.allCases, id: \.self) { mode in
                        clearablePill(mode.rawValue, isSelected: adjustmentMode == mode) {
                            adjustmentMode = mode
                            if mode == .none { adjustmentValue = "" }
                        }
                    }
                }
            }

            if adjustmentMode != .none {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(adjustmentMode == .percentIncrease || adjustmentMode == .percentDecrease ? "%" : "$")
                        .font(DesignSystem.Typography.heading3)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    TextField("0", text: $adjustmentValue)
                        .font(DesignSystem.Typography.heading3.monospacedDigit())
                        .keyboardType(.decimalPad)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            sectionLabel("APPEND TO NOTES")

            TextField("Text to append to existing notes", text: $notesToAppend, axis: .vertical)
                .font(DesignSystem.Typography.body)
                .lineLimit(3...6)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            sectionLabel("CHANGES PREVIEW")

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                ForEach(changeSummary, id: \.self) { change in
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.cyan)
                        Text(change)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.cyan.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.cyan.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Apply Button

    private var applyButton: some View {
        Button {
            showConfirmation = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.headline)
                Text("Apply Changes")
                    .font(DesignSystem.Typography.heading4)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.sm)
            .background(hasChanges ? DesignSystem.Colors.cyan : DesignSystem.Colors.cyan.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .disabled(!hasChanges)
        .padding(.top, DesignSystem.Spacing.xxs)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.captionBold)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
    }

    private func clearablePill(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.captionBold)
                .padding(.horizontal, DesignSystem.Spacing.xs)
                .padding(.vertical, DesignSystem.Spacing.xxs)
                .background(
                    isSelected
                        ? DesignSystem.Colors.cyan.opacity(0.2)
                        : DesignSystem.Colors.backgroundTertiary
                )
                .foregroundStyle(
                    isSelected
                        ? DesignSystem.Colors.cyan
                        : DesignSystem.Colors.textSecondary
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? DesignSystem.Colors.cyan.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Apply Changes

    private func applyChanges() {
        for card in cards {
            if let cat = selectedCategory {
                card.category = cat.rawValue
            }
            if let cond = selectedCondition {
                card.condition = cond.rawValue
            }
            if let variant = selectedVariant {
                card.variant = variant.rawValue
            }

            // Tags: add
            let addTags = tagsToAdd.trimmingCharacters(in: .whitespaces)
            if !addTags.isEmpty {
                let newTags = addTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                var existing = card.tagsArray
                for tag in newTags where !tag.isEmpty && !existing.contains(tag) {
                    existing.append(tag)
                }
                card.tags = existing.joined(separator: ", ")
            }

            // Tags: remove
            let removeTags = tagsToRemove.trimmingCharacters(in: .whitespaces)
            if !removeTags.isEmpty {
                let toRemove = Set(removeTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() })
                let filtered = card.tagsArray.filter { !toRemove.contains($0.lowercased()) }
                card.tags = filtered.isEmpty ? nil : filtered.joined(separator: ", ")
            }

            // Storage location
            let loc = storageLocation.trimmingCharacters(in: .whitespaces)
            if !loc.isEmpty {
                card.storageLocation = loc
            }

            // Notes
            let notes = notesToAppend.trimmingCharacters(in: .whitespaces)
            if !notes.isEmpty {
                if card.notes.isEmpty {
                    card.notes = notes
                } else {
                    card.notes += "\n\(notes)"
                }
            }

            // Market value adjustment
            if adjustmentMode != .none, let val = Double(adjustmentValue), val > 0 {
                switch adjustmentMode {
                case .fixedIncrease:
                    card.estimatedValue += val
                case .fixedDecrease:
                    card.estimatedValue = max(0, card.estimatedValue - val)
                case .percentIncrease:
                    card.estimatedValue *= (1 + val / 100)
                case .percentDecrease:
                    card.estimatedValue *= max(0, 1 - val / 100)
                case .none:
                    break
                }
            }
        }

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save bulk edit: \(error)")
            #endif
            showSaveError = true
        }
    }
}
