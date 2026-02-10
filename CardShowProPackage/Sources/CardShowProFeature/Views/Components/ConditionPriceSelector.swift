import SwiftUI

/// A segmented control for selecting card condition with price display
public struct ConditionPriceSelector: View {
    @Binding var selectedCondition: PriceCondition
    let conditionPrices: ConditionPrices?
    let priceChange7d: Double?
    let onPriceHistoryTap: (() -> Void)?

    init(
        selectedCondition: Binding<PriceCondition>,
        conditionPrices: ConditionPrices?,
        priceChange7d: Double? = nil,
        onPriceHistoryTap: (() -> Void)? = nil
    ) {
        self._selectedCondition = selectedCondition
        self.conditionPrices = conditionPrices
        self.priceChange7d = priceChange7d
        self.onPriceHistoryTap = onPriceHistoryTap
    }

    private var currentPrice: Double? {
        conditionPrices?.price(for: selectedCondition)
    }

    private var trend: PriceTrend {
        guard let change = priceChange7d else { return .stable }
        if change > 2.0 { return .rising }
        if change < -2.0 { return .falling }
        return .stable
    }

    public var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Condition Picker
            conditionPicker

            // Price Display with Trend
            if let price = currentPrice {
                priceDisplay(price: price)
            } else if conditionPrices == nil {
                estimatedPriceNote
            }

            // Price History Button
            if onPriceHistoryTap != nil {
                priceHistoryButton
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.borderPrimary, lineWidth: 1)
        )
    }

    // MARK: - Subviews

    private var conditionPicker: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Card Condition")
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(PriceCondition.allCases) { condition in
                        ConditionPill(
                            condition: condition,
                            isSelected: selectedCondition == condition,
                            price: conditionPrices?.price(for: condition),
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCondition = condition
                                    HapticManager.shared.selection()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func priceDisplay(price: Double) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.sm) {
                // Price
                Text("$\(price, specifier: "%.2f")")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                // Trend Badge
                if let change = priceChange7d, selectedCondition == .nearMint {
                    trendBadge(change: change)
                }
            }

            // Condition Label
            Text(selectedCondition.rawValue)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    private func trendBadge(change: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.caption)
            Text(String(format: "%+.1f%%", change))
                .font(DesignSystem.Typography.captionBold)
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, 2)
        .background(trend.color.opacity(0.15))
        .foregroundStyle(trend.color)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
    }

    private var estimatedPriceNote: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "info.circle")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("Detailed condition pricing requires JustTCG integration")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    private var priceHistoryButton: some View {
        Button {
            onPriceHistoryTap?()
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(DesignSystem.Typography.labelLarge)
                Text("View Price History")
                    .font(DesignSystem.Typography.labelLarge)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cyan.opacity(0.15))
            .foregroundStyle(DesignSystem.Colors.cyan)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .accessibilityLabel("View price history chart")
        .accessibilityHint("Opens a chart showing price trends over time")
    }
}

// MARK: - Condition Pill

struct ConditionPill: View {
    let condition: PriceCondition
    let isSelected: Bool
    let price: Double?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(condition.abbreviation)
                    .font(DesignSystem.Typography.labelLarge)
                    .fontWeight(isSelected ? .semibold : .regular)

                if let price = price {
                    Text("$\(price, specifier: "%.0f")")
                        .font(DesignSystem.Typography.caption)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                isSelected
                    ? DesignSystem.Colors.cyan
                    : DesignSystem.Colors.backgroundTertiary
            )
            .foregroundStyle(
                isSelected
                    ? Color.white
                    : DesignSystem.Colors.textPrimary
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        isSelected
                            ? DesignSystem.Colors.cyan
                            : DesignSystem.Colors.borderSecondary,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(condition.rawValue)")
        .accessibilityValue(price.map { "$\(String(format: "%.2f", $0))" } ?? "Price unavailable")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Compact Condition Picker (for ScanResultView)

struct CompactConditionPicker: View {
    @Binding var selectedCondition: PriceCondition
    let basePrice: Double?

    init(selectedCondition: Binding<PriceCondition>, basePrice: Double?) {
        self._selectedCondition = selectedCondition
        self.basePrice = basePrice
    }

    private var estimatedPrice: Double? {
        guard let base = basePrice else { return nil }
        return base * selectedCondition.typicalMultiplier
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Condition")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Picker("Condition", selection: $selectedCondition) {
                ForEach(PriceCondition.allCases) { condition in
                    Text(condition.abbreviation).tag(condition)
                }
            }
            .pickerStyle(.segmented)

            // Estimated Price Note
            if let price = estimatedPrice {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Est. Price:")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text("$\(price, specifier: "%.2f")")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    if selectedCondition != .nearMint {
                        Text("(\(Int(selectedCondition.typicalMultiplier * 100))% of NM)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Condition Price Selector") {
    VStack(spacing: 20) {
        ConditionPriceSelector(
            selectedCondition: .constant(.nearMint),
            conditionPrices: ConditionPrices(
                nearMint: 350.00,
                lightlyPlayed: 280.00,
                moderatelyPlayed: 200.00,
                heavilyPlayed: 150.00,
                damaged: 100.00
            ),
            priceChange7d: 5.2,
            onPriceHistoryTap: { print("History tapped") }
        )

        ConditionPriceSelector(
            selectedCondition: .constant(.lightlyPlayed),
            conditionPrices: nil,
            priceChange7d: nil,
            onPriceHistoryTap: nil
        )

        CompactConditionPicker(
            selectedCondition: .constant(.nearMint),
            basePrice: 100.00
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
#endif
