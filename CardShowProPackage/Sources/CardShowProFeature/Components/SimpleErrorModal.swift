import SwiftUI

/// Simple error modal with glassmorphic design
///
/// Displays error messages with clean SF Symbol icons and minimal styling.
/// Replaces Pokemon-themed error illustrations with professional design.
struct SimpleErrorModal: View {
    enum ErrorType {
        case cardNotFound
        case lowLight
        case holdSteady

        var icon: String {
            switch self {
            case .cardNotFound: return "exclamationmark.circle.fill"
            case .lowLight: return "lightbulb.fill"
            case .holdSteady: return "camera.fill"
            }
        }

        var title: String {
            switch self {
            case .cardNotFound: return "Card Not Found"
            case .lowLight: return "Low Light Detected"
            case .holdSteady: return "Hold Steady"
            }
        }

        var message: String {
            switch self {
            case .cardNotFound:
                return "We couldn't identify this card in our database. It may be damaged or not yet cataloged."
            case .lowLight:
                return "We're having trouble seeing the card clearly. Try moving to a brighter area or enable the flash."
            case .holdSteady:
                return "Try holding your device steady while scanning the card."
            }
        }

        var iconColor: Color {
            switch self {
            case .cardNotFound: return .red.opacity(0.8)
            case .lowLight: return DesignSystem.Colors.goldAmber
            case .holdSteady: return .orange.opacity(0.8)
            }
        }
    }

    let errorType: ErrorType
    let onPrimaryAction: () -> Void
    let onSecondaryAction: (() -> Void)?

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onPrimaryAction()
                }

            // Error modal
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Icon
                Image(systemName: errorType.icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(errorType.iconColor)
                    .frame(width: 80, height: 80)

                // Title
                Text(errorType.title)
                    .font(DesignSystem.Typography.heading2)
                    .foregroundStyle(.white)

                // Message
                Text(errorType.message)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Buttons
                VStack(spacing: DesignSystem.Spacing.sm) {
                    // Primary button
                    Button(action: onPrimaryAction) {
                        Text(primaryButtonText)
                            .font(DesignSystem.Typography.labelLarge)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(primaryButtonColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Secondary button (if provided)
                    if let secondaryAction = onSecondaryAction {
                        Button(action: secondaryAction) {
                            Text(secondaryButtonText)
                                .font(DesignSystem.Typography.label)
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.xs)
            }
            .padding(DesignSystem.Spacing.xl)
            .frame(maxWidth: 340)
            .background(.ultraThinMaterial)
            .background(Color(hex: "#1C1C1E").opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(errorType.title). \(errorType.message)")
    }

    // MARK: - Button Text
    private var primaryButtonText: String {
        switch errorType {
        case .cardNotFound: return "Try Again"
        case .lowLight: return "Turn On Flash"
        case .holdSteady: return "Got It"
        }
    }

    private var secondaryButtonText: String {
        switch errorType {
        case .cardNotFound: return "Enter Manually"
        case .lowLight: return "Dismiss"
        case .holdSteady: return "Use Manual Capture"
        }
    }

    private var primaryButtonColor: Color {
        switch errorType {
        case .cardNotFound: return DesignSystem.Colors.goldAmber
        case .lowLight: return DesignSystem.Colors.goldAmber
        case .holdSteady: return DesignSystem.Colors.goldAmber
        }
    }
}

// MARK: - Previews
#Preview("Card Not Found") {
    SimpleErrorModal(
        errorType: .cardNotFound,
        onPrimaryAction: { print("Try Again") },
        onSecondaryAction: { print("Enter Manually") }
    )
    .preferredColorScheme(.dark)
}

#Preview("Low Light") {
    SimpleErrorModal(
        errorType: .lowLight,
        onPrimaryAction: { print("Turn On Flash") },
        onSecondaryAction: { print("Dismiss") }
    )
    .preferredColorScheme(.dark)
}

#Preview("Hold Steady") {
    SimpleErrorModal(
        errorType: .holdSteady,
        onPrimaryAction: { print("Got It") },
        onSecondaryAction: { print("Use Manual") }
    )
    .preferredColorScheme(.dark)
}