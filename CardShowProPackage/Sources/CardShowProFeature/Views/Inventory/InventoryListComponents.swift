import SwiftUI

// MARK: - Category Pill
struct CategoryPill: View {
    let category: CardCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? category.color : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Profit Badge Component
struct ProfitBadge: View {
    let profit: Double
    let roi: Double

    private var profitColor: Color {
        if profit > 0 {
            return DesignSystem.Colors.success
        } else if profit < 0 {
            return DesignSystem.Colors.error
        } else {
            return DesignSystem.Colors.textSecondary
        }
    }

    private var profitIcon: String {
        profit >= 0 ? "arrow.up.right" : "arrow.down.right"
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: profitIcon)
                .font(.caption2)
            Text("$\(String(format: "%.0f", abs(profit)))")
                .font(.caption)
                .fontWeight(.semibold)
            Text("(\(String(format: "%.0f", roi))%)")
                .font(.caption2)
        }
        .foregroundStyle(profitColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(profitColor.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profit >= 0 ? "Profit" : "Loss") $\(String(format: "%.0f", abs(profit))), \(String(format: "%.0f", roi))% ROI")
    }
}

// MARK: - Inventory Stat Box Component
struct InventoryStatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Sort Options Sheet
struct SortOptionsSheet: View {
    @Binding var selectedOption: CardListView.SortOption
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(CardListView.SortOption.allCases, id: \.self) { option in
                    Button {
                        selectedOption = option
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.rawValue)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Spacer()
                            if selectedOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignSystem.Colors.cyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.cyan)
                }
            }
        }
    }
}

// MARK: - Filter Options Sheet
struct FilterOptionsSheet: View {
    @Binding var selectedFilter: CardListView.ProfitFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(CardListView.ProfitFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(filter.rawValue)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                if let description = filterDescription(for: filter) {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                                }
                            }
                            Spacer()
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignSystem.Colors.cyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.cyan)
                }
            }
        }
    }

    private func filterDescription(for filter: CardListView.ProfitFilter) -> String? {
        switch filter {
        case .all:
            return nil
        case .profitable:
            return "Cards with positive profit"
        case .unprofitable:
            return "Cards with negative profit"
        case .noCost:
            return "Cards without purchase cost"
        case .highROI:
            return "Return over 100%"
        case .mediumROI:
            return "Return 50-100%"
        case .lowROI:
            return "Return under 50%"
        }
    }
}

// MARK: - CardCategory Extension for Identifiable
extension CardCategory: Identifiable {
    var id: String { rawValue }
}

// MARK: - Confidence Helper Functions
func confidenceColor(for confidence: Double) -> Color {
    switch confidence {
    case 0.9...1.0: return DesignSystem.Colors.success
    case 0.75..<0.9: return DesignSystem.Colors.electricBlue
    case 0.5..<0.75: return DesignSystem.Colors.warning
    default: return DesignSystem.Colors.error
    }
}

func confidenceIcon(for confidence: Double) -> String {
    switch confidence {
    case 0.9...1.0: return "checkmark.seal.fill"
    case 0.75..<0.9: return "checkmark.circle.fill"
    case 0.5..<0.75: return "exclamationmark.triangle.fill"
    default: return "xmark.octagon.fill"
    }
}
