import SwiftUI

/// Sheet for adding cards from inventory or manually
struct AddCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TradeAnalyzerViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Manual Entry Button
                Button {
                    dismiss()
                    // Small delay to ensure sheet dismisses before showing next one
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        if viewModel.isAddingToYourSide {
                            viewModel.showingAddYourCard = true
                        } else {
                            viewModel.showingAddTheirCard = true
                        }
                    }
                } label: {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 48))
                            .foregroundStyle(DesignSystem.Colors.electricBlue)

                        Text("Enter Manually")
                            .font(DesignSystem.Typography.heading3)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("Type card name and value")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.xl)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.borderPrimary, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // From Inventory Button (Coming Soon)
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text("From Inventory")
                        .font(DesignSystem.Typography.heading3)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text("Coming soon - Select from saved cards")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text("COMING SOON")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xxxs)
                        .background(DesignSystem.Colors.warning)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xl)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                .opacity(0.5)

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }
}
