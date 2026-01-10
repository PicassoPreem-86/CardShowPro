import SwiftUI

/// Segmented control for selecting grading company
struct CompanySelector: View {
    @Binding var selectedCompany: GradingCompany
    let onCompanyChanged: (GradingCompany) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("GRADING COMPANY")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: 0) {
                ForEach(GradingCompany.allCases) { company in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCompany = company
                            onCompanyChanged(company)
                        }
                    } label: {
                        Text(company.displayName)
                            .font(DesignSystem.Typography.labelLarge)
                            .foregroundStyle(
                                selectedCompany == company
                                    ? DesignSystem.Colors.backgroundPrimary
                                    : DesignSystem.Colors.textPrimary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(
                                selectedCompany == company
                                    ? DesignSystem.Colors.electricBlue
                                    : DesignSystem.Colors.backgroundTertiary
                            )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.borderPrimary, lineWidth: 1)
            )
        }
    }
}

#Preview {
    @Previewable @State var company = GradingCompany.psa
    CompanySelector(
        selectedCompany: $company,
        onCompanyChanged: { _ in }
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
