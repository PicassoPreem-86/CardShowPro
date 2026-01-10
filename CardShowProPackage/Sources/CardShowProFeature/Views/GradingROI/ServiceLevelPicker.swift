import SwiftUI

/// Picker for selecting service level tier
struct ServiceLevelPicker: View {
    let serviceLevels: [ServiceLevel]
    @Binding var selectedServiceLevel: ServiceLevel
    let onServiceLevelChanged: (ServiceLevel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("SERVICE LEVEL")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Menu {
                ForEach(serviceLevels) { level in
                    Button {
                        selectedServiceLevel = level
                        onServiceLevelChanged(level)
                    } label: {
                        HStack {
                            Text(level.name)
                            Spacer()
                            Text(level.fee.asCurrency)
                        }
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedServiceLevel.name)
                            .font(DesignSystem.Typography.bodyLarge)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text(selectedServiceLevel.turnaroundDays)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    Spacer()

                    Text(selectedServiceLevel.fee.asCurrency)
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.electricBlue)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.borderPrimary, lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    @Previewable @State var serviceLevel = GradingCompany.psa.serviceLevels[0]
    ServiceLevelPicker(
        serviceLevels: GradingCompany.psa.serviceLevels,
        selectedServiceLevel: $serviceLevel,
        onServiceLevelChanged: { _ in }
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
