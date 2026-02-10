import SwiftUI

/// Forward Mode: "What Profit?" - Input sale price, calculate profit
/// PRIMARY mode for 80% of users who know their listing price
struct ForwardModeView: View {
    @Bindable var model: SalesCalculatorModel
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?
    @State private var showPlatformComparison = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Platform Selector
            PlatformSelectorCard(model: model)

            // HERO INPUT: Sale Price
            SalePriceInput(model: model, focusedField: $focusedField)

            // Secondary Inputs: Costs
            CostsSection(model: model, focusedField: $focusedField)

            // HERO RESULT: Net Profit
            ProfitResultCard(result: model.calculateProfit())
                .accessibilityIdentifier("profit-result-card")

            // Collapsible Fee Breakdown
            CollapsibleFeeBreakdown(result: model.calculateProfit())

            // Platform Comparison Button
            if model.salePrice > 0 && model.itemCost > 0 {
                platformComparisonButton
                    .accessibilityIdentifier("compare-platforms-button")
            }
        }
        .padding(DesignSystem.Spacing.md)
        .sheet(isPresented: $showPlatformComparison) {
            PlatformComparisonView(
                salePrice: model.salePrice,
                itemCost: model.itemCost,
                shippingCost: model.shippingCost,
                suppliesCost: model.suppliesCost
            )
        }
    }

    // MARK: - Platform Comparison Button

    private var platformComparisonButton: some View {
        Button {
            showPlatformComparison = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text("Compare All Platforms")
                        .font(DesignSystem.Typography.labelLarge)

                    Text("See which platform gives you the best profit")
                        .font(DesignSystem.Typography.captionSmall)
                        .opacity(0.8)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.electricBlue,
                        DesignSystem.Colors.electricBlue.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .shadow(
                color: DesignSystem.Colors.electricBlue.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Compare all platforms to see which gives the best profit")
    }
}

// MARK: - Sale Price Input (Hero Input)

private struct SalePriceInput: View {
    @Bindable var model: SalesCalculatorModel
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("LISTING PRICE")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text("What are you listing at?")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            // Large prominent input field
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("$")
                    .font(DesignSystem.Typography.displaySmall)
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)

                TextField("0.00", value: $model.salePrice, format: .number)
                    .font(DesignSystem.Typography.displaySmall.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .salePrice)
                    .accessibilityLabel("Sale price")
                    .accessibilityHint("Enter the price you are listing at")
                    .accessibilityIdentifier("sale-price-field")
            }
            .padding(DesignSystem.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.backgroundSecondary,
                        DesignSystem.Colors.backgroundTertiary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .stroke(
                        focusedField == .salePrice
                            ? DesignSystem.Colors.thunderYellow
                            : DesignSystem.Colors.borderPrimary,
                        lineWidth: focusedField == .salePrice ? 3 : 1
                    )
            )
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }
}

// MARK: - Costs Section

private struct CostsSection: View {
    @Bindable var model: SalesCalculatorModel
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("YOUR COSTS")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text("What did you spend?")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            VStack(spacing: DesignSystem.Spacing.sm) {
                CostInputField(
                    title: "Item Cost",
                    value: $model.itemCost,
                    focusedField: $focusedField,
                    field: .itemCost
                )

                CostInputField(
                    title: "Shipping Cost",
                    value: $model.shippingCost,
                    focusedField: $focusedField,
                    field: .shippingCost
                )

                CostInputField(
                    title: "Supplies Cost",
                    subtitle: "Sleeves, top-loaders, boxes",
                    value: $model.suppliesCost,
                    focusedField: $focusedField,
                    field: .suppliesCost
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }
}

// MARK: - Cost Input Field

private struct CostInputField: View {
    let title: String
    var subtitle: String? = nil
    @Binding var value: Decimal
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?
    let field: SalesCalculatorView.Field

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer()

            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Text("$")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                TextField("0.00", value: $value, format: .number)
                    .font(DesignSystem.Typography.heading4.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: field)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .accessibilityLabel(title)
                    .accessibilityIdentifier("\(title.lowercased().replacingOccurrences(of: " ", with: "-"))-field")
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .stroke(
                        focusedField == field ? DesignSystem.Colors.electricBlue : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundTertiary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
}

#Preview("Forward Mode - Empty") {
    @Previewable @State var model = SalesCalculatorModel()
    @Previewable @FocusState var focusedField: SalesCalculatorView.Field?

    ScrollView {
        ForwardModeView(model: model, focusedField: $focusedField)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Forward Mode - Filled") {
    @Previewable @State var model = SalesCalculatorModel()
    @Previewable @FocusState var focusedField: SalesCalculatorView.Field?

    let _ = {
        model.salePrice = 100.00
        model.itemCost = 50.00
        model.shippingCost = 5.00
        model.suppliesCost = 2.00
    }()

    ScrollView {
        ForwardModeView(model: model, focusedField: $focusedField)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}
