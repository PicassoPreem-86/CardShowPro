import SwiftUI

/// Sheet for manually entering card details
struct ManualCardEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TradeAnalyzerViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Card Name", text: $viewModel.manualCardName)
                        .font(DesignSystem.Typography.body)

                    TextField("Set Name (Optional)", text: $viewModel.manualSetName)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } header: {
                    Text("Card Details")
                        .font(DesignSystem.Typography.labelSmall)
                }

                Section {
                    TextField("0.00", text: $viewModel.manualValue)
                        .keyboardType(.decimalPad)
                        .font(DesignSystem.Typography.bodyLarge)
                } header: {
                    Text("Estimated Value")
                        .font(DesignSystem.Typography.labelSmall)
                } footer: {
                    Text("Enter the estimated market value for this card")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                Section {
                    Button {
                        viewModel.addManualCard()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Add Card")
                                .font(DesignSystem.Typography.labelLarge)
                                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                            Spacer()
                        }
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                    }
                    .listRowBackground(DesignSystem.Colors.thunderYellow)
                    .disabled(viewModel.manualCardName.isEmpty || viewModel.manualValue.isEmpty)
                }
            }
            .navigationTitle("Add Card Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetManualEntry()
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }
}
