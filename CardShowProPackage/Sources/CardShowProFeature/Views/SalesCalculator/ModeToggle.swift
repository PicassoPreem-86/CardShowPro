import SwiftUI

/// Mode toggle for switching between Forward and Reverse calculation modes
struct ModeToggle: View {
    @Binding var mode: CalculatorMode

    var body: some View {
        HStack(spacing: 0) {
            ModeToggleButton(
                title: "What Profit?",
                subtitle: "I'm listing at...",
                isSelected: mode == .forward,
                position: .leading
            ) {
                withAnimation(.spring(duration: 0.3)) {
                    mode = .forward
                }
            }
            .accessibilityIdentifier("forward-mode-button")

            ModeToggleButton(
                title: "What Price?",
                subtitle: "I want to make...",
                isSelected: mode == .reverse,
                position: .trailing
            ) {
                withAnimation(.spring(duration: 0.3)) {
                    mode = .reverse
                }
            }
            .accessibilityIdentifier("reverse-mode-button")
        }
        .frame(height: 72)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

// MARK: - Mode Toggle Button

private struct ModeToggleButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let position: Position
    let action: () -> Void

    enum Position {
        case leading
        case trailing
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxxs) {
                Text(title)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.backgroundPrimary : DesignSystem.Colors.textPrimary)

                Text(subtitle)
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.backgroundPrimary.opacity(0.8) : DesignSystem.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(DesignSystem.Colors.thunderYellow)
                            .padding(DesignSystem.Spacing.xxxs)
                            .shadow(
                                color: DesignSystem.Colors.thunderYellow.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 2
                            )
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(subtitle)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    @Previewable @State var mode: CalculatorMode = .forward

    VStack(spacing: 20) {
        ModeToggle(mode: $mode)

        Text("Current Mode: \(mode == .forward ? "Forward (What Profit?)" : "Reverse (What Price?)")")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
