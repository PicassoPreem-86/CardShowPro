import SwiftUI

/// Shimmer effect modifier for adding shimmer animation to any view
///
/// Usage:
/// ```swift
/// Text("Loading...")
///     .shimmer(isActive: true)
/// ```
@MainActor
public struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.0),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                            .onAppear {
                                withAnimation(
                                    .linear(duration: DesignSystem.Animation.deliberate)
                                    .repeatForever(autoreverses: false)
                                ) {
                                    phase = 1.0
                                }
                            }
                    }
                    .allowsHitTesting(false)
                }
            }
    }
}

extension View {
    /// Apply shimmer animation effect
    ///
    /// - Parameter isActive: Whether shimmer animation should be active
    ///
    /// Usage:
    /// ```swift
    /// Text("Loading")
    ///     .shimmer(isActive: viewModel.isLoading)
    /// ```
    public func shimmer(isActive: Bool) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
