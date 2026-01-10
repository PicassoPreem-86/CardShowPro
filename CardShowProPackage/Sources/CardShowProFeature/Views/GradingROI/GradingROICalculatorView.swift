import SwiftUI

/// Main Grading ROI Calculator view
struct GradingROICalculatorView: View {
    @State private var state = GradingROICalculatorState()
    @FocusState private var isInputFocused: Bool
    @State private var showResetAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Input Section
                inputSection

                // Cost Breakdown Card
                CostBreakdownCard(costs: state.calculation.costs)

                // Grade Scenarios Table
                GradeScenariosTable(
                    scenarios: state.calculation.scenarios,
                    rawValue: state.rawValue
                )

                // Recommendation Card
                RecommendationCard(recommendation: state.calculation.recommendation)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle("Grading ROI Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    showResetAlert = true
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
                .foregroundStyle(DesignSystem.Colors.thunderYellow)
            }
        }
        .alert("Reset Calculator?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                state.reset()
                isInputFocused = false
            }
        } message: {
            Text("This will clear all inputs and reset to default values.")
        }
    }

    private var inputSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Raw Value Input
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text("RAW CARD VALUE")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                HStack {
                    Text("$")
                        .font(DesignSystem.Typography.heading2)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    TextField("0.00", value: $state.rawValue, format: .number)
                        .font(DesignSystem.Typography.heading2)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .keyboardType(.decimalPad)
                        .focused($isInputFocused)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(
                            isInputFocused ? DesignSystem.Colors.electricBlue : DesignSystem.Colors.borderPrimary,
                            lineWidth: isInputFocused ? 2 : 1
                        )
                )
            }

            // Company Selector
            CompanySelector(
                selectedCompany: $state.selectedCompany,
                onCompanyChanged: { company in
                    state.updateCompany(company)
                }
            )

            // Service Level Picker
            ServiceLevelPicker(
                serviceLevels: state.availableServiceLevels,
                selectedServiceLevel: $state.selectedServiceLevel,
                onServiceLevelChanged: { serviceLevel in
                    state.updateServiceLevel(serviceLevel)
                }
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

#Preview {
    NavigationStack {
        GradingROICalculatorView()
    }
}
