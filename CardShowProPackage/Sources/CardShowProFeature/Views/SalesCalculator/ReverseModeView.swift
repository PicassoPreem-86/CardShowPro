import SwiftUI

/// Reverse Mode: "What Price?" - Input desired profit, calculate required sale price
/// SECONDARY mode for 20% of users who want to hit a profit target
struct ReverseModeView: View {
    @Bindable var model: SalesCalculatorModel
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Platform Selector
            PlatformSelectorCard(model: model)

            // Profit Goal Section
            ProfitGoalSection(model: model, focusedField: $focusedField)

            // Costs Section
            ReverseCostsSection(model: model, focusedField: $focusedField)

            // HERO RESULT: Recommended Sale Price
            PriceResultCard(result: model.calculationResult, model: model)
        }
        .padding(DesignSystem.Spacing.md)
    }
}

// MARK: - Profit Goal Section

private struct ProfitGoalSection: View {
    @Bindable var model: SalesCalculatorModel
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("PROFIT GOAL")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text("How much do you want to make?")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            // Mode Toggle: $ Amount vs % Margin
            HStack(spacing: DesignSystem.Spacing.xs) {
                ProfitModeButton(
                    title: "$ Amount",
                    isSelected: isFixedAmountMode,
                    action: {
                        if case .percentage(let percent) = model.profitMode {
                            model.profitMode = .fixedAmount(model.cardCost * Decimal(percent))
                        }
                    }
                )

                ProfitModeButton(
                    title: "% Margin",
                    isSelected: !isFixedAmountMode,
                    action: {
                        if case .fixedAmount(let amount) = model.profitMode {
                            let percent = model.cardCost > 0 ? Double(truncating: (amount / model.cardCost) as NSNumber) : 0.20
                            model.profitMode = .percentage(percent)
                        } else {
                            model.profitMode = .percentage(0.20)
                        }
                    }
                )
            }

            // Input based on selected mode
            if case .fixedAmount = model.profitMode {
                FixedAmountInput(model: model, focusedField: $focusedField)
            } else if case .percentage(let percent) = model.profitMode {
                PercentageInput(model: model, currentPercent: percent)
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

    private var isFixedAmountMode: Bool {
        if case .fixedAmount = model.profitMode {
            return true
        }
        return false
    }
}

// MARK: - Profit Mode Button

private struct ProfitModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(isSelected ? DesignSystem.Colors.backgroundPrimary : DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(isSelected ? DesignSystem.Colors.thunderYellow : DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Fixed Amount Input

private struct FixedAmountInput: View {
    @Bindable var model: SalesCalculatorModel
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Enter your desired profit")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("$")
                    .font(DesignSystem.Typography.displaySmall)
                    .foregroundStyle(DesignSystem.Colors.success)

                TextField("0.00", value: fixedAmountBinding, format: .number)
                    .font(DesignSystem.Typography.displaySmall.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .profitAmount)
                    .accessibilityLabel("Desired profit amount")
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .stroke(
                        focusedField == .profitAmount
                            ? DesignSystem.Colors.success
                            : DesignSystem.Colors.borderPrimary,
                        lineWidth: focusedField == .profitAmount ? 3 : 1
                    )
            )
        }
    }

    private var fixedAmountBinding: Binding<Decimal> {
        Binding(
            get: {
                if case .fixedAmount(let amount) = model.profitMode {
                    return amount
                }
                return 0
            },
            set: { newValue in
                model.profitMode = .fixedAmount(newValue)
            }
        )
    }
}

// MARK: - Percentage Input

private struct PercentageInput: View {
    @Bindable var model: SalesCalculatorModel
    let currentPercent: Double

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("Quick Presets")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: DesignSystem.Spacing.xs) {
                ReversePresetButton(label: "20%", value: 0.20, currentValue: currentPercent) {
                    model.setMarginPreset(0.20)
                }

                ReversePresetButton(label: "30%", value: 0.30, currentValue: currentPercent) {
                    model.setMarginPreset(0.30)
                }

                ReversePresetButton(label: "50%", value: 0.50, currentValue: currentPercent) {
                    model.setMarginPreset(0.50)
                }

                ReversePresetButton(label: "100%", value: 1.00, currentValue: currentPercent) {
                    model.setMarginPreset(1.00)
                }
            }

            // Current margin display
            HStack {
                Text("Target Margin")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text((currentPercent * 100).asPercentage)
                    .font(DesignSystem.Typography.displaySmall.monospacedDigit())
                    .foregroundStyle(DesignSystem.Colors.success)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        }
    }
}

// MARK: - Reverse Preset Button

private struct ReversePresetButton: View {
    let label: String
    let value: Double
    let currentValue: Double
    let action: () -> Void

    private var isSelected: Bool {
        abs(currentValue - value) < 0.001
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(isSelected ? DesignSystem.Colors.backgroundPrimary : DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(isSelected ? DesignSystem.Colors.success : DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(isSelected ? DesignSystem.Colors.success : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) profit margin")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Reverse Costs Section

private struct ReverseCostsSection: View {
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
                ReverseCostField(
                    title: "Item Cost",
                    value: $model.cardCost,
                    focusedField: $focusedField,
                    field: .cardCost
                )

                ReverseCostField(
                    title: "Shipping Cost",
                    value: $model.shippingCost,
                    focusedField: $focusedField,
                    field: .shippingCost
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

// MARK: - Reverse Cost Field

private struct ReverseCostField: View {
    let title: String
    @Binding var value: Decimal
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?
    let field: SalesCalculatorView.Field

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

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

#Preview("Reverse Mode - Empty") {
    @Previewable @State var model = SalesCalculatorModel()
    @Previewable @FocusState var focusedField: SalesCalculatorView.Field?

    let _ = { model.mode = .reverse }()

    ScrollView {
        ReverseModeView(model: model, focusedField: $focusedField)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Reverse Mode - Filled") {
    @Previewable @State var model = SalesCalculatorModel()
    @Previewable @FocusState var focusedField: SalesCalculatorView.Field?

    let _ = {
        model.mode = .reverse
        model.cardCost = 50.00
        model.shippingCost = 5.00
        model.profitMode = .fixedAmount(15.00)
    }()

    ScrollView {
        ReverseModeView(model: model, focusedField: $focusedField)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}
