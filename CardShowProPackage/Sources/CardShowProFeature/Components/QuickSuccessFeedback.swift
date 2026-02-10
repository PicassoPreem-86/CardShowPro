import SwiftUI

/// Quick success feedback with minimal animation
///
/// Displays a brief checkmark animation (0.3s) to confirm successful card capture.
/// Much faster and more subtle than the previous Pokemon-themed animation.
struct QuickSuccessFeedback: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Subtle overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Success checkmark
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DesignSystem.Colors.goldAmber.opacity(glowOpacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Checkmark background
                Circle()
                    .fill(DesignSystem.Colors.goldAmber)
                    .frame(width: 72, height: 72)

                // Checkmark icon
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(checkmarkScale)
            .opacity(checkmarkOpacity)
        }
        .task {
            await playAnimation()
        }
    }

    // MARK: - Animation
    private func playAnimation() async {
        if reduceMotion {
            // Reduced motion: Simple fade in/out
            withAnimation(.easeOut(duration: 0.15)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }

            // Trigger haptic
            triggerHaptic()

            try? await Task.sleep(for: .seconds(0.4))

            withAnimation(.easeIn(duration: 0.15)) {
                checkmarkOpacity = 0
            }

            try? await Task.sleep(for: .seconds(0.15))
            onComplete()
        } else {
            // Full animation: Quick scale-up with glow
            await animateFullSequence()
        }
    }

    private func animateFullSequence() async {
        // Phase 1: Scale up (0.0s - 0.15s)
        withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
            checkmarkScale = 1.1
            checkmarkOpacity = 1.0
            glowOpacity = 0.6
        }

        // Trigger haptic immediately
        triggerHaptic()

        // Phase 2: Settle (0.15s - 0.25s)
        try? await Task.sleep(for: .seconds(0.15))

        withAnimation(.spring(response: 0.1, dampingFraction: 0.7)) {
            checkmarkScale = 1.0
        }

        // Phase 3: Fade out (0.25s - 0.35s)
        try? await Task.sleep(for: .seconds(0.1))

        withAnimation(.easeIn(duration: 0.1)) {
            checkmarkOpacity = 0
            glowOpacity = 0
        }

        try? await Task.sleep(for: .seconds(0.1))

        // Complete
        onComplete()
    }

    // MARK: - Haptic
    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Convenience Modifier
extension View {
    /// Shows quick success feedback as an overlay
    func quickSuccessFeedback(
        isPresented: Binding<Bool>,
        onComplete: @escaping () -> Void = {}
    ) -> some View {
        self.overlay {
            if isPresented.wrappedValue {
                QuickSuccessFeedback {
                    isPresented.wrappedValue = false
                    onComplete()
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Preview
#Preview("Success Feedback") {
    ZStack {
        Color.black.ignoresSafeArea()

        QuickSuccessFeedback {
            print("Animation complete")
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("In Context") {
    struct PreviewWrapper: View {
        @State private var showSuccess = false

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Text("Tap to trigger")
                        .foregroundStyle(.white)

                    Button("Capture Card") {
                        showSuccess = true
                    }
                    .padding()
                    .background(DesignSystem.Colors.goldAmber)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
            .quickSuccessFeedback(isPresented: $showSuccess) {
                print("Success feedback completed!")
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}