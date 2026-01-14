import SwiftUI

/// Main Sales Calculator view with form-based layout
struct SalesCalculatorView: View {
    @State private var model = SalesCalculatorModel()
    @FocusState private var focusedField: Field?
    @State private var showResetAlert = false
    @State private var showCopyToast = false

    enum Field: Hashable {
        // Forward Mode fields
        case salePrice
        case itemCost
        case shippingCost
        case suppliesCost

        // Reverse Mode fields (legacy)
        case cardCost
        case profitAmount
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Mode Toggle
                ModeToggle(mode: $model.mode)

                // Mode-specific views
                Group {
                    switch model.mode {
                    case .forward:
                        ForwardModeView(model: model, focusedField: $focusedField)
                    case .reverse:
                        ReverseModeView(model: model, focusedField: $focusedField)
                    }
                }
                .transition(.opacity)
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle("Sales Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("sales-calculator-view")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    showResetAlert = true
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .accessibilityIdentifier("reset-button")
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .foregroundStyle(DesignSystem.Colors.thunderYellow)
            }
        }
        .alert("Reset Calculator?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                model.reset()
                focusedField = nil
            }
        } message: {
            Text("This will clear all inputs and reset to default values.")
        }
        .sheet(isPresented: $model.showPlatformPicker) {
            PlatformPickerSheet(model: model)
        }
        .overlay(alignment: .top) {
            if showCopyToast {
                ToastView(message: "List price copied!")
                    .padding(.top, DesignSystem.Spacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showCopyToast = false
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(DesignSystem.Typography.labelLarge)
            .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.thunderYellow)
            .clipShape(Capsule())
            .shadow(
                color: DesignSystem.Shadows.level4.color,
                radius: DesignSystem.Shadows.level4.radius,
                x: DesignSystem.Shadows.level4.x,
                y: DesignSystem.Shadows.level4.y
            )
    }
}
