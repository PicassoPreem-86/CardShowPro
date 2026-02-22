import SwiftUI

// MARK: - Inventory Filters

struct InventoryFilters: Codable {
    var minPrice: Double?
    var maxPrice: Double?
    var dateFrom: Date?
    var dateTo: Date?
    var conditions: Set<String> = []
    var variants: Set<String> = []
    var gradingServices: Set<String> = []
    var acquisitionSources: Set<String> = []

    var hasActiveFilters: Bool {
        minPrice != nil || maxPrice != nil ||
        dateFrom != nil || dateTo != nil ||
        !conditions.isEmpty || !variants.isEmpty ||
        !gradingServices.isEmpty || !acquisitionSources.isEmpty
    }

    var activeFilterCount: Int {
        var count = 0
        if minPrice != nil { count += 1 }
        if maxPrice != nil { count += 1 }
        if dateFrom != nil { count += 1 }
        if dateTo != nil { count += 1 }
        count += conditions.count
        count += variants.count
        count += gradingServices.count
        count += acquisitionSources.count
        return count
    }

    mutating func reset() {
        minPrice = nil
        maxPrice = nil
        dateFrom = nil
        dateTo = nil
        conditions = []
        variants = []
        gradingServices = []
        acquisitionSources = []
    }
}

// MARK: - Advanced Filter View

struct AdvancedFilterView: View {
    @Binding var filters: InventoryFilters
    @Environment(\.dismiss) private var dismiss

    // Local editing state
    @State private var minPriceText = ""
    @State private var maxPriceText = ""
    @State private var dateFrom: Date?
    @State private var dateTo: Date?
    @State private var selectedConditions: Set<String> = []
    @State private var selectedVariants: Set<String> = []
    @State private var selectedGradingServices: Set<String> = []
    @State private var selectedAcquisitionSources: Set<String> = []
    @State private var showDateFrom = false
    @State private var showDateTo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Active filter count
                    if localFilterCount > 0 {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .foregroundStyle(.cyan)
                            Text("\(localFilterCount) filter\(localFilterCount == 1 ? "" : "s") active")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.cyan)
                            Spacer()
                            Button("Clear All") {
                                clearAll()
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.error)
                        }
                        .padding()
                        .background(Color.cyan.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    }

                    // Price Range
                    filterSection(title: "PRICE RANGE") {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 2) {
                                    Text("$")
                                        .foregroundStyle(.secondary)
                                    TextField("0", text: $minPriceText)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Max")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 2) {
                                    Text("$")
                                        .foregroundStyle(.secondary)
                                    TextField("999", text: $maxPriceText)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                    }

                    // Date Range
                    filterSection(title: "DATE RANGE") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("From")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let from = dateFrom {
                                    Button {
                                        dateFrom = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    DatePicker("", selection: Binding(
                                        get: { from },
                                        set: { dateFrom = $0 }
                                    ), displayedComponents: .date)
                                    .labelsHidden()
                                } else {
                                    Button("Set Date") {
                                        dateFrom = Calendar.current.date(byAdding: .month, value: -1, to: Date())
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.cyan)
                                }
                            }

                            Divider()

                            HStack {
                                Text("To")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let to = dateTo {
                                    Button {
                                        dateTo = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    DatePicker("", selection: Binding(
                                        get: { to },
                                        set: { dateTo = $0 }
                                    ), displayedComponents: .date)
                                    .labelsHidden()
                                } else {
                                    Button("Set Date") {
                                        dateTo = Date()
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.cyan)
                                }
                            }
                        }
                    }

                    // Condition
                    filterSection(title: "CONDITION") {
                        chipGrid(
                            items: CardCondition.allCases.map(\.rawValue),
                            selected: $selectedConditions,
                            color: .cyan
                        )
                    }

                    // Variant
                    filterSection(title: "VARIANT") {
                        chipGrid(
                            items: InventoryCardVariant.allCases.map(\.rawValue),
                            selected: $selectedVariants,
                            color: .purple
                        )
                    }

                    // Grading Service
                    filterSection(title: "GRADING SERVICE") {
                        chipGrid(
                            items: GradingService.allCases.map(\.rawValue),
                            selected: $selectedGradingServices,
                            color: DesignSystem.Colors.thunderYellow
                        )
                    }

                    // Acquisition Source
                    filterSection(title: "ACQUISITION SOURCE") {
                        chipGrid(
                            items: AcquisitionSource.allCases.map(\.rawValue),
                            selected: $selectedAcquisitionSources,
                            color: .orange
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.cyan)
                }
            }
            .onAppear {
                loadFilters()
            }
        }
    }

    // MARK: - Components

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            content()
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    private func chipGrid(items: [String], selected: Binding<Set<String>>, color: Color) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                let isSelected = selected.wrappedValue.contains(item)
                Button {
                    if isSelected {
                        selected.wrappedValue.remove(item)
                    } else {
                        selected.wrappedValue.insert(item)
                    }
                } label: {
                    Text(item)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? color : Color(.systemGray5))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Computed

    private var localFilterCount: Int {
        var count = 0
        if !minPriceText.isEmpty, Double(minPriceText) != nil { count += 1 }
        if !maxPriceText.isEmpty, Double(maxPriceText) != nil { count += 1 }
        if dateFrom != nil { count += 1 }
        if dateTo != nil { count += 1 }
        count += selectedConditions.count
        count += selectedVariants.count
        count += selectedGradingServices.count
        count += selectedAcquisitionSources.count
        return count
    }

    // MARK: - Actions

    private func loadFilters() {
        if let min = filters.minPrice {
            minPriceText = String(format: "%.2f", min)
        }
        if let max = filters.maxPrice {
            maxPriceText = String(format: "%.2f", max)
        }
        dateFrom = filters.dateFrom
        dateTo = filters.dateTo
        selectedConditions = filters.conditions
        selectedVariants = filters.variants
        selectedGradingServices = filters.gradingServices
        selectedAcquisitionSources = filters.acquisitionSources
    }

    private func applyFilters() {
        filters.minPrice = Double(minPriceText)
        filters.maxPrice = Double(maxPriceText)
        filters.dateFrom = dateFrom
        filters.dateTo = dateTo
        filters.conditions = selectedConditions
        filters.variants = selectedVariants
        filters.gradingServices = selectedGradingServices
        filters.acquisitionSources = selectedAcquisitionSources
        dismiss()
    }

    private func clearAll() {
        minPriceText = ""
        maxPriceText = ""
        dateFrom = nil
        dateTo = nil
        selectedConditions = []
        selectedVariants = []
        selectedGradingServices = []
        selectedAcquisitionSources = []
    }
}

// MARK: - Flow Layout (wrapping horizontal chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, containerWidth: proposal.width ?? .infinity)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, containerWidth: bounds.width)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func layout(subviews: Subviews, containerWidth: CGFloat) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > containerWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
