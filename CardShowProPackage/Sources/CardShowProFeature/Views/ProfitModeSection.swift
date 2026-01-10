import SwiftUI

/// Profit mode selector with presets
struct ProfitModeSection: View {
    @Bindable var model: SalesCalculatorModel
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            SectionHeader(title: "Profit Target")

            // Mode Toggle
            HStack(spacing: DesignSystem.Spacing.xs) {
                ModeButton(
                    title: "$ Amount",
                    isSelected: isFixedAmountMode,
                    action: {
                        if case .percentage(let percent) = model.profitMode {
                            model.profitMode = .fixedAmount(model.cardCost * Decimal(percent))
                        }
                    }
                )

                ModeButton(
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

            // Input Field
            if case .fixedAmount = model.profitMode {
                // Fixed Amount Input
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("PROFIT AMOUNT")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("$")
                            .font(DesignSystem.Typography.heading2)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        TextField("0.00", value: fixedAmountBinding, format: .number)
                            .font(DesignSystem.Typography.heading2.monospacedDigit())
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .profitAmount)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(
                                focusedField == .profitAmount ? DesignSystem.Colors.electricBlue : Color.clear,
                                lineWidth: 2
                            )
                    )
                }
            } else if case .percentage(let percent) = model.profitMode {
                // Percentage Mode with Presets
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("MARGIN PRESETS")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        PresetButton(label: "20%", value: 0.20, currentValue: percent) {
                            model.setMarginPreset(0.20)
                        }

                        PresetButton(label: "30%", value: 0.30, currentValue: percent) {
                            model.setMarginPreset(0.30)
                        }

                        PresetButton(label: "50%", value: 0.50, currentValue: percent) {
                            model.setMarginPreset(0.50)
                        }
                    }

                    // Current Margin Display
                    HStack {
                        Text("Current Margin:")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        Spacer()

                        Text((percent * 100).asPercentage)
                            .font(DesignSystem.Typography.heading3.monospacedDigit())
                            .foregroundStyle(DesignSystem.Colors.thunderYellow)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
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

// MARK: - Mode Button

struct ModeButton: View {
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
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preset Button

struct PresetButton: View {
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
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(isSelected ? DesignSystem.Colors.thunderYellow : DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(isSelected ? DesignSystem.Colors.thunderYellow : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}
