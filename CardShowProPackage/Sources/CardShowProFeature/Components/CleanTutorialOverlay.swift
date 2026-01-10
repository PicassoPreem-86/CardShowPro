import SwiftUI

/// Clean, minimal tutorial overlay for first-time users
///
/// Shows a brief 2-step guide with glassmorphic design.
/// Much simpler and more professional than the previous Pokemon-themed tutorial.
struct CleanTutorialOverlay: View {
    let onDismiss: () -> Void

    @State private var currentStep = 0
    private let totalSteps = 2

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {} // Prevent passthrough

            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()

                // Tutorial content
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Step indicator dots
                    HStack(spacing: 8) {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? DesignSystem.Colors.goldAmber : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }

                    // Step content
                    VStack(spacing: DesignSystem.Spacing.md) {
                        // Icon
                        Image(systemName: stepIcon)
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.goldAmber)
                            .frame(width: 80, height: 80)

                        // Title
                        Text(stepTitle)
                            .font(DesignSystem.Typography.heading2)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        // Description
                        Text(stepDescription)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 300)
                    .padding(.vertical, DesignSystem.Spacing.md)

                    // Action button
                    Button(action: handleButtonTap) {
                        Text(buttonText)
                            .font(DesignSystem.Typography.labelLarge)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DesignSystem.Colors.goldAmber)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(DesignSystem.Spacing.xl)
                .background(.ultraThinMaterial)
                .background(Color(hex: "#1C1C1E").opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 15)
                .padding(.horizontal, DesignSystem.Spacing.xl)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tutorial: \(stepTitle). \(stepDescription)")
    }

    // MARK: - Step Content
    private var stepIcon: String {
        switch currentStep {
        case 0: return "viewfinder"
        default: return "hand.tap.fill"
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return "Position Your Card"
        default: return "Automatic Capture"
        }
    }

    private var stepDescription: String {
        switch currentStep {
        case 0: return "Center the card in your camera view. Make sure it's well-lit and in focus."
        default: return "Hold steady. We'll automatically capture when the card is perfectly framed."
        }
    }

    private var buttonText: String {
        currentStep < totalSteps - 1 ? "Next" : "Start Scanning"
    }

    // MARK: - Actions
    private func handleButtonTap() {
        if currentStep < totalSteps - 1 {
            // Move to next step
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentStep += 1
            }

            // Light haptic
            HapticManager.shared.light()
        } else {
            // Complete tutorial
            onDismiss()
        }
    }
}

// MARK: - Preview
#Preview("Tutorial - Step 1") {
    CleanTutorialOverlay {
        print("Tutorial dismissed")
    }
    .preferredColorScheme(.dark)
}

#Preview("In Camera Context") {
    ZStack {
        // Mock camera view
        Color.black.ignoresSafeArea()

        CleanTutorialOverlay {
            print("Tutorial dismissed")
        }
    }
    .preferredColorScheme(.dark)
}