import SwiftUI

/// Generation phase view with AI animation and progress indicators
struct GenerationPhaseView: View {
    let state: ListingGeneratorState

    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Thunder Icon Animation
            ThunderIconAnimation(pulseScale: $pulseScale, rotationAngle: $rotationAngle)

            // Status Text
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Generating Listing")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Optimizing for \(state.selectedPlatform.rawValue)")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Progress Steps
            ProgressStepsView(progress: state.generationProgress)

            // Progress Bar
            ProgressBarView(progress: state.generationProgress)

            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startAnimations()
            simulateProgress()
        }
    }

    private func startAnimations() {
        // Pulse animation
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.2
        }

        // Rotation animation
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }

    private func simulateProgress() {
        // Progress simulation over 2.5 seconds
        let steps = 25
        let interval = 2.5 / Double(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                withAnimation(.easeInOut(duration: interval)) {
                    // Progress is handled by service completion
                }
            }
        }
    }
}

// MARK: - Thunder Icon Animation

private struct ThunderIconAnimation: View {
    @Binding var pulseScale: CGFloat
    @Binding var rotationAngle: Double

    var body: some View {
        ZStack {
            // Outer glow rings
            Circle()
                .fill(DesignSystem.Colors.electricBlue.opacity(0.2))
                .frame(width: 200, height: 200)
                .scaleEffect(pulseScale)

            Circle()
                .fill(DesignSystem.Colors.electricBlue.opacity(0.1))
                .frame(width: 250, height: 250)
                .scaleEffect(pulseScale * 1.1)

            // Thunder icon
            Image(systemName: "bolt.fill")
                .font(.system(size: 80))
                .foregroundStyle(DesignSystem.Colors.electricBlue)
                .shadow(
                    color: DesignSystem.Colors.electricBlue.opacity(0.5),
                    radius: 20
                )
                .scaleEffect(pulseScale)

            // Rotating ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            DesignSystem.Colors.electricBlue.opacity(0),
                            DesignSystem.Colors.electricBlue,
                            DesignSystem.Colors.cyan,
                            DesignSystem.Colors.electricBlue.opacity(0)
                        ],
                        center: .center
                    ),
                    lineWidth: 4
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(rotationAngle))
        }
    }
}

// MARK: - Progress Steps View

private struct ProgressStepsView: View {
    let progress: Double

    private var currentStep: Int {
        if progress < 0.33 { return 0 }
        if progress < 0.66 { return 1 }
        if progress < 1.0 { return 2 }
        return 3
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ProgressStep(
                title: "Analyzing card details",
                isActive: currentStep >= 0,
                isComplete: currentStep > 0
            )

            ProgressStep(
                title: "Optimizing title and description",
                isActive: currentStep >= 1,
                isComplete: currentStep > 1
            )

            ProgressStep(
                title: "Generating SEO keywords",
                isActive: currentStep >= 2,
                isComplete: currentStep > 2
            )
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }
}

private struct ProgressStep: View {
    let title: String
    let isActive: Bool
    let isComplete: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Icon
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                    .transition(.scale.combined(with: .opacity))
            } else if isActive {
                ProgressView()
                    .tint(DesignSystem.Colors.electricBlue)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .transition(.scale.combined(with: .opacity))
            }

            // Title
            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(
                    isActive || isComplete
                        ? DesignSystem.Colors.textPrimary
                        : DesignSystem.Colors.textTertiary
                )

            Spacer()
        }
        .animation(.easeInOut(duration: DesignSystem.Animation.fast), value: isActive)
        .animation(.easeInOut(duration: DesignSystem.Animation.fast), value: isComplete)
    }
}

// MARK: - Progress Bar View

private struct ProgressBarView: View {
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("Progress")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.electricBlue)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                        .fill(DesignSystem.Colors.backgroundTertiary)
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.electricBlue,
                                    DesignSystem.Colors.cyan
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: DesignSystem.Animation.normal), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }
}
