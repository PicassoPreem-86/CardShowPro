import SwiftUI

/// Individual grade scenario row with profit indicators
struct GradeScenarioRow: View {
    let scenario: GradeScenario

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Grade Badge
            gradeBadge

            Spacer()

            // Values Stack
            VStack(alignment: .trailing, spacing: 4) {
                // Graded Value
                Text(scenario.gradedValue.asCurrency)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .monospacedDigit()

                // Profit/ROI
                HStack(spacing: 8) {
                    Text(scenario.profit.asCurrency)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(profitColor)
                        .monospacedDigit()

                    Text(scenario.roiPercentage.asPercentage)
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(profitColor)
                        .monospacedDigit()
                }
            }

            // Profit Indicator
            profitIndicator
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(profitColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var gradeBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(gradeColor)
                .frame(width: 8, height: 8)

            Text(scenario.gradeLevel.displayName)
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }

    private var profitIndicator: some View {
        Image(systemName: profitIcon)
            .font(.title3)
            .foregroundStyle(profitColor)
            .frame(width: 24)
    }

    private var gradeColor: Color {
        switch scenario.gradeLevel {
        case .ten:
            return DesignSystem.Colors.thunderYellow
        case .nine:
            return DesignSystem.Colors.success
        case .eight:
            return DesignSystem.Colors.warning
        case .belowEight:
            return DesignSystem.Colors.error
        }
    }

    private var profitColor: Color {
        switch scenario.profitIndicator {
        case .positive:
            return DesignSystem.Colors.success
        case .neutral:
            return DesignSystem.Colors.warning
        case .negative:
            return DesignSystem.Colors.error
        }
    }

    private var profitIcon: String {
        switch scenario.profitIndicator {
        case .positive:
            return "arrow.up.circle.fill"
        case .neutral:
            return "arrow.right.circle.fill"
        case .negative:
            return "arrow.down.circle.fill"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        GradeScenarioRow(
            scenario: GradeScenario(
                gradeLevel: .ten,
                gradedValue: 350,
                profit: 310,
                roiPercentage: 150
            )
        )

        GradeScenarioRow(
            scenario: GradeScenario(
                gradeLevel: .nine,
                gradedValue: 180,
                profit: 15,
                roiPercentage: 30
            )
        )

        GradeScenarioRow(
            scenario: GradeScenario(
                gradeLevel: .belowEight,
                gradedValue: 90,
                profit: -10,
                roiPercentage: -5
            )
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
