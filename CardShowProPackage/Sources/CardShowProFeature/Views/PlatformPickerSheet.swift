import SwiftUI

/// Modal sheet for selecting selling platform
struct PlatformPickerSheet: View {
    @Bindable var model: SalesCalculatorModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(SellingPlatform.allCases) { platform in
                Button {
                    withAnimation {
                        model.selectedPlatform = platform
                    }
                    dismiss()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        // Icon
                        Image(systemName: platform.icon)
                            .font(DesignSystem.Typography.heading3)
                            .foregroundStyle(DesignSystem.Colors.thunderYellow)
                            .frame(width: 44, height: 44)
                            .background(DesignSystem.Colors.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                        // Platform Details
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                            Text(platform.rawValue)
                                .font(DesignSystem.Typography.labelLarge)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                            Text(platform.feeStructure.description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)

                            // Fee Summary
                            if platform != .inPerson {
                                Text(feesSummary(for: platform))
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                            } else {
                                Text("No fees")
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundStyle(DesignSystem.Colors.success)
                            }
                        }

                        Spacer()

                        // Checkmark for selected
                        if model.selectedPlatform == platform {
                            Image(systemName: "checkmark.circle.fill")
                                .font(DesignSystem.Typography.heading3)
                                .foregroundStyle(DesignSystem.Colors.success)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Select Platform")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
                }
            }
        }
    }

    private func feesSummary(for platform: SellingPlatform) -> String {
        let fees = platform.feeStructure
        let platformPercent = fees.platformFeePercentage * 100
        let paymentPercent = fees.paymentFeePercentage * 100
        let fixedFee = fees.paymentFeeFixed

        if fixedFee > 0 {
            return String(format: "%.1f%% + %.1f%% + $%.2f", platformPercent, paymentPercent, fixedFee)
        } else {
            return String(format: "%.1f%% + %.1f%%", platformPercent, paymentPercent)
        }
    }
}
