import SwiftUI

struct CurrencyTextField: View {
    let title: String
    @Binding var value: Decimal
    @FocusState.Binding var focusedField: SalesCalculatorView.Field?
    let field: SalesCalculatorView.Field

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text(title.uppercased())
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("$")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                TextField("0.00", value: $value, format: .number)
                    .font(DesignSystem.Typography.heading2.monospacedDigit())
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: field)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        focusedField == field ? DesignSystem.Colors.electricBlue : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}
