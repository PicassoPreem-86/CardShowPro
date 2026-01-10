import SwiftUI

/// Multi-scenario comparison table showing all grade outcomes
struct GradeScenariosTable: View {
    let scenarios: [GradeScenario]
    let rawValue: Double

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Text("Grade Scenarios")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
            }

            // Raw Value Row
            VStack(spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text("Raw Value")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(rawValue.asCurrency)
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .monospacedDigit()
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                Divider()
                    .background(DesignSystem.Colors.borderPrimary)
            }

            // Scenario Rows
            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(scenarios) { scenario in
                    GradeScenarioRow(scenario: scenario)
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
}

#Preview {
    let scenarios = [
        GradeScenario(
            gradeLevel: .ten,
            gradedValue: 350,
            profit: 310,
            roiPercentage: 150
        ),
        GradeScenario(
            gradeLevel: .nine,
            gradedValue: 180,
            profit: 140,
            roiPercentage: 80
        ),
        GradeScenario(
            gradeLevel: .eight,
            gradedValue: 120,
            profit: 80,
            roiPercentage: 40
        ),
        GradeScenario(
            gradeLevel: .belowEight,
            gradedValue: 90,
            profit: -10,
            roiPercentage: -5
        )
    ]

    GradeScenariosTable(scenarios: scenarios, rawValue: 100)
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}
